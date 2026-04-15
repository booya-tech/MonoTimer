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
    private var cancellables = Set<AnyCancellable>()

    @Published var selectedProduct: Product?
    @Published var selectedUserPlans: UserPlans = .standard
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage = ""

    @Published private(set) var products: [Product] = []
    @Published private(set) var isStoreLoading = false
    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var yearlyProduct: Product?
    @Published private(set) var currentPlan: UserPlans = .standard

    var isActivePlan: Bool {
        selectedUserPlans == currentPlan
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
        bindStoreKitManager()
    }

    // MARK: - Actions

    func loadInitialData() async {
        await storeKitManager.loadProducts()
        selectedUserPlans = .yearly
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

    // MARK: - Private

    private func bindStoreKitManager() {
        storeKitManager.$products
            .sink { [weak self] products in
                guard let self else { return }
                self.products = products
                self.monthlyProduct = products.first { $0.id == AppConstants.StoreKit.premiumMonthly }
                self.yearlyProduct = products.first { $0.id == AppConstants.StoreKit.premiumYearly }
            }
            .store(in: &cancellables)

        storeKitManager.$isLoading
            .assign(to: &$isStoreLoading)

        storeKitManager.$purchasedProductIDs
            .sink { [weak self] ids in
                guard let self else { return }
                if ids.contains(AppConstants.StoreKit.premiumMonthly) {
                    self.currentPlan = .monthly
                } else if ids.contains(AppConstants.StoreKit.premiumYearly) {
                    self.currentPlan = .yearly
                } else {
                    self.currentPlan = .standard
                }
            }
            .store(in: &cancellables)
    }
}
