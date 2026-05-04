//
//  AnalyticEvents.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/19/26.
//
// MARK: - Strongly-typed analytics events

/// All app-level analytics events. Keep this list as the single source of truth
/// for naming. Each case maps to a snake_case event name in the concrete service.
enum AnalyticsEvent {
    // App lifecycle
    case appLaunched

    // Auth
    case authSignedIn(method: String)
    case authSignedOut

    // Timer
    case timerStarted(presetMinutes: Int, sessionType: String, isStrictMode: Bool)
    case timerPaused(remainingSeconds: Int)
    case timerResumed
    case timerReset
    case timerCompleted(sessionType: String, durationSeconds: Int)
    case breakSkipped

    // Paywall / Purchases
    case paywallViewed(source: String)
    case paywallPurchaseStarted(productId: String)
    case paywallPurchaseSucceeded(productId: String)
    case paywallPurchaseFailed(productId: String, reason: String)
    case paywallDismissed
    case purchaseRestored(productId: String)
    case subscriptionRenewed(productId: String)

    // Settings
    case settingChanged(key: String, value: String)

    // Onboarding
    case onboardingStarted
    case onboardingStepCompleted(step: String)
    case onboardingCompleted(focusLengthMinutes: Int, dailyGoalMinutes: Int, notificationsEnabled: Bool)

    // Tags
    case tagPickerOpened(source: String)
    case tagSelected(tagId: String, isDefault: Bool)
    case tagCreated(tagId: String, customCount: Int)
    case tagRenamed(tagId: String)
    case tagDeleted(tagId: String, customCount: Int)
    case tagLimitReached(limit: Int, isPremium: Bool)
    case tagUpgradeTapped
}

extension AnalyticsEvent {
    /// snake_case event name sent to the analytics backend.
    var name: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .authSignedIn: return "auth_signed_in"
        case .authSignedOut: return "auth_signed_out"
        case .timerStarted: return "timer_started"
        case .timerPaused: return "timer_paused"
        case .timerResumed: return "timer_resumed"
        case .timerReset: return "timer_reset"
        case .timerCompleted: return "timer_completed"
        case .breakSkipped: return "break_skipped"
        case .paywallViewed: return "paywall_viewed"
        case .paywallPurchaseStarted: return "paywall_purchase_started"
        case .paywallPurchaseSucceeded: return "paywall_purchase_succeeded"
        case .paywallPurchaseFailed: return "paywall_purchase_failed"
        case .paywallDismissed: return "paywall_dismissed"
        case .purchaseRestored: return "purchase_restored"
        case .subscriptionRenewed: return "subscription_renewed"
        case .settingChanged: return "setting_changed"
        case .onboardingStarted: return "onboarding_started"
        case .onboardingStepCompleted: return "onboarding_step_completed"
        case .onboardingCompleted: return "onboarding_completed"
        case .tagPickerOpened: return "tag_picker_opened"
        case .tagSelected: return "tag_selected"
        case .tagCreated: return "tag_created"
        case .tagRenamed: return "tag_renamed"
        case .tagDeleted: return "tag_deleted"
        case .tagLimitReached: return "tag_limit_reached"
        case .tagUpgradeTapped: return "tag_upgrade_tapped"
        }
    }

    /// Per-event properties forwarded to the backend.
    var properties: [String: Any]? {
        switch self {
        case .appLaunched, .authSignedOut, .timerResumed, .timerReset,
             .breakSkipped, .paywallDismissed, .onboardingStarted,
             .tagUpgradeTapped:
            return nil

        case .authSignedIn(let method):
            return ["method": method]

        case .timerStarted(let presetMinutes, let sessionType, let isStrictMode):
            return [
                "preset_minutes": presetMinutes,
                "session_type": sessionType,
                "is_strict_mode": isStrictMode
            ]

        case .timerPaused(let remainingSeconds):
            return ["remaining_seconds": remainingSeconds]

        case .timerCompleted(let sessionType, let durationSeconds):
            return [
                "session_type": sessionType,
                "duration_seconds": durationSeconds
            ]

        case .paywallViewed(let source):
            return ["source": source]

        case .paywallPurchaseStarted(let productId),
             .paywallPurchaseSucceeded(let productId),
             .purchaseRestored(let productId),
             .subscriptionRenewed(let productId):
            return ["product_id": productId]

        case .paywallPurchaseFailed(let productId, let reason):
            return ["product_id": productId, "reason": reason]

        case .settingChanged(let key, let value):
            return ["key": key, "value": value]

        case .onboardingStepCompleted(let step):
            return ["step": step]

        case .onboardingCompleted(let focusLengthMinutes, let dailyGoalMinutes, let notificationsEnabled):
            return [
                "focus_length_minutes": focusLengthMinutes,
                "daily_goal_minutes": dailyGoalMinutes,
                "notifications_enabled": notificationsEnabled
            ]

        case .tagPickerOpened(let source):
            return ["source": source]

        case .tagSelected(let tagId, let isDefault):
            return ["tag_id": tagId, "is_default": isDefault]

        case .tagCreated(let tagId, let customCount),
             .tagDeleted(let tagId, let customCount):
            return ["tag_id": tagId, "custom_count": customCount]

        case .tagRenamed(let tagId):
            return ["tag_id": tagId]

        case .tagLimitReached(let limit, let isPremium):
            return ["limit": limit, "is_premium": isPremium]
        }
    }
}
