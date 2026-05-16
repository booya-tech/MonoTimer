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

enum PurchaseError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return AppString.paywallErrorSubTitle
        }
    }
}

@MainActor
final class PurchaseManager: NSObject, ObservableObject {
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

    // Prefer yearly when both are active so a plan-switch (Apple's
    // upgrade/downgrade flow can briefly leave both subscriptions active)
    // doesn't flicker the UI between Monthly and Yearly labels.
    var currentPlan: UserPlans {
        if purchasedProductIDs.contains(AppConstants.StoreKit.premiumYearly) { return .yearly }
        if purchasedProductIDs.contains(AppConstants.StoreKit.premiumMonthly) { return .monthly }
        return .standard
    }

    // MARK: - Init

    // Side-effect free: API calls are kicked off from `FocusSpaceApp` after
    // `configure()` runs so we never touch `Purchases.shared` before the SDK
    // is configured (the `static let shared` initializer fires before
    // `FocusSpaceApp.init()`'s body).
    private override init() { super.init() }

    // MARK: - Configure

    @MainActor
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
        // Receive server-side entitlement updates (renewals, refunds, billing
        // retry exits) without waiting for a scenePhase refresh.
        Purchases.shared.delegate = shared
    }

    // MARK: - Offerings

    func loadProducts() async { await loadOfferings() }

    func loadOfferings() async {
        guard Purchases.isConfigured else {
            errorMessage = PurchaseError.notConfigured.errorDescription
            return
        }
        guard !isLoading else { return }
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
        guard Purchases.isConfigured else { throw PurchaseError.notConfigured }
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
        guard Purchases.isConfigured else { throw PurchaseError.notConfigured }
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
        guard Purchases.isConfigured else { return }
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
        guard Purchases.isConfigured else { return }
        do {
            let result = try await Purchases.shared.logIn(userId)
            apply(customerInfo: result.customerInfo)
        } catch {
            Logger.log("Failed to RC logIn: \(error.localizedDescription)")
        }
    }

    func logOut() async {
        guard Purchases.isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.logOut()
            apply(customerInfo: customerInfo)
        } catch {
            Logger.log("Failed to RC logOut: \(error.localizedDescription)")
        }
    }

    // MARK: - Apply

    // Writes `AppPreferences.isPremiumUser` (UserDefaults) as the canonical
    // gating flag. That value is read synchronously across the app — so a
    // launch that occurs while offline, or before the first `refreshCustomerInfo`
    // completes, will show the previous-session cached state. This is the
    // intended grace window; downgrades take effect on the next successful
    // server hit (refresh / scenePhase / delegate push).
    private func apply(customerInfo: CustomerInfo) {
        let isPremium = customerInfo.entitlements["premium"]?.isActive == true
        // `activeSubscriptions` preserves all currently-active product IDs so
        // `currentPlan` can choose between them when a plan-switch leaves both
        // monthly and yearly active briefly. The `entitlement.productIdentifier`
        // alone collapses to one.
        purchasedProductIDs = isPremium ? customerInfo.activeSubscriptions : []
        preferences.isPremiumUser = isPremium
    }

    // MARK: - Error mapping

    // Returns a user-facing string for an error thrown by a RC API, or `nil`
    // when the error should be swallowed silently (user cancellation, payment
    // pending on SCA / Ask-to-Buy). Falls back to `localizedDescription` for
    // anything not explicitly mapped.
    static func userFacingMessage(for error: Error) -> String? {
        let nsError = error as NSError
        if let code = ErrorCode(rawValue: nsError.code) {
            switch code {
            case .purchaseCancelledError, .paymentPendingError:
                return nil
            default:
                break
            }
        }
        return error.localizedDescription
    }
}

// MARK: - PurchasesDelegate

extension PurchaseManager: PurchasesDelegate {
    // Called by the RC SDK from a non-isolated context when CustomerInfo
    // changes server-side (renewal, refund, revocation). Hop to the main
    // actor before mutating `@Published` state.
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo: customerInfo)
        }
    }
}
