//
//  AppleAuthButtonView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/26/26.
//

import SwiftUI
import AuthenticationServices

struct AppleAuthButtonView: View {
    var isLoading: Bool = false
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: onRequest,
            onCompletion: onCompletion
        )
        .frame(height: 50)
        .cornerRadius(8)
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
}

#Preview {
    AppleAuthButtonView(
        onRequest: { _ in },
        onCompletion: { _ in }
    )
}
