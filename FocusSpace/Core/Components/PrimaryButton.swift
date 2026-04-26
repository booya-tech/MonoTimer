//
//  PrimaryButton.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/23/25.
//
//  Primary button component with monochrome styling
//

import SwiftUI

// Primary button with monochrome design
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.buttonText)
                .foregroundColor(isDestructive ? AppColors.background : AppColors.primaryText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isDestructive ? AppColors.primaryText : AppColors.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.primaryText, lineWidth: 1)
                        )
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .buttonStyle(PlainButtonStyle())

    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Start Timer") {}
        PrimaryButton(title: "Stop Timer", isDestructive: true) {}
    }
    .padding()
}
