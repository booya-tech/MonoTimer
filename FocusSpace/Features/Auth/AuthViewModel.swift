//
//  AuthViewModel.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/24/25.
//
//  ViewModel for authentication screen
//

import Foundation
import AuthenticationServices
import GoogleSignIn
import UIKit

// ViewModel handling authentication UI logic and validation
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isSignUpMode: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    // Toggle between sign in and sign up modes
    func toggleMode() {
        isSignUpMode.toggle()
        clearForm()
    }

    // Clear form fields and errors
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }

    // Validate form inputs
    private func validateForm() -> Bool {
        errorMessage = ""

        guard !email.isEmpty else { 
            errorMessage = "Email is required"

            return false 
        }

        guard email.contains("@") && email.contains(".") else { 
            errorMessage = "Please enter a valid email"

            return false    
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"

            return false
        }

        if isSignUpMode {
            guard password == confirmPassword else {
                errorMessage = "Passwords don't match"

                return false
            }
        }

        return true
    }

    // Handle sign in or sign up action
    func authenticate() async {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = ""

        defer { isLoading = false }

        do {
            if isSignUpMode {
                try await authService.signUp(
                    email: email,
                    password: password
                )
            } else {
                try await authService.signIn(
                    email: email,
                    password: password
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            ErrorHandler.shared.handle(error)
        }
    }
    
    // Handle Sign in with Apple result
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        
        do {
            switch result {
            case .success(let authorization):
                // Extract the credential from the button's result
                guard
                    let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                    let identityToken = credential.identityToken,
                    let tokenString = String(data: identityToken, encoding: .utf8)
                else {
                    errorMessage = "Failed to get Apple credentials"
                    return
                }
                try await authService.signInWithApple(tokenString)
            case .failure(let error):
                // Check if user cancelled
                if let authError = error as? ASAuthorizationError,
                   authError.code == .canceled {
                    throw AppError.userCancelled
                } else {
                    throw AppError.from(error)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            ErrorHandler.shared.handle(error)
        }
    }

    // Drive the native GoogleSignIn-iOS sheet, then exchange the ID token with Supabase
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            guard let presentingVC = Self.topViewController() else {
                throw AppError.authenticationFailed("Unable to present sign-in")
            }

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google did not return an ID token"
                return
            }
            let accessToken = result.user.accessToken.tokenString

            try await authService.signInWithGoogle(idToken: idToken, accessToken: accessToken)
        } catch {
            // Silently swallow user-initiated cancellations
            if (error as NSError).code == GIDSignInError.canceled.rawValue { return }
            errorMessage = error.localizedDescription
            ErrorHandler.shared.handle(error)
        }
    }

    // Walks the window scene's view-controller hierarchy to find the topmost
    // controller capable of presenting the Google sign-in sheet.
    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController

        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
}
