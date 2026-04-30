//
//  OnboardingWelcomeView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/27/26.
//

import SwiftUI
import SDWebImageSwiftUI

struct OnboardingWelcomeView: View {
    var body: some View {
        VStack(spacing: AppConstants.UI.mediumPadding) {
            Spacer()

            AnimatedImage(name: "ghost-onboarding.gif")
                .customLoopCount(0)
                .resizable()
                .scaledToFit()
                .frame(
                    width: AppConstants.UI.onboardingHeroSize,
                    height: AppConstants.UI.onboardingHeroSize
                )
                .accessibilityHidden(true)

            Spacer().frame(height: AppConstants.UI.largePadding)

            Text(AppConstants.appName)
                .font(AppTypography.title1)
                .foregroundColor(AppColors.primaryText)

            Text(AppString.onboardingWelcomeTitle)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)

            Text(AppString.onboardingWelcomeSubtitle)
                .font(AppTypography.body)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.UI.largePadding)

            Spacer()
            Spacer()
        }
        .onAppear {
            let asset = NSDataAsset(name: AppAsset.Image.onboardingGhost)
            print("Ghost asset bytes:", asset?.data.count ?? -1)
        }
    }
}

#Preview {
    OnboardingWelcomeView()
}
