//
//  AuthService.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/24/25.
//
//  Authentication service for email/password sign-in
//

import Foundation
import Supabase
import Auth

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: User? = nil
    @Published var isLoading = false
    @Published var isInitialized = false

    private var supabase: SupabaseClient? { SupabaseManager.shared.client }
    private let googleSignIn: GoogleSignInCoordinator

    // True if the user has any third-party identity (Apple, Google, …).
    // Hybrid users (email + OAuth) are also considered OAuth: the password
    // gate is skipped because they can re-authenticate via the OAuth flow.
    var isOAuthUser: Bool {
        currentUser?.identities?.contains {
            $0.provider == "apple" || $0.provider == "google"
        } ?? false
    }

    // True if the user has an Apple identity linked (primary or secondary).
    var isAppleUser: Bool {
        currentUser?.identities?.contains { $0.provider == "apple" } ?? false
    }

    init(googleSignIn: GoogleSignInCoordinator? = nil) {
        self.googleSignIn = googleSignIn ?? GoogleSignInCoordinator()
        Task {
            await checkCurrentSession()
        }
    }

    // Check if user has an existing session
    private func checkCurrentSession() async {
        guard let supabase else {
            Logger.log("Supabase not configured - skipping session check")
            isInitialized = true
            return
        }
        
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
        } catch {
            Logger.log("No existing session found")
            currentUser = nil
        }

        isInitialized = true
    }

    // Sign up with email and password
    func signUp(email: String, password: String) async throws {
        guard let supabase else { throw AuthError.serviceUnavailable }
        
        isLoading = true
        defer { isLoading = false }

        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )

        currentUser = response.user
    }

    // Sign in with email and password
    func signIn(email: String, password: String) async throws {
        guard let supabase else { throw AuthError.serviceUnavailable }
        
        isLoading = true
        defer { isLoading = false }

        let response = try await supabase.auth.signIn(
            email: email,
            password: password
        )

        currentUser = response.user
    }

    /// Sign in with Apple via Supabase. `nonce` is the raw value whose SHA-256
    /// was passed to `ASAuthorizationAppleIDRequest.nonce`; Supabase verifies
    /// the ID token's `nonce` claim matches `sha256(nonce)`.
    func signInWithApple(idToken: String, nonce: String) async throws {
        guard let supabase else { throw AuthError.serviceUnavailable }

        isLoading = true
        defer { isLoading = false }

        let response = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )

        currentUser = response.user
    }

    /// Sign in with Google via Supabase using a native ID token from
    /// GoogleSignIn-iOS. `nonce` is the raw value whose SHA-256 was passed to
    /// `GIDSignIn.signIn(...nonce:)`.
    func signInWithGoogle(idToken: String, accessToken: String, nonce: String) async throws {
        guard let supabase else { throw AuthError.serviceUnavailable }

        isLoading = true
        defer { isLoading = false }

        let response = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken,
                nonce: nonce
            )
        )

        currentUser = response.user
    }

    // Sign out current user
    func signOut() async throws {
        guard let supabase else { throw AuthError.serviceUnavailable }
        
        isLoading = true
        defer { isLoading = false }

        try await supabase.auth.signOut()
        // Also clear any cached Google session so the next "Continue with
        // Google" prompts the account chooser instead of silently re-binding.
        googleSignIn.signOut()
        currentUser = nil
    }

    // Verify password before sensitive operations
    func verifyPassword(password: String) async throws {
        guard let supabase else { throw AuthError.serviceUnavailable }
        guard let email = currentUser?.email else {
            throw AuthError.notAuthenticated
        }

        // Re-authenticate with current credentials
        _ = try await supabase.auth.signIn(
            email: email,
            password: password
        )
    }

    // Check if user is authenticated
    var isAuthenticated: Bool {
        currentUser != nil
    }

    // Delete user account and all associated data
    func deleteAccount() async throws {
        guard let supabase else { throw AuthError.serviceUnavailable }
        
        isLoading = true
        defer { isLoading = false }

        // Step 1: Delete all user data from database
        try await supabase.rpc("delete_own_account").execute()

        // Step 2: Sign out (revokes auth session)
        try await supabase.auth.signOut()

        // Step 3: Revoke the Google OAuth grant (App Store 5.1.1(v)).
        // Best-effort: if the user is not a Google user or the network call
        // fails, we still proceed with local cleanup.
        try? await googleSignIn.disconnect()

        // Step 4: Clear local state
        currentUser = nil
    }
}
