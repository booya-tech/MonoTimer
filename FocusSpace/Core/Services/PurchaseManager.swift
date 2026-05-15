//
//  PurchaseManager.swift
//  MonoTimer
//
//  RevenueCat wrapper that replaces StoreKitManager.
//  Exposes the same public interface so all consumers compile without changes
//  except PaywallViewModel, which passes Package instead of Product.
//

import Foundation
import RevenueCat

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published private(set) var packages: [Package] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var preferences: AppPreferences { AppPreferences.shared }
    private var analytics: AnalyticsService { AnalyticsBootstrap.shared }

    // MARK: - Computed Helpers

    var hasActiveSubscription: Bool { !purchasedProductIDs.isEmpty }

    var monthlyProduct: Package? {
        packages.first { $0.storeProduct.productIdentifier == AppConstants.StoreKit.premiumMonthly }
    }

    var yearlyProduct: Package? {
        packages.first { $0.storeProduct.productIdentifier == AppConstants.StoreKit.premiumYearly }
    }

    var currentPlan: UserPlans {
        if purchasedProductIDs.contains(AppConstants.StoreKit.premiumMonthly) { return .monthly }
        if purchasedProductIDs.contains(AppConstants.StoreKit.premiumYearly) { return .yearly }
        return .standard
    }

    // MARK: - Init

    // Side-effect free: API calls are kicked off from `FocusSpaceApp` after
    // `configure()` runs so we never touch `Purchases.shared` before the SDK
    // is configured (the `static let shared` initializer fires before
    // `FocusSpaceApp.init()`'s body).
    private init() {}

    // MARK: - Configure

    static func configure() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
              !apiKey.isEmpty else {
            Logger.log("⚠️ REVENUECAT_API_KEY missing from Info.plist — purchases disabled")
            return
        }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: apiKey)
    }

    // MARK: - Offerings

    func loadProducts() async { await loadOfferings() }

    func loadOfferings() async {
        guard packages.isEmpty || errorMessage != nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            packages = (offerings.current?.availablePackages ?? [])
                .sorted { $0.storeProduct.price < $1.storeProduct.price }
            errorMessage = nil
        } catch {
            Logger.log("Failed to load RC offerings: \(error.localizedDescription)")
            errorMessage = "Unable to load subscription options."
        }
    }

    // MARK: - Purchase

    func purchase(_ package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        let result = try await Purchases.shared.purchase(package: package)
        guard !result.userCancelled else { return false }
        // RevenueCat returns a fully-resolved CustomerInfo after purchase —
        // no Transaction.currentEntitlements propagation lag, no finish() race.
        apply(customerInfo: result.customerInfo)
        return true
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        let preRestoreIDs = purchasedProductIDs
        let customerInfo = try await Purchases.shared.restorePurchases()
        apply(customerInfo: customerInfo)
        for productID in purchasedProductIDs.subtracting(preRestoreIDs) {
            analytics.capture(.purchaseRestored(productId: productID))
        }
    }

    // MARK: - Refresh

    func updatePurchasedProducts() async { await refreshCustomerInfo() }

    func refreshCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            apply(customerInfo: customerInfo)
        } catch {
            Logger.log("Failed to refresh RC customer info: \(error.localizedDescription)")
        }
    }

    // MARK: - Identity

    // Link RC identity to the Supabase user so entitlements follow the
    // account across devices instead of staying on the anonymous
    // `$RCAnonymousID` that is per-install.
    func logIn(userId: String) async {
        do {
            let result = try await Purchases.shared.logIn(userId)
            apply(customerInfo: result.customerInfo)
        } catch {
            Logger.log("Failed to RC logIn: \(error.localizedDescription)")
        }
    }

    func logOut() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            apply(customerInfo: customerInfo)
        } catch {
            Logger.log("Failed to RC logOut: \(error.localizedDescription)")
        }
    }

    // MARK: - Apply

    private func apply(customerInfo: CustomerInfo) {
        let isPremium = customerInfo.entitlements["premium"]?.isActive == true
        let activeID = customerInfo.entitlements["premium"]?.productIdentifier
        purchasedProductIDs = isPremium ? (activeID.map { [$0] } ?? []) : []
        preferences.isPremiumUser = isPremium
    }
}
