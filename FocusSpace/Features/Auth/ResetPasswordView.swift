//
//  ResetPasswordView.swift
//  FocusSpace
//

import SwiftUI

struct ResetPasswordView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { hideKeyboard() }

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(AppTypography.title1)
                        .foregroundColor(AppColors.primaryText)

                    Text("Enter your new password")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer().frame(height: 32)

                VStack(spacing: 16) {
                    PasswordField(placeholder: "New Password", text: $newPassword, isVisible: $showNewPassword)
                    PasswordField(placeholder: "Confirm Password", text: $confirmPassword, isVisible: $showConfirmPassword)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer().frame(height: 32)

                PrimaryButton(
                    title: isLoading ? "Updating..." : "Set New Password"
                ) {
                    Task { await updatePassword() }
                }
                .disabled(isLoading)

                Spacer().frame(height: 12)

                if !isLoading {
                    Button("Cancel") {
                        authService.isPasswordRecovery = false
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .interactiveDismissDisabled()
    }

    private func updatePassword() async {
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }

        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            try await authService.updatePassword(newPassword)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ResetPasswordView(authService: AuthService())
}
