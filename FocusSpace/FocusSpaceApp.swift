//
//  FocusSpaceApp.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/22/25.
//

import SwiftUI

@main
struct FocusSpaceApp: App {
    @StateObject private var appViewModel: AppViewModel
    @ObservedObject private var storeKitManager = StoreKitManager.shared

    init() {
        // Configure analytics before any ViewModel is constructed so the
        // `AppViewModel` auth observer can immediately call `identify`.
        AnalyticsBootstrap.configure()
        AnalyticsBootstrap.shared.capture(.appLaunched)
        _appViewModel = StateObject(wrappedValue: AppViewModel())
    }

    var body: some Scene {
        WindowGroup {
             RootView()
                .environmentObject(appViewModel)
                .environmentObject(AppPreferences.shared)
                .environmentObject(storeKitManager)
                .environment(\.analytics, AnalyticsBootstrap.shared)
        }
    }
}
