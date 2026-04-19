//
//  PaywallViewModel.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/15/26.
//

import Foundation
import StoreKit
import Combine

enum UserPlans: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { self.rawValue }
}

@MainActor
protocol PaywallViewModelProtocol: ObservableObject {
    var selectedProduct: Product? { get }
    var selectedUserPlans: UserPlans { get set }
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
    /// Resolved variant of the paywall, driven by the `paywall_v2` feature flag.
    /// Defaults to `.v1` when the flag is off or analytics is disabled.
    var variant: PaywallVariant { get }

    func loadInitialData() async
    func onPlanChanged(_ newPlan: UserPlans)
    func purchaseSelectedProduct() async -> Bool
    func restorePurchases() async
    func retryLoadProducts() async
    func planLabel(for product: Product) -> String
    func periodLabel(for product: Product) -> String
    func savingsPercentage(yearly: Decimal, monthly: Decimal) -> Int
}

/// A/B variant resolved from the `paywall_v2` PostHog feature flag.
enum PaywallVariant: String {
    case v1
    case v2
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
    @Published var selectedUserPlans: UserPlans = .standard
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var variant: PaywallVariant = .v1

    var products: [Product] { storeKitManager.products }
    var isStoreLoading: Bool { storeKitManager.isLoading }
    var monthlyProduct: Product? { storeKitManager.monthlyProduct }
    var yearlyProduct: Product? { storeKitManager.yearlyProduct }

    var isActivePlan: Bool {
        selectedUserPlans == storeKitManager.currentPlan
    }

    var isStandardSelected: Bool {
        selectedUserPlans == .standard
    }

    var ctaLabel: String {
        if isStandardSelected { return AppString.paywallCurrentPlan }
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
        // Resolve the A/B variant first so it can be sent as a property on
        // `paywall_viewed` for clean funnel attribution in PostHog.
        variant = analytics.isFeatureEnabled("paywall_v2") ? .v2 : .v1

        if !hasCapturedView {
            hasCapturedView = true
            analytics.capture(.paywallViewed(source: source))
        }
        await storeKitManager.loadProducts()
        selectedUserPlans = storeKitManager.currentPlan == .standard ? .yearly : storeKitManager.currentPlan
        selectedProduct = storeKitManager.yearlyProduct
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
        guard let product = selectedProduct else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        analytics.capture(.paywallPurchaseStarted(productId: product.id))

        do {
            let success = try await storeKitManager.purchase(product)
            if success {
                analytics.capture(.paywallPurchaseSucceeded(productId: product.id))
            } else {
                // false from StoreKit means userCancelled / pending - not a true error.
                analytics.capture(.paywallPurchaseFailed(
                    productId: product.id,
                    reason: "cancelled_or_pending"
                ))
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

    func restorePurchases() async {
        await storeKitManager.restorePurchases()
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
        let yearlyTotal = NSDecimalNumber(decimal: yearly).doubleValue
        let monthlyTotal = NSDecimalNumber(decimal: monthly).doubleValue * 12
        guard monthlyTotal > 0 else { return 0 }
        return Int(((monthlyTotal - yearlyTotal) / monthlyTotal) * 100)
    }
}
