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
    
    enum Premium {
        static let minPremiumValue: Int = 4
    }
}
