//
//  PostHogAnalyticsService.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 4/19/26.
//
//  PostHog-backed implementation of `AnalyticsService`. Configures the SDK
//  on init and forwards typed events as snake_case strings.
//

import Foundation
import PostHog
import SwiftUI

final class PostHogAnalyticsService: AnalyticsService {
    /// Toggle to enable PostHog Session Replay. Kept off by default - flipping
    /// to `true` should be paired with a review of every PII surface in the
    /// app (text inputs are auto-masked, but free-form labels are not).
    static let sessionReplayEnabled = false

    init(apiKey: String, host: String) {
        let config = PostHogConfig(apiKey: apiKey, host: host)
        // We use `.analyticsScreen()` modifiers for SwiftUI screen tracking
        // because automatic SwiftUI screen names are based on internal view IDs
        // and are not human-readable.
        config.captureScreenViews = false
        config.captureApplicationLifecycleEvents = true
        // Use `.always` so anonymous pre-login events create a person profile
        // that PostHog can merge with the identified user on sign-in. With
        // `.identifiedOnly` the activation funnel `app_launched -> auth_signed_in`
        // splits across two distinct ids and breaks attribution.
        config.personProfiles = .always

        // Session replay is opt-in. When enabled, the SDK auto-masks all text
        // inputs and images, and `.analyticsMask()` is applied to PII surfaces
        // (see Auth, Profile, MonoTextField).
        config.sessionReplay = Self.sessionReplayEnabled
        config.sessionReplayConfig.maskAllTextInputs = true
        config.sessionReplayConfig.maskAllImages = true

        PostHogSDK.shared.setup(config)
    }

    func capture(_ event: AnalyticsEvent) {
        if let properties = event.properties {
            PostHogSDK.shared.capture(event.name, properties: properties)
        } else {
            PostHogSDK.shared.capture(event.name)
        }
    }

    func identify(userId: String, properties: [String: Any]?) {
        if let properties {
            PostHogSDK.shared.identify(userId, userProperties: properties)
        } else {
            PostHogSDK.shared.identify(userId)
        }
    }

    func reset() {
        PostHogSDK.shared.reset()
    }

    func screen(_ name: String, properties: [String: Any]?) {
        if let properties {
            PostHogSDK.shared.screen(name, properties: properties)
        } else {
            PostHogSDK.shared.screen(name)
        }
    }

    func isFeatureEnabled(_ key: String) -> Bool {
        PostHogSDK.shared.isFeatureEnabled(key)
    }

    func reloadFeatureFlags() async {
        await withCheckedContinuation { continuation in
            PostHogSDK.shared.reloadFeatureFlags {
                continuation.resume()
            }
        }
    }

    func optIn() {
        PostHogSDK.shared.optIn()
    }

    func optOut() {
        PostHogSDK.shared.optOut()
    }
}

// MARK: - Session replay masking

extension View {
    /// Marks a view as containing PII so it is masked out in session replay
    /// recordings. Safe to call even when session replay is disabled.
    func analyticsMask() -> some View {
        postHogMask()
    }
}
