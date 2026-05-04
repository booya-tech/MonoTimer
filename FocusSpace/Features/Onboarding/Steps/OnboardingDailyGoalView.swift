//
//  OnboardingDailyGoalView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/27/26.
//

import SwiftUI

struct OnboardingDailyGoalView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = [
        GridItem(.flexible(), spacing: AppConstants.UI.mediumPadding),
        GridItem(.flexible(), spacing: AppConstants.UI.mediumPadding)
    ]

    var body: some View {
        VStack(spacing: AppConstants.UI.largePadding) {
            VStack(spacing: AppConstants.UI.smallPadding) {
                Text(AppString.onboardingDailyGoalTitle)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text(AppString.onboardingDailyGoalSubtitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppConstants.UI.largePadding)

            LazyVGrid(columns: columns, spacing: AppConstants.UI.mediumPadding) {
                ForEach(AppConstants.Onboarding.dailyGoalChoices, id: \.self) { minutes in
                    OnboardingChip(
                        title: formatHours(minutes),
                        subtitle: "\(minutes) min",
                        isSelected: viewModel.dailyGoalMinutes == minutes
                    ) {
                        viewModel.selectDailyGoal(minutes)
                    }
                }
            }
            .padding(.horizontal, AppConstants.UI.largePadding)

            Spacer()
        }
        .padding(.top, AppConstants.UI.largePadding)
    }

    private func formatHours(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder)m" }
        if remainder == 0 { return "\(hours)h" }
        return "\(hours)h \(remainder)m"
    }
}

#Preview {
    OnboardingDailyGoalView(viewModel: OnboardingViewModel())
}
