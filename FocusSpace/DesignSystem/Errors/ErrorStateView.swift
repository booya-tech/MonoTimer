//
//  ErrorStateView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/15/26.
//
//  Reusable error / empty-state placeholder used across the app.
//

import SwiftUI

struct ErrorStateView: View {
    let systemImage: String
    let title: String
    let description: String
    let buttonLabel: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(AppColors.secondaryText)

            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.primaryText)

            Text(description)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            Button(action: action) {
                Text(buttonLabel)
                    .font(AppTypography.buttonText)
                    .foregroundStyle(AppColors.primaryRevert)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.primaryText)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    ErrorStateView(
        systemImage: "wifi.slash",
        title: "Unable to load plans",
        description: "Check your connection and try again.",
        buttonLabel: "Retry",
        action: {}
    )
}
