//
//  AnalyticsService.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 4/19/26.
//
//  Protocol-based analytics abstraction so ViewModels never import a concrete
//  analytics SDK directly. Concrete implementations live alongside this file.
//

import Foundation

// MARK: - Service protocol

/// Lightweight analytics abstraction used by ViewModels and Views.
/// Implementations: `PostHogAnalyticsService`, `NoOpAnalyticsService`.
protocol AnalyticsService: AnyObject {
    func capture(_ event: AnalyticsEvent)
    func identify(userId: String, properties: [String: Any]?)
    func reset()
    func screen(_ name: String, properties: [String: Any]?)
    func isFeatureEnabled(_ key: String) -> Bool
    /// Forces a fresh fetch of remote feature flag values. Call before reading
    /// a flag whose value must be authoritative on first launch (e.g. A/B
    /// variants on the paywall).
    func reloadFeatureFlags() async
    func optIn()
    func optOut()
}

extension AnalyticsService {
    func identify(userId: String) {
        identify(userId: userId, properties: nil)
    }

    func screen(_ name: String) {
        screen(name, properties: nil)
    }
}
