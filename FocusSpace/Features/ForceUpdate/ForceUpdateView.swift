//
//  ForceUpdateView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 5/13/26.
//
//  Blocking screen shown when the installed version is behind the App Store.
//  The user cannot dismiss this screen — they must update to continue.
//

import SwiftUI

struct ForceUpdateView: View {
    let appStoreURL: URL?

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image(AppAsset.Image.ghostAppForceupdate)
                        .resizable()
                        .scaledToFit()

                    VStack(spacing: 8) {
                        Text(AppString.forceUpdateTitle)
                            .font(AppTypography.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.primaryText)

                        Text(AppString.forceUpdateMessage)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                PrimaryButton(title: AppString.forceUpdateCTA) {
                    guard let url = appStoreURL else { return }
                    openURL(url)
                }
                .disabled(appStoreURL == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        // Prevent interactive dismissal — this gate must not be swipeable.
        .interactiveDismissDisabled(true)
    }

}

#Preview {
    ForceUpdateView(appStoreURL: URL(string: "https://apps.apple.com"))
}
