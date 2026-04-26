//
//  DeleteAccountViewModel.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 10/30/25.
//

import SwiftUI

@MainActor
final class DeleteAccountViewModel: ObservableObject {
    @Published var password: String = ""
    @Published var isDeleting = false
    @Published var errorMessage: String?
    
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func deleteAccount() async {
        isDeleting = true
        errorMessage = nil
        
        do {
            if !authService.isOAuthUser {
                guard !password.isEmpty else {
                    errorMessage = "Please enter your password"
                    return
                }
                try await authService.verifyPassword(password: password)
            }
            
            try await authService.deleteAccount()
            
        } catch {
            isDeleting = false
            errorMessage = "Failed to delete account. Please check your password."
            ErrorHandler.shared.handle(error)
        }
    }
}


