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
    private let googleSignIn: GoogleSignInCoordinator

    // Raw nonce kept for the duration of an in-flight Apple sign-in. Set in
    // `configureAppleRequest`, consumed in `handleAppleSignIn`.
    private var pendingAppleNonce: String?

    init(
        authService: AuthService,
        googleSignIn: GoogleSignInCoordinator? = nil
    ) {
        self.authService = authService
        self.googleSignIn = googleSignIn ?? GoogleSignInCoordinator()
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

    /// Configure the Apple sign-in request with a fresh nonce. Pass this as
    /// the `onRequest` closure of `SignInWithAppleButton`.
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AuthNonce.random()
        pendingAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = AuthNonce.sha256(nonce)
    }

    // Handle Sign in with Apple result
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = ""
        defer {
            isLoading = false
            pendingAppleNonce = nil
        }

        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityToken = credential.identityToken,
                let tokenString = String(data: identityToken, encoding: .utf8)
            else {
                errorMessage = "Failed to get Apple credentials"
                return
            }
            guard let nonce = pendingAppleNonce else {
                errorMessage = "Missing sign-in nonce. Please try again."
                return
            }
            do {
                try await authService.signInWithApple(idToken: tokenString, nonce: nonce)
            } catch {
                errorMessage = error.localizedDescription
                ErrorHandler.shared.handle(error)
            }

        case .failure(let error):
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                Logger.log("Apple sign-in cancelled")
                return
            }
            errorMessage = error.localizedDescription
            ErrorHandler.shared.handle(error)
        }
    }

    // Drive the native GoogleSignIn-iOS sheet, then exchange the ID token with Supabase
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        let nonce = AuthNonce.random()
        let hashedNonce = AuthNonce.sha256(nonce)

        do {
            let tokens = try await googleSignIn.signIn(hashedNonce: hashedNonce)
            try await authService.signInWithGoogle(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken,
                nonce: nonce
            )
        } catch {
            if GoogleSignInCoordinator.isCancellation(error) {
                Logger.log("Google sign-in cancelled")
                return
            }
            errorMessage = error.localizedDescription
            ErrorHandler.shared.handle(error)
        }
    }
}
