//
//  StoreKitManager.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/14/26.
//
//  Manages StoreKit2 subscriptions and premium entitlement status
//

import Foundation
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // Products fetched from App Store / StoreKit config
    @Published private(set) var products: [Product] = []
    // Set of product IDs the user currently has active entitlements for
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var transactionListener: Task<Void, Error>?
    private var preferences: AppPreferences { AppPreferences.shared }
    private var analytics: AnalyticsService { AnalyticsBootstrap.shared }

    // MARK: - Computed Helpers

    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }

    var monthlyProduct: Product? {
        products.first { $0.id == AppConstants.StoreKit.premiumMonthly }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == AppConstants.StoreKit.premiumYearly }
    }

    // MARK: - Current Plan
    var currentPlan: UserPlans {
        if purchasedProductIDs.contains(AppConstants.StoreKit.premiumMonthly) {
            return .monthly
        } else if purchasedProductIDs.contains(AppConstants.StoreKit.premiumYearly) {
            return .yearly
        } else {
            return .standard
        }
    }

    // MARK: - Init

    private init() {
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    // MARK: - Load Products

    /// Fetches product metadata (price, display name) from the App Store
    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(
                for: AppConstants.StoreKit.allProductIDs
            )
            // Sort so monthly appears first (lower price)
            products = storeProducts.sorted { $0.price < $1.price }
            errorMessage = nil
        } catch {
            Logger.log("Failed to load products: \(error.localizedDescription)")
            errorMessage = "Unable to load subscription options."
        }
    }

    // MARK: - Purchase

    /// Initiates a purchase for the given product. Returns true if successful.
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    /// Syncs with the App Store to restore any previously purchased subscriptions
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        let preRestoreIDs = purchasedProductIDs

        do {
            try await AppStore.sync()
        } catch {
            Logger.log("Restore failed: \(error.localizedDescription)")
            errorMessage = "Unable to restore purchases. Check your connection."
        }
        await updatePurchasedProducts()

        let restored = purchasedProductIDs.subtracting(preRestoreIDs)
        for productID in restored {
            analytics.capture(.purchaseRestored(productId: productID))
        }
    }

    // MARK: - Entitlement Check

    /// Iterates current entitlements to determine active subscriptions,
    /// then syncs the result with AppPreferences.isPremiumUser
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                Logger.log("Unverified entitlement: \(error.localizedDescription)")
            }
        }

        purchasedProductIDs = purchased
        preferences.isPremiumUser = hasActiveSubscription
    }

    // MARK: - Transaction Listener

    /// Listens for external transaction changes: renewals, refunds,
    /// family sharing, Ask to Buy approvals
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                    await self.captureRenewal(productId: transaction.productID)
                } catch {
                    Logger.log("Unverified transaction: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Forwarded from the transaction listener so renewal events are captured
    /// on the main actor where the analytics service lives.
    private func captureRenewal(productId: String) {
        analytics.capture(.subscriptionRenewed(productId: productId))
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
