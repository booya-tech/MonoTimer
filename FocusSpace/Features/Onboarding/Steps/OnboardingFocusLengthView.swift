//
//  OnboardingFocusLengthView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/27/26.
//

import SwiftUI

struct OnboardingFocusLengthView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = [
        GridItem(.flexible(), spacing: AppConstants.UI.mediumPadding),
        GridItem(.flexible(), spacing: AppConstants.UI.mediumPadding)
    ]

    var body: some View {
        VStack(spacing: AppConstants.UI.largePadding) {
            VStack(spacing: AppConstants.UI.smallPadding) {
                Text(AppString.onboardingFocusLengthTitle)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text(AppString.onboardingFocusLengthSubtitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppConstants.UI.largePadding)

            LazyVGrid(columns: columns, spacing: AppConstants.UI.mediumPadding) {
                ForEach(AppConstants.Onboarding.focusLengthChoices, id: \.self) { minutes in
                    OnboardingChip(
                        title: "\(minutes)",
                        subtitle: "minutes",
                        isSelected: viewModel.focusLengthMinutes == minutes
                    ) {
                        viewModel.selectFocusLength(minutes)
                    }
                }
            }
            .padding(.horizontal, AppConstants.UI.largePadding)

            Spacer()
        }
        .padding(.top, AppConstants.UI.largePadding)
    }
}

#Preview {
    OnboardingFocusLengthView(viewModel: OnboardingViewModel())
}
