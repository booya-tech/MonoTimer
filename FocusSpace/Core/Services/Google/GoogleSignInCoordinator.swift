//
//  GoogleSignInCoordinator.swift
//  FocusSpace
//
//  Bridges Google's GIDSignIn API to the rest of the app. Owns the
//  presentation context lookup so ViewModels stay UIKit-free, and accepts a
//  hashed nonce so the resulting ID token can be replay-protected by Supabase.
//

import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class GoogleSignInCoordinator {
    struct Tokens {
        let idToken: String
        let accessToken: String
    }

    enum CoordinatorError: Error {
        case noPresentingViewController
        case missingIDToken
    }

    /// Presents the native Google sign-in sheet and returns the resulting tokens.
    /// - Parameter hashedNonce: SHA-256 hex of the raw nonce. The same raw nonce
    ///   must later be sent to Supabase so it can verify the ID token's `nonce`
    ///   claim.
    func signIn(hashedNonce: String) async throws -> Tokens {
        guard let presenter = Self.topViewController() else {
            throw CoordinatorError.noPresentingViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presenter,
            hint: nil,
            additionalScopes: nil,
            nonce: hashedNonce
        )

        guard let idToken = result.user.idToken?.tokenString else {
            throw CoordinatorError.missingIDToken
        }
        return Tokens(
            idToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }

    /// Clears the locally cached Google session. Call on user-initiated sign-out.
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    /// Revokes the OAuth grant on Google's side and clears the local session.
    /// Call on account deletion to satisfy App Store 5.1.1(v).
    func disconnect() async throws {
        try await GIDSignIn.sharedInstance.disconnect()
    }

    /// Whether the given error represents a user-initiated cancellation.
    static func isCancellation(_ error: Error) -> Bool {
        guard let gidError = error as? GIDSignInError else { return false }
        return gidError.code == .canceled
    }

    // MARK: - Presentation

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
