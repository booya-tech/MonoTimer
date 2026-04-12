//
//  Constants.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/20/25.
//
//  App-wide constants and configuration
//

import Foundation

enum AppConstants {
    //MARK: - App Name
    static let appName = "MonoTimer"
    
    // MARK: - URLs
    enum URLs {
        static let github = "https://github.com/booya-tech/MonoTimer"
        static let privacyPolicy = "https://github.com/booya-tech/MonoTimer/blob/main/docs/privacy-policy.md"
        static let termsOfService = "https://github.com/booya-tech/MonoTimer/blob/main/docs/terms-of-service.md"
    }
    
    // MARK: - Timer Defaults
    enum Timer {
        static let defaultFocusDuration = 25
        static let defaultBreakDuration = 5
        static let availableFocusDurations = [25, 30, 35, 40, 45, 50, 60, 90, 120]
        static let availableBreakDurations = [5, 10, 15, 20, 25, 30]
    }
    
    // MARK: - Goals
    enum Goals {
        static let defaultDailyGoal = 120 // minutes
    }
    
    // MARK: - UI
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let largePadding: CGFloat = 24
        static let mediumPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
    }
}

//MARK: - Session Notification

extension SessionType {
    var notificationTitle: String {
        switch self {
            case .focus: return "Focus Session Completed!"
            case .shortBreak: return "Break Time Over!"
            case .longBreak: return "Long Break Time Over!"
        }
    }

    func notificationBody(presetName: String) -> String {
        switch self {
        case .focus:
            return "Great work! Your \(presetName)-minute focus session is done. Open the app to start your break."
        case .shortBreak:
            return "Ready to get back to work? Your break is over."
        case .longBreak:
            return "Refreshed and ready! Time to start your next focus session."
        }
    }
}

//MARK: - Schedule Notification

enum DailyReminder: String, CaseIterable {
    case morning = "daily_morning"
    case midday = "daily_midday"
    case evening = "daily_evening"

    var hour: Int {
        switch self {
        case .morning:  return 6
        case .midday:   return 12
        case .evening:  return 18
        }
    }

    var title: String {
        switch self {
        case .morning:  return "Morning Focus"
        case .midday:   return "Midday Focus"
        case .evening:  return "Evening Focus Time!"
        }
    }

    var body: String {
        switch self {
        case .morning:  return "A fresh day awaits — start a focus session to build momentum. 🔥"
        case .midday:   return "Keep the momentum going with an afternoon focus session. 💎"
        case .evening:  return "Start your session to keep the flow alive. 🌊"
        }
    }
}
