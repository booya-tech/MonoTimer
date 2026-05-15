//
//  FocusSpaceApp.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/22/25.
//

import SwiftUI
import GoogleSignIn

@main
struct FocusSpaceApp: App {
    @StateObject private var appViewModel: AppViewModel
    @ObservedObject private var purchaseManager = PurchaseManager.shared

    init() {
        // Configure analytics before any ViewModel is constructed so the
        // `AppViewModel` auth observer can immediately call `identify`.
        AnalyticsBootstrap.configure()
        PurchaseManager.configure()
        AnalyticsBootstrap.shared.capture(.appLaunched)
        _appViewModel = StateObject(wrappedValue: AppViewModel())
    }

    var body: some Scene {
        WindowGroup {
             RootView()
                .environmentObject(appViewModel)
                .environmentObject(AppPreferences.shared)
                .environmentObject(purchaseManager)
                .environment(\.analytics, AnalyticsBootstrap.shared)
                .onOpenURL { url in
                    if url.scheme == AppConstants.URLs.deepLinkScheme {
                        Task {
                            do {
                                try await appViewModel.authService.handleDeepLink(url)
                            } catch {
                                Logger.log("Deep link handling failed: \(error.localizedDescription)")
                                ErrorHandler.shared.handle(error)
                            }
                        }
                    } else {
                        GIDSignIn.sharedInstance.handle(url)
                    }
                }
        }
    }
}
