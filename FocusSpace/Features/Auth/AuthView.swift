//
//  AuthView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/24/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showForgotPassword = false

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }

            VStack(spacing: 0) {
                Spacer().frame(height: 32)
                // Header
                appHeader
                
                Spacer().frame(height: 32)
                // Email & Password Fields
                emailAndPasswordFields
                
                Spacer().frame(height: 32)
                // Apple Sign-in and Normal Sign-in Buttons
                VStack(spacing: 0) {
                    Spacer().frame(height: 8)
                    customDivider
                    
                    Spacer().frame(height: 8)
                    AppleAuthButtonView(
                        isLoading: viewModel.isLoading,
                        onRequest: viewModel.configureAppleRequest,
                        onCompletion: { result in
                            Task {
                                await viewModel.handleAppleSignIn(result)
                            }
                        }
                    )

                    Spacer().frame(height: 8)
                    GoogleAuthButtonView(isLoading: viewModel.isLoading) {
                        Task { await viewModel.signInWithGoogle() }
                    }

                    Spacer().frame(height: 16)
                    primaryButton
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .analyticsScreen(AppConstants.Analytics.Screen.auth)
        .fullScreenCover(isPresented: $showForgotPassword) {
            ForgotPasswordView(authService: authService, prefillEmail: viewModel.email)
        }
    }
    
    private var appHeader: some View {
        // Header
        VStack(spacing: 8) {
            Text(AppConstants.appName)
                .font(AppTypography.title1)
                .foregroundColor(AppColors.primaryText)

            Text(viewModel.isSignUpMode ? AppString.Auth.createAccount : AppString.Auth.welcomeBack)
                .font(AppTypography.body)
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    private var emailAndPasswordFields: some View {
        VStack(spacing: 16) {
            // Email field
            TextField(AppString.Auth.emailPlaceholder, text: $viewModel.email)
                .controlSize(.large)
                .textFieldStyle(MonoTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .analyticsMask()

            // Password field
            PasswordField(placeholder: AppString.Auth.passwordPlaceholder, text: $viewModel.password, isVisible: $showPassword)

            if !viewModel.isSignUpMode {
                HStack {
                    Spacer()
                    Button(AppString.Auth.forgotPassword) {
                        showForgotPassword = true
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
                }
            }

            // Confirm password (only for sign up)
            if viewModel.isSignUpMode {
                PasswordField(placeholder: AppString.Auth.confirmPasswordPlaceholder, text: $viewModel.confirmPassword, isVisible: $showConfirmPassword)
            }

            // Error message
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        
    }
    
    private var customDivider: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.secondaryText.opacity(0.3))
            Text(AppString.Auth.orDivider)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.secondaryText.opacity(0.3))
        }
    }
    
    @ViewBuilder
    private var primaryButton: some View {
        // Main action button
        PrimaryButton(
            title: viewModel.isLoading ? AppString.Auth.loading : (viewModel.isSignUpMode ? AppString.Auth.signUp : AppString.signIn)
        ) {
            Task {
                await viewModel.authenticate()
            }
        }
        .disabled(viewModel.isLoading)

        Spacer().frame(height: 12)
        
        Button(action: viewModel.toggleMode) {
            Text(viewModel.isSignUpMode ? AppString.Auth.alreadyHaveAccount : AppString.Auth.dontHaveAccount)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
    }
}

#Preview {
    AuthView(authService: AuthService())
}
