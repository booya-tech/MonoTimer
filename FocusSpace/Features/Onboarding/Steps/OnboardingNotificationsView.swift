//
//  OnboardingNotificationsView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/27/26.
//

import SwiftUI

struct OnboardingNotificationsView: View {
    var body: some View {
        VStack(spacing: AppConstants.UI.largePadding) {
            Spacer()

            Image(systemName: "bell.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AppColors.primaryText)
                .accessibilityHidden(true)

            VStack(spacing: AppConstants.UI.smallPadding) {
                Text(AppString.onboardingNotificationsTitle)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text(AppString.onboardingNotificationsSubtitle)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppConstants.UI.largePadding)
            // TODO: Check double Spacer()
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingNotificationsView()
}
