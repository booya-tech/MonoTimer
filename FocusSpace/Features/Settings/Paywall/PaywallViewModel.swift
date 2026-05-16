//
//  PaywallViewModel.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/15/26.
//

import Foundation
import RevenueCat
import Combine

@MainActor
protocol PaywallViewModelProtocol: ObservableObject {
    var selectedProduct: Package? { get }
    var selectedPlan: UserPlans { get set }
    var isPurchasing: Bool { get }
    var showError: Bool { get set }
    var errorMessage: String { get }
    var isActivePlan: Bool { get }
    var isStandardSelected: Bool { get }
    var ctaLabel: String { get }
    var products: [Package] { get }
    var isStoreLoading: Bool { get }
    var monthlyProduct: Package? { get }
    var yearlyProduct: Package? { get }

    func loadInitialData() async
    func onPlanChanged(_ newPlan: UserPlans)
    func purchaseSelectedProduct() async -> Bool
    func restorePurchases() async
    func retryLoadProducts() async
    func dismissPaywall()
    func planLabel(for product: Package) -> String
    func periodLabel(for product: Package) -> String
    func savingsPercentage(yearly: Decimal, monthly: Decimal) -> Int
}

@MainActor
final class PaywallViewModel: PaywallViewModelProtocol {
    private let purchaseManager: PurchaseManager
    private let analytics: AnalyticsService
    /// Origin of the paywall presentation (e.g. "dashboard", "profile").
    /// Forwarded to `paywall_viewed` and the purchase funnel events.
    private let source: String
    private var cancellable: AnyCancellable?
    private var hasCapturedView = false

    @Published var selectedProduct: Package?
    @Published var selectedPlan: UserPlans = .standard {
        didSet { onPlanChanged(selectedPlan) }
    }
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage = ""

    var products: [Package] { purchaseManager.packages }
    var isStoreLoading: Bool { purchaseManager.isLoading }
    var monthlyProduct: Package? { purchaseManager.monthlyProduct }
    var yearlyProduct: Package? { purchaseManager.yearlyProduct }

    var isActivePlan: Bool {
        selectedPlan == purchaseManager.currentPlan
    }

    var isStandardSelected: Bool {
        selectedPlan == .standard
    }

    var ctaLabel: String {
        if isStandardSelected { return AppString.paywallCurrentPlan }
        if isActivePlan { return AppString.paywallActivePlan }
        guard let product = selectedProduct else { return AppString.paywallSubscribe }
        return AppString.paywallGetPremium(product.storeProduct.localizedPriceString)
    }

    @MainActor
    init(
        purchaseManager: PurchaseManager? = nil,
        analytics: AnalyticsService? = nil,
        source: String = "unknown"
    ) {
        // Defaults resolved here because `PurchaseManager.shared` and
        // `AnalyticsBootstrap.shared` are `@MainActor`-isolated and default
        // expressions are evaluated in a nonisolated context.
        self.purchaseManager = purchaseManager ?? .shared
        self.analytics = analytics ?? AnalyticsBootstrap.shared
        self.source = source

        let purchaseManager = self.purchaseManager

        cancellable = purchaseManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    // MARK: - Actions

    func loadInitialData() async {
        if !hasCapturedView {
            hasCapturedView = true
            analytics.capture(.paywallViewed(source: source))
        }
        await purchaseManager.loadOfferings()
        selectedPlan = purchaseManager.currentPlan
    }

    func onPlanChanged(_ newPlan: UserPlans) {
        switch newPlan {
        case .standard:
            selectedProduct = nil
        case .monthly:
            selectedProduct = purchaseManager.monthlyProduct
        case .yearly:
            selectedProduct = purchaseManager.yearlyProduct
        }
    }

    func purchaseSelectedProduct() async -> Bool {
        guard !isPurchasing, let product = selectedProduct else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        let productId = product.storeProduct.productIdentifier
        analytics.capture(.paywallPurchaseStarted(productId: productId))

        do {
            let success = try await purchaseManager.purchase(product)
            if success {
                analytics.capture(.paywallPurchaseSucceeded(productId: productId))
            } else {
                analytics.capture(.paywallPurchaseCancelled(productId: productId))
            }
            return success
        } catch {
            analytics.capture(.paywallPurchaseFailed(
                productId: productId,
                reason: error.localizedDescription
            ))
            // Suppress cancellation / payment-pending so they don't surface
            // as user-visible alerts (mapped to nil by userFacingMessage).
            if let message = PurchaseManager.userFacingMessage(for: error) {
                errorMessage = message
                showError = true
            }
            return false
        }
    }

    func dismissPaywall() {
        analytics.capture(.paywallDismissed)
    }

    func restorePurchases() async {
        do {
            try await purchaseManager.restorePurchases()
        } catch {
            if let message = PurchaseManager.userFacingMessage(for: error) {
                errorMessage = message
                showError = true
            }
        }
    }

    func retryLoadProducts() async {
        await purchaseManager.loadOfferings()
    }

    // MARK: - Display Helpers

    func planLabel(for product: Package) -> String {
        product.storeProduct.productIdentifier == AppConstants.StoreKit.premiumYearly
            ? AppString.paywallYearly
            : AppString.paywallMonthly
    }

    func periodLabel(for product: Package) -> String {
        product.storeProduct.productIdentifier == AppConstants.StoreKit.premiumYearly
            ? AppString.paywallPeriodYear
            : AppString.paywallPeriodMonth
    }

    func savingsPercentage(yearly: Decimal, monthly: Decimal) -> Int {
        let yearlyValue = NSDecimalNumber(decimal: yearly).doubleValue
        let monthlyValue = NSDecimalNumber(decimal: monthly).doubleValue
        let annualizedMonthly = monthlyValue * 12
        guard annualizedMonthly > 0 else { return 0 }
        let savings = ((annualizedMonthly - yearlyValue) / annualizedMonthly) * 100
        return max(0, Int(savings.rounded()))
    }
}
