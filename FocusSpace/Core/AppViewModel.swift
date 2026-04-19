//
//  AppViewModel.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/23/25.
//

import SwiftUI
import Combine
import Auth

@MainActor
final class AppViewModel: NSObject,ObservableObject {
    @Published var authService = AuthService()
    @Published var notificationManager = NotificationManager.shared
    @Published var isLoading = true

    private let analytics: AnalyticsService
    private var cancellables = Set<AnyCancellable>()
    // Tracks the last user id we identified to avoid duplicate identify calls
    // when `currentUser` re-publishes the same value.
    private var lastIdentifiedUserId: String?

    @MainActor
    init(analytics: AnalyticsService? = nil) {
        // Default value resolved here (not in the parameter list) because
        // default expressions are evaluated in a nonisolated context, while
        // `AnalyticsBootstrap.shared` is `@MainActor`-isolated.
        self.analytics = analytics ?? AnalyticsBootstrap.shared
        super.init()

        authService.$isInitialized
            .filter { $0 == true }
            .sink { [weak self] _ in
                Task { @MainActor in
                    if let user = self?.authService.currentUser {
                        // Restore identity for users who were already signed in
                        // before this launch (session restored from Keychain).
                        self?.identifyIfNeeded(user)
                        await self?.requestNotificationPermissions()
                        await self?.scheduleDailyReminders()
                    }
                    // small delay for smooth transition
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    // show appropriate view based on authentication state
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)

        authService.$currentUser
            .removeDuplicates { $0?.id == $1?.id }
            .sink { [weak self] user in
                guard let self else { return }
                if let user {
                    self.identifyIfNeeded(user)
                } else if self.lastIdentifiedUserId != nil {
                    self.analytics.capture(.authSignedOut)
                    self.analytics.reset()
                    self.lastIdentifiedUserId = nil
                }
            }
            .store(in: &cancellables)

        authService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    /// Sends `identify` to analytics exactly once per signed-in user. The
    /// `auth_signed_in` event is also captured on the first identify of a
    /// session.
    private func identifyIfNeeded(_ user: User) {
        let userId = user.id.uuidString
        guard lastIdentifiedUserId != userId else { return }

        // Mirrors AuthService.isAppleUser - AnyJSON's ExpressibleByStringLiteral
        // conformance enables direct equality with a string literal.
        let provider = user.appMetadata["provider"] == "apple" ? "apple" : "email"
        analytics.identify(
            userId: userId,
            properties: ["auth_provider": provider]
        )
        analytics.capture(.authSignedIn(method: provider))
        lastIdentifiedUserId = userId
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

    // Schedule daily reminders
    private func scheduleDailyReminders() async {
        await notificationManager.scheduleDailyReminders()
    }
}
