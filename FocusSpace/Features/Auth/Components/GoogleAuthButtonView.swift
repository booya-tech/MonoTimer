//
//  GoogleAuthButtonView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/26/26.
//

import SwiftUI

// Google Sign-In button styled per Google Identity branding guidelines.
// Colors are intentionally hard-coded to Google's official spec (not the
// app palette) so the button reads as a recognizable, native Google button
// in both light and dark mode.
// Reference: https://developers.google.com/identity/branding-guidelines
struct GoogleAuthButtonView: View {
    let isLoading: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(AppAsset.Icon.googleLogo)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                Text("Continue with Google")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .accessibilityLabel("Continue with Google")
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "131314") : Color.white
    }

    private var textColor: Color {
        colorScheme == .dark ? Color(hex: "E3E3E3") : Color(hex: "1F1F1F")
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color(hex: "8E918F") : Color(hex: "747775")
    }
}

#Preview {
    GoogleAuthButtonView(isLoading: false, action: {})
}
