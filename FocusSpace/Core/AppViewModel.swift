//
//  AppViewModel.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/23/25.
//

import SwiftUI
import Combine

@MainActor
final class AppViewModel: NSObject,ObservableObject {
    @Published var authService = AuthService()
    @Published var notificationManager = NotificationManager.shared
    @Published var isLoading = true

    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        authService.$isInitialized
            .filter { $0 == true }
            .sink { [weak self] _ in
                Task { @MainActor in
                    if self?.authService.currentUser != nil {
                        await self?.requestNotificationPermissions()
                    }
                    // small delay for smooth transition
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    // show appropriate view based on authentication state
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    var isAuthenticated: Bool {
        authService.currentUser != nil
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            Logger.log("Sign out error: \(error.localizedDescription)")
        }
    }

    // Add notification permission request
    private func requestNotificationPermissions() async {
        await notificationManager.requestPermission()
    }
}
