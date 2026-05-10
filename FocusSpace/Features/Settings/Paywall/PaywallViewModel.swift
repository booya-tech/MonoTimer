//
//  PaywallViewModel.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/15/26.
//

import Foundation
import StoreKit
import Combine

@MainActor
protocol PaywallViewModelProtocol: ObservableObject {
    var selectedProduct: Product? { get }
    var selectedPlan: UserPlans { get set }
    var isPurchasing: Bool { get }
    var showError: Bool { get set }
    var errorMessage: String { get }
    var isActivePlan: Bool { get }
    var isStandardSelected: Bool { get }
    var ctaLabel: String { get }
    var products: [Product] { get }
    var isStoreLoading: Bool { get }
    var monthlyProduct: Product? { get }
    var yearlyProduct: Product? { get }

    func loadInitialData() async
    func onPlanChanged(_ newPlan: UserPlans)
    func purchaseSelectedProduct() async -> Bool
    func restorePurchases() async
    func retryLoadProducts() async
    func dismissPaywall()
    func planLabel(for product: Product) -> String
    func periodLabel(for product: Product) -> String
    func savingsPercentage(yearly: Decimal, monthly: Decimal) -> Int
}

@MainActor
final class PaywallViewModel: PaywallViewModelProtocol {
    private let storeKitManager: StoreKitManager
    private let analytics: AnalyticsService
    /// Origin of the paywall presentation (e.g. "dashboard", "profile").
    /// Forwarded to `paywall_viewed` and the purchase funnel events.
    private let source: String
    private var cancellable: AnyCancellable?
    private var hasCapturedView = false

    @Published var selectedProduct: Product?
    @Published var selectedPlan: UserPlans = .standard {
        didSet { onPlanChanged(selectedPlan) }
    }
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage = ""

    var products: [Product] { storeKitManager.products }
    var isStoreLoading: Bool { storeKitManager.isLoading }
    var monthlyProduct: Product? { storeKitManager.monthlyProduct }
    var yearlyProduct: Product? { storeKitManager.yearlyProduct }

    var isActivePlan: Bool {
        selectedPlan == storeKitManager.currentPlan
    }

    var isStandardSelected: Bool {
        selectedPlan == .standard
    }

    var ctaLabel: String {
        if isStandardSelected { return AppString.paywallCurrentPlan }
        if isActivePlan { return AppString.paywallActivePlan }
        guard let product = selectedProduct else { return AppString.paywallSubscribe }
        return AppString.paywallGetPremium(product.displayPrice)
    }

    @MainActor
    init(
        storeKitManager: StoreKitManager? = nil,
        analytics: AnalyticsService? = nil,
        source: String = "unknown"
    ) {
        // Defaults resolved here because `StoreKitManager.shared` and
        // `AnalyticsBootstrap.shared` are `@MainActor`-isolated and default
        // expressions are evaluated in a nonisolated context.
        self.storeKitManager = storeKitManager ?? .shared
        self.analytics = analytics ?? AnalyticsBootstrap.shared
        self.source = source

        let storeKitManager = self.storeKitManager

        cancellable = storeKitManager.objectWillChange
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
        await storeKitManager.loadProducts()
        selectedPlan = storeKitManager.currentPlan
    }

    func onPlanChanged(_ newPlan: UserPlans) {
        switch newPlan {
        case .standard:
            selectedProduct = nil
        case .monthly:
            selectedProduct = storeKitManager.monthlyProduct
        case .yearly:
            selectedProduct = storeKitManager.yearlyProduct
        }
    }

    func purchaseSelectedProduct() async -> Bool {
        guard !isPurchasing, let product = selectedProduct else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        analytics.capture(.paywallPurchaseStarted(productId: product.id))

        do {
            let success = try await storeKitManager.purchase(product)
            if success {
                analytics.capture(.paywallPurchaseSucceeded(productId: product.id))
            } else {
                analytics.capture(.paywallPurchaseCancelled(productId: product.id))
            }
            return success
        } catch {
            analytics.capture(.paywallPurchaseFailed(
                productId: product.id,
                reason: error.localizedDescription
            ))
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }

    func dismissPaywall() {
        analytics.capture(.paywallDismissed)
    }

    func restorePurchases() async {
        do {
            try await storeKitManager.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func retryLoadProducts() async {
        await storeKitManager.loadProducts()
    }

    // MARK: - Display Helpers

    func planLabel(for product: Product) -> String {
        product.id == AppConstants.StoreKit.premiumYearly
            ? AppString.paywallYearly
            : AppString.paywallMonthly
    }

    func periodLabel(for product: Product) -> String {
        product.id == AppConstants.StoreKit.premiumYearly
            ? AppString.paywallPeriodYear
            : AppString.paywallPeriodMonth
    }

    func savingsPercentage(yearly: Decimal, monthly: Decimal) -> Int {
        let annualizedMonthly = monthly * 12
        guard annualizedMonthly > 0 else { return 0 }
        let savings = ((annualizedMonthly - yearly) / annualizedMonthly) * 100
        return NSDecimalNumber(decimal: savings).intValue
    }
}
