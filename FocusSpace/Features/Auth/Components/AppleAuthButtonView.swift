//
//  AppleAuthButtonView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/26/26.
//

import SwiftUI
import AuthenticationServices

struct AppleAuthButtonView: View {
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: onCompletion
        )
        .frame(height: 50)
        .cornerRadius(8)
    }
}

#Preview {
    AppleAuthButtonView(onCompletion: { _ in })
}
