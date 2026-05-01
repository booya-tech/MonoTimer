//
//  RootView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/27/25.
//
//  Root view handling authentication flow
//

import SwiftUI

/// Root view that handles navigation between authenticated and unauthenticated states
struct RootView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var storeKitManager: StoreKitManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if appViewModel.isLoading {
              SplashScreenView()
            } else if !preferences.hasCompletedOnboarding {
                OnboardingView()
            } else if appViewModel.isAuthenticated {
                // display MainTabView
                MainTabView()
                    .environmentObject(appViewModel.authService)
            } else {
                // display AuthView
                AuthView(authService: appViewModel.authService)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appViewModel.isLoading)
        .animation(.easeInOut(duration: 0.3), value: preferences.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appViewModel.authService.currentUser != nil)
        .onChange(of: scenePhase) { (_, newPhase) in
            if newPhase == .active {
                Task { await storeKitManager.updatePurchasedProducts() }
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppViewModel())
        .environmentObject(AppPreferences.shared)
        .environmentObject(StoreKitManager.shared)
}
