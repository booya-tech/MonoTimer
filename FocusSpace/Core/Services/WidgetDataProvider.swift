//
//  WidgetDataProvider.swift
//  FocusSpace
//
//  Service for sharing data between main app and widget extension via App Group
//

import Foundation
import WidgetKit

/// Manages widget data synchronization via App Group UserDefaults
@MainActor
final class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    /// App Group identifier - must match entitlements
    static let appGroupIdentifier = "group.MonoTimer"
    
    /// UserDefaults key for widget data
    private static let widgetDataKey = "widgetData"
    
    /// Shared UserDefaults for App Group
    private let sharedDefaults: UserDefaults?
    
    private init() {
        sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier)
    }
    
    // MARK: - Write Methods (Main App)
    
    /// Updates widget data based on completed sessions
    /// - Parameters:
    ///   - sessions: All completed sessions
    ///   - dailyGoal: User's daily focus goal in minutes
    func updateWidgetData(sessions: [Session], dailyGoal: Int) {
        let widgetData = computeWidgetData(from: sessions, dailyGoal: dailyGoal)
        saveWidgetData(widgetData)
        
        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Computes widget data from sessions
    private func computeWidgetData(from sessions: [Session], dailyGoal: Int) -> WidgetData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Filter today's focus sessions
        let todaySessions = sessions.filter { session in
            session.type == .focus && calendar.isDate(session.startAt, inSameDayAs: today)
        }
        
        let todayMinutes = todaySessions.reduce(0) { $0 + $1.durationMinutes }
        let progress = dailyGoal > 0 ? min(Double(todayMinutes) / Double(dailyGoal), 1.0) : 0.0
        let currentStreak = computeCurrentStreak(from: sessions)
        
        return WidgetData(
            todaySessions: todaySessions.count,
            todayMinutes: todayMinutes,
            dailyGoal: dailyGoal,
            dailyGoalProgress: progress,
            currentStreak: currentStreak,
            lastUpdated: Date()
        )
    }
    
    /// Computes current streak (consecutive days with focus sessions)
    private func computeCurrentStreak(from sessions: [Session]) -> Int {
        let calendar = Calendar.current
        var currentDate = Date()
        var streak = 0
        
        for _ in 0..<365 { // Max 1 year lookback
            let daySessions = sessions.filter { session in
                session.type == .focus && calendar.isDate(session.startAt, inSameDayAs: currentDate)
            }
            
            if daySessions.isEmpty {
                break
            }
            
            streak += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }
        
        return streak
    }
    
    /// Saves widget data to shared UserDefaults
    private func saveWidgetData(_ data: WidgetData) {
        guard let sharedDefaults = sharedDefaults else {
            Logger.log("WidgetDataProvider: Failed to access shared UserDefaults")
            return
        }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            sharedDefaults.set(encoded, forKey: Self.widgetDataKey)
            Logger.log("WidgetDataProvider: Saved widget data - \(data.todaySessions) sessions, \(data.todayMinutes) min")
        } catch {
            Logger.log("WidgetDataProvider: Failed to encode widget data - \(error)")
        }
    }
    
    // MARK: - Read Methods (Widget Extension)
    
    /// Reads widget data from shared UserDefaults
    /// Can be called from widget extension (non-MainActor)
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
