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

struct PaywallView<VM: PaywallViewModelProtocol>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.analytics) private var analytics
    @ObservedObject private var vm: VM

    init(vm: VM) {
        _vm = ObservedObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 16)

                        headerSection

                        Spacer().frame(height: 16)

                        if vm.products.isEmpty && !vm.isStoreLoading {
                            ErrorStateView(
                                systemImage: AppConstants.Icon.wifiSlash,
                                title: AppString.paywallErrorTitle,
                                description: AppString.paywallErrorSubTitle,
                                buttonLabel: AppString.retry
                            ) {
                                Task { await vm.retryLoadProducts() }
                            }
                        } else {
                            planSelector
                            Spacer().frame(height: 16)
                            planCard
                            Spacer().frame(height: 16)
                            featuresSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }

                bottomCTA
            }
            .background(AppColors.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppString.skip) {
                        analytics.capture(.paywallDismissed)
                        dismiss()
                    }
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.primaryText)
                }
            }
            .alert(AppString.paywallAlertError, isPresented: $vm.showError) {
                Button(AppString.ok) {}
            } message: {
                Text(vm.errorMessage)
            }
            .task {
                await vm.loadInitialData()
            }
            .onChange(of: vm.selectedUserPlans) { _, newPlan in
                vm.onPlanChanged(newPlan)
            }
            .analyticsScreen("Paywall")
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

    // MARK: - Plan Selector

    private var planSelector: some View {
        HStack(spacing: 8) {
            ForEach(UserPlans.allCases) { plan in
                let isSelected = vm.selectedUserPlans == plan

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectedUserPlans = plan
                    }
                    HapticManager.shared.light()
                } label: {
                    Text(plan.rawValue)
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

    // MARK: - Plan Card

    private var planCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                switch vm.selectedUserPlans {
                case .standard:
                    standardPlanCardContent

                case .monthly:
                    if let product = vm.monthlyProduct {
                        premiumPlanCardContent(for: product)
                    }

                case .yearly:
                    if let product = vm.yearlyProduct {
                        premiumPlanCardContent(for: product)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.primaryText)
            )

            if vm.isActivePlan {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.caption2)

                    Text("Active")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppColors.primaryRevert)
                )
                .padding(.top, 16)
                .padding(.trailing, 16)
            }
        }
    }

    private var standardPlanCardContent: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppString.paywallStandard)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.primaryRevert)

                Text(AppString.paywallFreeForever)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.primaryRevert.opacity(0.7))
            }
        }
    }

    private func premiumPlanCardContent(for product: Product) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(vm.planLabel(for: product))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.primaryRevert)

                Text(product.displayPrice + " / " + vm.periodLabel(for: product))
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.primaryRevert.opacity(0.7))

                if product.id == AppConstants.StoreKit.premiumYearly,
                   let monthly = vm.monthlyProduct {
                    let savings = vm.savingsPercentage(
                        yearly: product.price,
                        monthly: monthly.price
                    )
                    Text(AppString.paywallSaveLabel(savings))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.primaryRevert.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(AppString.paywallWhatYouGet)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.primaryText)

            VStack(spacing: 16) {
                if vm.selectedUserPlans == .standard {
                    standardFeatures
                } else {
                    premiumFeatures
                }
            }
        }
    }

    private var standardFeatures: some View {
        Group {
            featureRow(icon: AppConstants.Icon.timerFill,
                       title: AppString.paywallFeatureBasicTimerTitle,
                       subtitle: AppString.paywallFeatureBasicTimerSubtitle)
            featureRow(icon: AppConstants.Icon.clockFill,
                       title: AppString.paywallFeatureFocusSessionsTitle,
                       subtitle: AppString.paywallFeatureFocusSessionsSubtitle)
            featureRow(icon: AppConstants.Icon.hourglassBottomHalfFilled,
                       title: AppString.paywallFeatureCustomDurationTitle,
                       subtitle: AppString.paywallFeatureCustomDurationSubtitle)
            featureRow(icon: AppConstants.Icon.circleFill,
                       title: AppString.paywallFeatureLightDarkModeTitle,
                       subtitle: AppString.paywallFeatureLightDarkModeSubtitle)
        }
    }

    private var premiumFeatures: some View {
        Group {
            featureRow(icon: AppConstants.Icon.paintpaletteFill,
                       title: AppString.paywallFeaturePremiumColorsTitle,
                       subtitle: AppString.paywallFeaturePremiumColorsSubtitle)
            featureRow(icon: AppConstants.Icon.sparkles,
                       title: AppString.paywallFeatureExclusiveThemesTitle,
                       subtitle: AppString.paywallFeatureExclusiveThemesSubtitle)
            featureRow(icon: AppConstants.Icon.chartBarFill,
                       title: AppString.paywallFeatureSessionHistoryTitle,
                       subtitle: AppString.paywallFeatureSessionHistorySubtitle)
            featureRow(icon: AppConstants.Icon.starFill,
                       title: AppString.paywallFeatureEarlyAccessTitle,
                       subtitle: AppString.paywallFeatureEarlyAccessSubtitle)
            featureRow(icon: AppConstants.Icon.heartFill,
                       title: AppString.paywallFeatureSupportDevTitle,
                       subtitle: AppString.paywallFeatureSupportDevSubtitle)
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
                Task {
                    let success = await vm.purchaseSelectedProduct()
                    if success { dismiss() }
                }
            } label: {
                Group {
                    if vm.isPurchasing {
                        ProgressView()
                            .tint(AppColors.primaryRevert)
                    } else {
                        Text(vm.ctaLabel)
                            .font(AppTypography.buttonLarge)
                    }
                }
                .foregroundStyle(vm.isStandardSelected
                    ? AppColors.secondaryText
                    : AppColors.primaryRevert)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(vm.isStandardSelected
                            ? AppColors.primaryText.opacity(0.15)
                            : AppColors.primaryText)
                )
            }
            .disabled(vm.isStandardSelected || vm.selectedProduct == nil || vm.isPurchasing)
            .buttonStyle(.plain)

            if !vm.isStandardSelected {
                Text(AppString.paywallAutoRenewDisclaimer)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 4) {
                Button(AppString.paywallRestorePurchases) {
                    Task { await vm.restorePurchases() }
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
}

// MARK: - Convenience Init

extension PaywallView where VM == PaywallViewModel {
    /// Convenience initializer that builds a default `PaywallViewModel`. The
    /// `source` is forwarded to the `paywall_viewed` analytics event so each
    /// presentation point in the app is distinguishable in funnels.
    init(source: String = "unknown") {
        self.init(vm: PaywallViewModel(source: source))
    }
}

#Preview {
    PaywallView()
}
