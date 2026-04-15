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
    static let paywallYearly = "Yearly"
    static let paywallMonthly = "Monthly"
    static let paywallPeriodYear = "year"
    static let paywallPeriodMonth = "month"
    static let paywallSubscribe = "Subscribe"
    static func paywallSaveLabel(_ percent: Int) -> String {
        "Save \(percent)% vs monthly"
    }
    static func paywallGetPremium(_ price: String) -> String {
        "Get Premium — \(price)"
    }
    // Features
    static let paywallWhatYouGet = "What you get"
    static let paywallFeaturePremiumColorsTitle = "Premium Wave Colors"
    static let paywallFeaturePremiumColorsSubtitle = "All 8 gradient wave themes with glow effects"
    static let paywallFeatureExclusiveThemesTitle = "Exclusive Themes"
    static let paywallFeatureExclusiveThemesSubtitle = "New premium themes added regularly"
    static let paywallFeatureEarlyAccessTitle = "Early Access"
    static let paywallFeatureEarlyAccessSubtitle = "Be the first to try new features"
    static let paywallFeatureSupportDevTitle = "Support Development"
    static let paywallFeatureSupportDevSubtitle = "Help keep MonoTimer ad-free"
    // Bottom CTA
    static let paywallAutoRenewDisclaimer = "Plans auto-renew. Cancel anytime in Settings."
    static let paywallRestorePurchases = "Restore Purchases"
    static let paywallTerms = "Terms"
    static let paywallPrivacy = "Privacy"
    static let paywallSeparator = "·"
}
