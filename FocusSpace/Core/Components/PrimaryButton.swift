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
                .foregroundColor(isDestructive ? AppColors.primaryText : AppColors.primaryRevert)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDestructive ? AppColors.primaryRevert : AppColors.primaryText)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isDestructive ? AppColors.primaryText : .clear, lineWidth: 1)
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
    }
    .padding()
}
