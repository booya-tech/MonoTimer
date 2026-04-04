//
//  WidgetData.swift
//  FocusSpace
//
//  Shared data model for widget communication via App Group
//

import Foundation

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
