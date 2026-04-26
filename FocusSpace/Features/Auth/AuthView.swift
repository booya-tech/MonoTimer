//
//  AuthView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/24/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel

    init(authService: AuthService) {
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
    }
    
    private var appHeader: some View {
        // Header
        VStack(spacing: 8) {
            Text(AppConstants.appName)
                .font(AppTypography.title1)
                .foregroundColor(AppColors.primaryText)

            Text(viewModel.isSignUpMode ? "Create an account" : "welcome back")
                .font(AppTypography.body)
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    private var emailAndPasswordFields: some View {
        VStack(spacing: 16) {
            // Email field
            TextField("Email", text: $viewModel.email)
                .controlSize(.large)
                .textFieldStyle(MonoTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .analyticsMask()

            // Password field
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(MonoTextFieldStyle())
                .analyticsMask()

            // Confirm password (only for sign up)
            if viewModel.isSignUpMode {
                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textFieldStyle(MonoTextFieldStyle())
                    .analyticsMask()
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
            Text("OR")
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
            title: viewModel.isLoading ? "Loading..." : (viewModel.isSignUpMode ? "Sign Up" : "Sign In")
        ) {
            Task {
                await viewModel.authenticate()
            }
        }
        .disabled(viewModel.isLoading)

        Spacer().frame(height: 8)
        Button(action: viewModel.toggleMode) {
            Text(viewModel.isSignUpMode ? "Already have an account? Sign In" : "Don't have an account?  Sign Up")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
    }
}

#Preview {
    AuthView(authService: AuthService())
}
