//
//  PaywallView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/14/26.
//
//  Subscription paywall with plan selection
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var storeKitManager: StoreKitManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection

                        if storeKitManager.products.isEmpty && !storeKitManager.isLoading {
                            ErrorStateView(
                                systemImage: AppConstants.Icon.wifiSlash,
                                title: AppString.paywallErrorTitle,
                                description: AppString.paywallErrorSubTitle,
                                buttonLabel: AppString.retry
                            ) {
                                Task { await storeKitManager.loadProducts() }
                            }
                        } else {
                            planSelector
                            planCard
                            featuresSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }

                bottomCTA
            }
            .background(AppColors.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppString.skip) { dismiss() }
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                }
            }
            .alert(AppString.paywallAlertError, isPresented: $showError) {
                Button(AppString.ok) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await storeKitManager.loadProducts()
                // Default to yearly (better value)
                selectedProduct = storeKitManager.yearlyProduct
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AppString.paywallHeaderSectionTitle)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Plan Selector (Tab-style like Revolut)

    private var planSelector: some View {
        HStack(spacing: 8) {
            ForEach(storeKitManager.products) { product in
                let isSelected = selectedProduct?.id == product.id

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedProduct = product
                    }
                    HapticManager.shared.light()
                } label: {
                    Text(planLabel(for: product))
                        .font(AppTypography.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? AppColors.primaryText : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? Color.clear : AppColors.primaryText.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .foregroundStyle(
                            isSelected ? AppColors.primaryRevert : AppColors.primaryText
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Plan Card (Dark card like Revolut)

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let product = selectedProduct {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(planLabel(for: product))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppColors.primaryRevert)

                        Text(product.displayPrice + " / " + periodLabel(for: product))
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.primaryRevert.opacity(0.7))

                        if product.id == AppConstants.StoreKit.premiumYearly,
                           let monthly = storeKitManager.monthlyProduct {
                            let savings = savingsPercentage(
                                yearly: product.price,
                                monthly: monthly.price
                            )
                            Text(AppString.paywallSaveLabel(savings))
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.primaryRevert.opacity(0.5))
                        }
                    }

                    Spacer()

                    Image(systemName: AppConstants.Icon.crownFill)
                        .font(.title2)
                        .foregroundStyle(AppColors.primaryRevert.opacity(0.6))
                }
            } else {
                ProgressView()
                    .tint(AppColors.primaryRevert)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.primaryText)
        )
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(AppString.paywallWhatYouGet)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.primaryText)

            VStack(spacing: 16) {
                featureRow(icon: AppConstants.Icon.paintpaletteFill,
                           title: AppString.paywallFeaturePremiumColorsTitle,
                           subtitle: AppString.paywallFeaturePremiumColorsSubtitle)
                featureRow(icon: AppConstants.Icon.sparkles,
                           title: AppString.paywallFeatureExclusiveThemesTitle,
                           subtitle: AppString.paywallFeatureExclusiveThemesSubtitle)
                featureRow(icon: AppConstants.Icon.starFill,
                           title: AppString.paywallFeatureEarlyAccessTitle,
                           subtitle: AppString.paywallFeatureEarlyAccessSubtitle)
                featureRow(icon: AppConstants.Icon.heartFill,
                           title: AppString.paywallFeatureSupportDevTitle,
                           subtitle: AppString.paywallFeatureSupportDevSubtitle)
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 28, height: 28)
                .foregroundStyle(AppColors.primaryText)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.body.weight(.medium))
                    .foregroundStyle(AppColors.primaryText)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 12) {
            Button {
                guard let product = selectedProduct else { return }
                Task { await performPurchase(product) }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(AppColors.primaryRevert)
                    } else {
                        Text(ctaLabel)
                            .font(AppTypography.buttonLarge)
                    }
                }
                .foregroundStyle(AppColors.primaryRevert)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColors.primaryText)
                )
            }
            .disabled(selectedProduct == nil || isPurchasing)
            .buttonStyle(.plain)

            Text(AppString.paywallAutoRenewDisclaimer)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button(AppString.paywallRestorePurchases) {
                    Task { await storeKitManager.restorePurchases() }
                }

                Text(AppString.paywallSeparator)

                Link(AppString.paywallTerms, destination: AppConstants.URLs.termsOfServiceURL)

                Text(AppString.paywallSeparator)

                Link(AppString.paywallPrivacy, destination: AppConstants.URLs.privacyPolicyURL)
            }
            .font(AppTypography.caption2)
            .foregroundStyle(AppColors.secondaryText)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            AppColors.background
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        )
    }

    // MARK: - Helpers

    private var ctaLabel: String {
        guard let product = selectedProduct else { return AppString.paywallSubscribe }
        return AppString.paywallGetPremium(product.displayPrice)
    }

    private func planLabel(for product: Product) -> String {
        product.id == AppConstants.StoreKit.premiumYearly ? AppString.paywallYearly : AppString.paywallMonthly
    }

    private func periodLabel(for product: Product) -> String {
        product.id == AppConstants.StoreKit.premiumYearly ? AppString.paywallPeriodYear : AppString.paywallPeriodMonth
    }

    private func savingsPercentage(yearly: Decimal, monthly: Decimal) -> Int {
        let yearlyTotal = NSDecimalNumber(decimal: yearly).doubleValue
        let monthlyTotal = NSDecimalNumber(decimal: monthly).doubleValue * 12
        guard monthlyTotal > 0 else { return 0 }
        return Int(((monthlyTotal - yearlyTotal) / monthlyTotal) * 100)
    }

    private func performPurchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let success = try await storeKitManager.purchase(product)
            if success { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreKitManager.shared)
}
