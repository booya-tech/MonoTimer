//
//  AnalyticsBootstrap.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 4/19/26.
//
//  Single entry point for initializing analytics. Reads the PostHog API key
//  from Info.plist (mirroring `SupabaseManager`) and falls back to a no-op
//  service if the key is missing or invalid. Honors the user's opt-out
//  preference at startup.
//

import Foundation
import SwiftUI

@MainActor
final class AnalyticsBootstrap {
    /// Shared singleton, set up by `configure()` at app launch.
    static private(set) var shared: AnalyticsService = NoOpAnalyticsService()

    private static let posthogHost = "https://us.i.posthog.com"
    private static let placeholderPrefix = "phc_REPLACE"

    /// Initializes the analytics SDK exactly once. Call from `FocusSpaceApp.init()`
    /// before any ViewModels are constructed.
    static func configure() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String,
              !apiKey.isEmpty,
              !apiKey.hasPrefix(placeholderPrefix) else {
            Logger.log("⚠️ POSTHOG_API_KEY missing or unset in Info.plist - analytics disabled")
            shared = NoOpAnalyticsService()
            return
        }

        shared = PostHogAnalyticsService(apiKey: apiKey, host: posthogHost)

        // Honor any previously persisted opt-out preference.
        if !AppPreferences.shared.isAnalyticsEnabled {
            shared.optOut()
        }

        #if DEBUG
        Logger.log("✅ PostHog analytics configured")
        #endif
    }
}

// MARK: - SwiftUI Environment integration

private struct AnalyticsServiceKey: EnvironmentKey {
    @MainActor
    static var defaultValue: AnalyticsService { AnalyticsBootstrap.shared }
}

extension EnvironmentValues {
    /// Access analytics from any SwiftUI view via `@Environment(\.analytics)`.
    var analytics: AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}

// MARK: - Screen tracking view modifier

private struct AnalyticsScreenModifier: ViewModifier {
    let name: String
    let properties: [String: Any]?
    @Environment(\.analytics) private var analytics

    func body(content: Content) -> some View {
        content.onAppear {
            analytics.screen(name, properties: properties)
        }
    }
}

extension View {
    /// Captures a screen view event when the view appears. Routes through the
    /// `AnalyticsService` abstraction so no feature view needs to import the
    /// underlying SDK.
    func analyticsScreen(_ name: String, properties: [String: Any]? = nil) -> some View {
        modifier(AnalyticsScreenModifier(name: name, properties: properties))
    }
}
