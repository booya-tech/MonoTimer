//
//  ForgotPasswordView.swift
//  FocusSpace
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var isSuccess = false

    private let authService: AuthService

    init(authService: AuthService, prefillEmail: String = "") {
        self.authService = authService
        self._email = State(initialValue: prefillEmail)
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { hideKeyboard() }

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.primaryText)
                    }
                    Spacer()
                }
                .padding(.top, 16)

                Spacer().frame(height: 32)

                if isSuccess {
                    successContent
                } else {
                    formContent
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }

    private var formContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Forgot Password")
                    .font(AppTypography.title1)
                    .foregroundColor(AppColors.primaryText)

                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 16)

            TextField("Email", text: $email)
                .controlSize(.large)
                .textFieldStyle(MonoTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .analyticsMask()

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 16)

            PrimaryButton(
                title: isLoading ? "Sending..." : "Send Reset Link"
            ) {
                Task { await sendResetLink() }
            }
            .disabled(isLoading)
        }
    }

    private var successContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primaryText)

            Text("Check your email")
                .font(AppTypography.title1)
                .foregroundColor(AppColors.primaryText)

            Text("We've sent a password reset link to \(email)")
                .font(AppTypography.body)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 16)

            PrimaryButton(title: "Back to Sign In") {
                dismiss()
            }
        }
    }

    private func sendResetLink() async {
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return
        }
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email"
            return
        }

        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            try await authService.resetPasswordForEmail(email)
            isSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ForgotPasswordView(authService: AuthService(), prefillEmail: "test@example.com")
}
