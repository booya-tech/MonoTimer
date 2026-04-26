//
//  AuthNonce.swift
//  FocusSpace
//
//  Helpers for generating OIDC nonces used in native Sign in with Apple and
//  Google flows. The raw nonce is sent to Supabase, the SHA-256 hash is sent
//  to the identity provider; the provider embeds the hash in the issued ID
//  token's `nonce` claim, which Supabase then verifies against the raw value.
//

import Foundation
import CryptoKit

enum AuthNonce {
    /// Returns a cryptographically secure URL-safe random string.
    static func random(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")

        var result = ""
        result.reserveCapacity(length)
        var remaining = length

        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            precondition(status == errSecSuccess, "SecRandomCopyBytes failed: \(status)")

            for byte in bytes where remaining > 0 {
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    /// Returns the SHA-256 hex digest of the input string.
    static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
