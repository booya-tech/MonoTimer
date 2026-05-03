//
//  AppString.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 10/31/25.
//

import Foundation

enum AppString {
    // Navigation Title
    static let profileViewTitle = "Profile"
    
    // Global String
    static let signIn = "Sign In"
    static let signOut = "Sign Out"
    static let cancel = "Cancel"
    static let version = "Version"
    static let about = "About"
    static let unknown = "Unknown"
    static let delete = "Delete"
    static let retry = "Retry"
    static let skip = "Skip"
    static let ok = "OK"
    
    // Profile View
    static let profileViewSignOutTitle = "Are you sure you want to sign out? Your data will be synced before signing out."
    static let profileViewStatsTitle = "Your Stats"
    static let profileViewStateRowSessions = "Total Sessions"
    static let profileViewStateRowFocusTime = "Total Focus Time"
    static let profileViewStateRowCurrentStreak = "Current Streak"
    static let profileViewDeleteAccount = "Delete Account"
    
    // Delete Account View
    static let deleteAccount = "Delete Account"
    static let deleteAccountViewDialogTitle = "Deleting your account will permanently remove all your data, including focus sessions, statistics, and personal information. This action cannot be undone."
    
    // Habit Streaks Board View
    static let habitStreaksTitle = "Habit Streaks"
    
    // Paywall View
    // Error State
    static let paywallErrorTitle = "Unable to load plans"
    static let paywallErrorSubTitle = "Check your connection and try again."
    static let paywallAlertError = "Purchase Error"
    // Section Title
    static let paywallHeaderSectionTitle = "Select Plan"
    // Plan Labels
    static let paywallStandard = "Standard"
    static let paywallYearly = "Yearly"
    static let paywallMonthly = "Monthly"
    static let paywallFreeForever = "Free forever"
    static let paywallPeriodYear = "year"
    static let paywallPeriodMonth = "month"
    static let paywallSubscribe = "Subscribe"
    static let paywallCurrentPlan = "Current Plan"
    static func paywallSaveLabel(_ percent: Int) -> String {
        "Save \(percent)% vs monthly"
    }
    static func paywallGetPremium(_ price: String) -> String {
        "Get Premium — \(price)"
    }
    // Standard Features
    static let paywallWhatYouGet = "What you get"
    static let paywallFeatureBasicTimerTitle = "Basic Timer"
    static let paywallFeatureBasicTimerSubtitle = "Focus and break timer with presets"
    static let paywallFeatureFocusSessionsTitle = "Focus Sessions"
    static let paywallFeatureFocusSessionsSubtitle = "Track your daily focus sessions"
    static let paywallFeatureCustomDurationTitle = "Custom Duration"
    static let paywallFeatureCustomDurationSubtitle = "Custom break and focus duration"
    static let paywallFeatureSessionHistoryTitle = "Session History"
    static let paywallFeatureSessionHistorySubtitle = "View your past focus activity"
    static let paywallFeatureLightDarkModeTitle = "Light & Dark Mode"
    static let paywallFeatureLightDarkModeSubtitle = "Choose the appearance that suits you"
    // Premium Features
    static let paywallFeaturePremiumColorsTitle = "Premium Wave Colors"
    static let paywallFeaturePremiumColorsSubtitle = "All 8 gradient wave themes with glow effects"
    static let paywallFeatureExclusiveThemesTitle = "Exclusive Themes"
    static let paywallFeatureExclusiveThemesSubtitle = "New premium themes added regularly"
    static let paywallFeatureEarlyAccessTitle = "Early Access"
    static let paywallFeatureEarlyAccessSubtitle = "Be the first to try new features"
    static let paywallFeatureSupportDevTitle = "Support Development"
    static let paywallFeatureSupportDevSubtitle = "Help keep MonoTimer ad-free"
    static let paywallFeatureSessionTagTitle = "Up to 20 Custom Tags"
    static let paywallFeatureSessionTagSubtitle = "Label sessions with your own tags — free users get 3"
    // Bottom CTA
    static let paywallAutoRenewDisclaimer = "Plans auto-renew. Cancel anytime in Settings."
    static let paywallRestorePurchases = "Restore Purchases"
    static let paywallTerms = "Terms"
    static let paywallPrivacy = "Privacy"
    static let paywallSeparator = "|"

    // Onboarding
    static let onboardingGetStarted = "Get Started"
    static let onboardingContinue = "Continue"
    static let onboardingNotNow = "Not now"
    static let onboardingEnableNotifications = "Enable Notifications"

    static let onboardingWelcomeTitle = "Focus in monochrome."
    static let onboardingWelcomeSubtitle = "Distraction-free focus sessions, your way."

    static let onboardingFocusLengthTitle = "How long do you usually focus?"
    static let onboardingFocusLengthSubtitle = "You can change this anytime in Settings."

    static let onboardingDailyGoalTitle = "What's your daily focus goal?"
    static let onboardingDailyGoalSubtitle = "We'll track your progress on the dashboard."

    static let onboardingNotificationsTitle = "Stay on track."
    static let onboardingNotificationsSubtitle = "Get notified when sessions and breaks end."
}
