//
//  NoOpAnalyticsService.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 4/19/26.
//
//  Silent fallback used when the API key is missing, when the user has opted
//  out, and in unit tests. All calls are intentional no-ops.
//

import Foundation

final class NoOpAnalyticsService: AnalyticsService {
    func capture(_ event: AnalyticsEvent) {}
    func identify(userId: String, properties: [String: Any]?) {}
    func reset() {}
    func screen(_ name: String, properties: [String: Any]?) {}
    func isFeatureEnabled(_ key: String) -> Bool { false }
    func reloadFeatureFlags() async {}
    func optIn() {}
    func optOut() {}
}
