//
//  OnboardingView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/27/26.
//
//  4-step first-launch onboarding container.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                pageIndicator
                    .padding(.top, AppConstants.UI.mediumPadding)
                    .padding(.horizontal, AppConstants.UI.largePadding)

                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        OnboardingWelcomeView()
                    case .focusLength:
                        OnboardingFocusLengthView(viewModel: viewModel)
                    case .dailyGoal:
                        OnboardingDailyGoalView(viewModel: viewModel)
                    case .notifications:
                        OnboardingNotificationsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

                footer
                    .padding(.horizontal, AppConstants.UI.largePadding)
                    .padding(.bottom, AppConstants.UI.mediumPadding)
            }
        }
        .analyticsScreen(AppConstants.Analytics.Screen.onboarding)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? AppColors.primaryText : AppColors.primaryText.opacity(0.2))
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel("Step \(viewModel.currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
    }

    @ViewBuilder
    private var footer: some View {
        switch viewModel.currentStep {
        case .welcome:
            PrimaryButton(title: AppString.onboardingGetStarted) {
                viewModel.next()
            }
        case .focusLength, .dailyGoal:
            VStack(spacing: AppConstants.UI.smallPadding) {
                PrimaryButton(title: AppString.onboardingContinue) {
                    viewModel.next()
                }
                backButton
            }
        case .notifications:
            VStack(spacing: AppConstants.UI.smallPadding) {
                PrimaryButton(title: AppString.onboardingEnableNotifications) {
                    Task { await viewModel.requestNotificationsAndComplete() }
                }
                Button(action: viewModel.skipNotificationsAndComplete) {
                    Text(AppString.onboardingNotNow)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                        .frame(height: 44)
                }
            }
        }
    }

    private var backButton: some View {
        Button(action: viewModel.back) {
            HStack(spacing: 4) {
                Image(systemName: AppConstants.Icon.chevronLeft)
                Text("Back")
            }
            .font(AppTypography.body)
            .foregroundColor(AppColors.secondaryText)
            .frame(height: 44)
        }
    }
}

#Preview {
    OnboardingView()
}
