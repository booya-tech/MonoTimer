//
//  OnboardingViewModel.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/27/26.
//
//  Drives the 4-step first-launch onboarding flow.
//

import Foundation
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case focusLength
    case dailyGoal
    case notifications

    var analyticsName: String {
        switch self {
        case .welcome: return "welcome"
        case .focusLength: return "focus_length"
        case .dailyGoal: return "daily_goal"
        case .notifications: return "notifications"
        }
    }
}

/// Owns the onboarding flow state. Step views read selections from here and
/// route navigation through `next()`/`back()`. Persistence to `AppPreferences`
/// happens only in `complete()` so a mid-flow exit leaves no partial state.
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var focusLengthMinutes: Int
    @Published var dailyGoalMinutes: Int

    private let preferences: AppPreferences
    private let notifications: NotificationManager
    private let analytics: AnalyticsService

    init(
        preferences: AppPreferences? = nil,
        notifications: NotificationManager? = nil,
        analytics: AnalyticsService? = nil
    ) {
        // `.shared` getters are `@MainActor`-isolated; resolve them inside the
        // init body (which is `@MainActor` via the class) instead of as default args.
        let prefs = preferences ?? .shared
        let notif = notifications ?? .shared
        let track = analytics ?? AnalyticsBootstrap.shared

        self.preferences = prefs
        self.notifications = notif
        self.analytics = track
        self.focusLengthMinutes = prefs.selectedFocusDuration
        self.dailyGoalMinutes = prefs.dailyFocusGoal

        track.capture(.onboardingStarted)
    }

    var isFirstStep: Bool { currentStep == .welcome }
    var isLastStep: Bool { currentStep == .notifications }

    func selectFocusLength(_ minutes: Int) {
        focusLengthMinutes = minutes
    }

    func selectDailyGoal(_ minutes: Int) {
        dailyGoalMinutes = minutes
    }

    func next() {
        analytics.capture(.onboardingStepCompleted(step: currentStep.analyticsName))
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = next
        }
    }

    func back() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = prev
        }
    }

    /// User tapped the affirmative CTA on the notifications step.
    /// Triggers the iOS permission alert exactly once, then completes onboarding.
    func requestNotificationsAndComplete() async {
        await notifications.requestPermission()
        complete()
    }

    /// User tapped "Not now" on the notifications step.
    /// Skips the iOS prompt entirely (preserves future re-prompt rights) and completes.
    func skipNotificationsAndComplete() {
        complete()
    }

    private func complete() {
        preferences.selectedFocusDuration = focusLengthMinutes
        preferences.dailyFocusGoal = dailyGoalMinutes
        preferences.onboardingVersion = AppConstants.Onboarding.currentVersion
        preferences.hasCompletedOnboarding = true

        analytics.capture(.onboardingStepCompleted(step: OnboardingStep.notifications.analyticsName))
        analytics.capture(.onboardingCompleted(
            focusLengthMinutes: focusLengthMinutes,
            dailyGoalMinutes: dailyGoalMinutes,
            notificationsEnabled: notifications.isAuthorized
        ))
    }
}
