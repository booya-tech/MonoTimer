//
//  FocusSpaceApp.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/22/25.
//

import SwiftUI

@main
struct FocusSpaceApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @ObservedObject private var storeKitManager = StoreKitManager.shared

    var body: some Scene {
        WindowGroup {
             RootView()
                .environmentObject(appViewModel)
                .environmentObject(AppPreferences.shared)
                .environmentObject(storeKitManager)
        }
    }
}
