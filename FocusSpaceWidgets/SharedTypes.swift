//
//  SharedTypes.swift
//  FocusSpaceWidgets
//
//  Shared data types and utilities for widget extension
//  These mirror the types in the main app for cross-process data sharing
//

import Foundation

// MARK: - Widget Data Model

/// Data structure shared between the main app and widget extension
/// Stored in App Group UserDefaults for cross-process access
struct WidgetData: Codable {
    /// Number of focus sessions completed today
    var todaySessions: Int
    
    /// Total focus minutes completed today
    var todayMinutes: Int
    
    /// User's daily focus goal in minutes
    var dailyGoal: Int
    
    /// Progress toward daily goal (0.0 - 1.0)
    var dailyGoalProgress: Double
    
    /// Current consecutive days streak
    var currentStreak: Int
    
    /// Timestamp of last data update
    var lastUpdated: Date
    
    /// Empty/default widget data
    static let empty = WidgetData(
        todaySessions: 0,
        todayMinutes: 0,
        dailyGoal: 120,
        dailyGoalProgress: 0.0,
        currentStreak: 0,
        lastUpdated: Date()
    )
}

// MARK: - Widget Data Provider (Read-only for Widget Extension)

/// Provides read access to widget data from App Group UserDefaults
enum WidgetDataProvider {
    /// App Group identifier - must match entitlements
    static let appGroupIdentifier = "group.MonoTimer"
    
    /// UserDefaults key for widget data
    private static let widgetDataKey = "widgetData"
    
    /// Reads widget data from shared UserDefaults
    static func readWidgetData() -> WidgetData {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: widgetDataKey) else {
            return .empty
        }
        
        do {
            return try JSONDecoder().decode(WidgetData.self, from: data)
        } catch {
            return .empty
        }
    }
}
