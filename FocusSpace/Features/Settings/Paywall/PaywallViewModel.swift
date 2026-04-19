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

    func loadInitialData() async
    func onPlanChanged(_ newPlan: UserPlans)
    func purchaseSelectedProduct() async -> Bool
    func restorePurchases() async
    func retryLoadProducts() async
    func planLabel(for product: Product) -> String
    func periodLabel(for product: Product) -> String
    func savingsPercentage(yearly: Decimal, monthly: Decimal) -> Int
}

@MainActor
final class PaywallViewModel: PaywallViewModelProtocol {
    private let storeKitManager: StoreKitManager
    private var cancellable: AnyCancellable?

    @Published var selectedProduct: Product?
    @Published var selectedUserPlans: UserPlans = .standard
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage = ""

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

    init(storeKitManager: StoreKitManager = .shared) {
        self.storeKitManager = storeKitManager

        cancellable = storeKitManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    // MARK: - Actions

    func loadInitialData() async {
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

        do {
            let success = try await storeKitManager.purchase(product)
            return success
        } catch {
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
