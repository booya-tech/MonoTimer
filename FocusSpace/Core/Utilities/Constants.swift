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
    
    #if DEBUG
    static let isDebugMode = true
    #else
    static let isDebugMode = false
    #endif
    
    //MARK: - Icons
    public enum Icon {
        static let chevronLeft = "chevron.left"
        static let chevronRight = "chevron.right"
        static let wifiSlash = "wifi.slash"
        static let personFill = "person.fill"
        static let timerFill = "timer"
        static let clockFill = "clock.fill"
        static let circleFill = "circle.lefthalf.filled"
        static let crownFill = "👑"
        static let paintpaletteFill = "paintpalette.fill"
        static let sparkles = "sparkles"
        static let starFill = "star.fill"
        static let hourglassBottomHalfFilled = "hourglass.bottomhalf.filled"
        static let heartFill = "heart.fill"
        static let chartBarFill = "chart.bar.fill"
        static let plus = "plus"
        static let checkmark = "checkmark"
        static let pencil = "pencil"
        static let lockFill = "lock.fill"
        static let trash = "trash"
    }

    // MARK: - Tag Picker
    enum Tag {
        static let navigationTitle = "Tags"
        static let done = "Done"
        static let save = "Save"
        static let cancel = "Cancel"
        static let add = "Add"
        static let delete = "Delete"
        static let createNew = "Create new tag"
        static let tagNamePlaceholder = "Tag name"
        static let newTagNamePlaceholder = "New tag name"
        static let addTagAccessibility = "Add tag"
        static var upgradeLabel: String {
            "Upgrade for up to \(Premium.premiumCustomTagLimit) tags"
        }
        static func upgradeOverLimitLabel(count: Int) -> String {
            "Upgrade to keep all \(count) tags"
        }
    }
    
    // MARK: - URLs
    enum URLs {
        static let github = "https://github.com/booya-tech/MonoTimer"
        static let privacyPolicy = "https://booya-pannachai.notion.site/Privacy-Policy-for-MonoTimer-34be6eb508b080ef8103f1343b726928?source=copy_link"
        static let termsOfService = "https://booya-pannachai.notion.site/Terms-of-Service-for-MonoTimer-34be6eb508b080c08b19c300669639e1?source=copy_link"

        static let privacyPolicyURL = URL(string: privacyPolicy)!
        static let termsOfServiceURL = URL(string: termsOfService)!
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

    // MARK: - Onboarding
    enum Onboarding {
        static let currentVersion = 1
        static let focusLengthChoices = [25, 30, 45, 50]
        static let dailyGoalChoices = [30, 60, 120, 180]
    }
    
    // MARK: - UI
    enum UI {
        static let circleSize: CGFloat = 220
        static let circleFrameSize: CGFloat = circleSize + 2
        static let cornerRadius: CGFloat = 12
        static let largePadding: CGFloat = 24
        static let mediumPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let onboardingHeroSize: CGFloat = 220
    }
    
    enum Premium {
        static let minPremiumValue: Int = 4
        static let freeCustomTagLimit = 3
        static let premiumCustomTagLimit = 20
    }
    
    // MARK: - Chart
    enum Chart {
        static let maxYearsBack = 10
    }
    
    #if DEBUG
    // MARK: - Mock Data
    enum MockData {
        static let yearlyChartData: [Int: [DayData]] = {
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"

            var result: [Int: [DayData]] = [:]
            for yearOffset in 0...Chart.maxYearsBack {
                let year = currentYear - yearOffset
                let data: [DayData] = (1...12).compactMap { month in
                    var comps = DateComponents()
                    comps.year = year
                    comps.month = month
                    comps.day = 1
                    guard let date = calendar.date(from: comps) else { return nil }
                    let minutes = Int.random(in: 0...300)
                    return DayData(day: monthFormatter.string(from: date), minutes: minutes, date: date)
                }
                result[year] = data
            }
            return result
        }()
    }
    #endif
    
    // MARK: - StoreKit
    enum StoreKit {
        static let premiumMonthly = "com.monotimer.premium.monthly"
        static let premiumYearly = "com.monotimer.premium.yearly"
        static let subscriptionGroupID = "premium"
        
        static let allProductIDs: Set<String> = [
            premiumMonthly,
            premiumYearly
        ]
    }

    // MARK: - Analytics
    enum Analytics {
        /// Human-readable screen names sent to PostHog via `.analyticsScreen(_:)`.
        /// Centralized so renames stay consistent across the app and dashboards.
        enum Screen {
            static let timer = "Timer"
            static let dashboard = "Dashboard"
            static let profile = "Profile"
            static let settings = "Settings"
            static let auth = "Auth"
            static let paywall = "Paywall"
            static let onboarding = "Onboarding"
        }
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
