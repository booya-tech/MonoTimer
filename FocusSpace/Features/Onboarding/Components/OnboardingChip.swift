//
//  OnboardingChip.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/27/26.
//

import SwiftUI

/// Selectable monochrome chip used by Focus Length and Daily Goal steps.
struct OnboardingChip: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, subtitle: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundColor(isSelected ? AppColors.background : AppColors.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(isSelected ? AppColors.background.opacity(0.8) : AppColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.UI.mediumPadding)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                    .fill(isSelected ? AppColors.primaryText : AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius)
                            .stroke(AppColors.primaryText, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(subtitle.map { "\(title), \($0)" } ?? title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack(spacing: 12) {
        OnboardingChip(title: "25", subtitle: "minutes", isSelected: true) {}
        OnboardingChip(title: "45", subtitle: "minutes", isSelected: false) {}
    }
    .padding()
}
