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

        // Kick off RC fetches AFTER `Purchases.configure(...)`. Doing this
        // from `PurchaseManager.init` would race the configure call because
        // the `shared` singleton is materialized by the property initializer
        // on line 14, which runs before this `init` body.
        Task { @MainActor in
            await PurchaseManager.shared.loadOfferings()
            await PurchaseManager.shared.refreshCustomerInfo()
        }
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
