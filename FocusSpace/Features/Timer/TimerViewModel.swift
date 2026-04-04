//
//  TimerViewModel.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/30/25.
//
//  Timer state management and core logic
//

import ActivityKit
import Foundation
import SwiftUI
import UIKit
import WidgetKit

/// Timer state for the state machine
enum TimerState {
    case idle  // Timer not started
    case running  // Timer actively counting down
    case paused  // Timer paused
    case completed  // Timer finished
}

enum HapticType {
    case light, medium, success, warning
}

@MainActor
final class TimerViewModel: ObservableObject {
    // Published properties
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var currentState: TimerState = .idle
    @Published var currentSessionType: SessionType = .focus
    @Published var completedSessions: [Session] = []
    @Published private(set) var sessionEndTime: Date?
    // Notification Manager
    @Published var notificationManager = NotificationManager.shared
    @Published var preferences = AppPreferences.shared

    private let sessionSync: SessionSyncService

    // Live Activity
    private let activityManager = ActivityManager.shared

    // Computed properties
    var isRunning: Bool { currentState == .running }
    var isPaused: Bool { currentState == .paused }
    var isIdle: Bool { currentState == .idle }
    var isCompleted: Bool { currentState == .completed }

    // Formatted time display (MM:SS)
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }

    // Progress percentage (0.0 - 1.0)
    var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }

        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    private var timer: Timer?
    private var sessionStartTime: Date?

    // Initialization
    init(sessionSync: SessionSyncService) {
        self.sessionSync = sessionSync

        Task {
            await loadSessions()
        }
    }

    private func loadSessions() async {
        do {
            let sessions = try await sessionSync.getSessions()
            await MainActor.run {
                self.completedSessions = sessions
                // Update widget data after loading sessions
                updateWidgetData()
            }
        } catch {
            Logger.log("Failed to load sessions: \(error)")
            await MainActor.run {
                ErrorHandler.shared.handle(error, customMessage: "Failed to load sessions")
            }
        }
    }

    // Save session via sync service
    private func saveSession(_ session: Session) async {
        do {
            try await sessionSync.saveSession(session)
            await loadSessions()
        } catch {
            Logger.log("Failed to save session: \(error)")
            await MainActor.run {
                ErrorHandler.shared.handle(error, customMessage: "Failed to save session")
            }
        }
    }

    // Sync methods
    func syncNow() async {
        do {
            try await sessionSync.syncNow()
            await loadSessions()
        } catch {
            Logger.log("Sync failed: \(error)")
            await MainActor.run {
                ErrorHandler.shared.handle(error, customMessage: "Sync failed")
            }
        }
    }

    func syncOnForeground() async {
        await sessionSync.syncOnAppForeground()
        await loadSessions()
    }

    // MARK: - Timer Actions
    // Start a new timer session
    func start(sessionType: SessionType = .focus) {
        stop()  // Clear any existing timer
        currentSessionType = sessionType

       let durationMinutes = sessionType == .focus ? preferences.selectedFocusDuration : preferences.selectedBreakDuration
        totalSeconds = durationMinutes * 60
        remainingSeconds = totalSeconds
        sessionEndTime = Date().addingTimeInterval(TimeInterval(totalSeconds))
        sessionStartTime = Date()
        currentState = .running

        startTimer()

        triggerHaptic(.light)

        // Start Live Activity
        Task {
            await activityManager.startNewLiveActivity(
                presetName: "\(durationMinutes)",
                sessionType: sessionType,
                totalSeconds: totalSeconds,
                remainingSeconds: remainingSeconds,
                isRunning: true
            )
        }
        
        // Task {
        //     await notificationManager.debugAuthorizationStatus()
        // }

        Task {
            await notificationManager.scheduleTimerCompletion(
                for: sessionType,
                in: TimeInterval(totalSeconds),
                presetName: "\(durationMinutes)"
            )
        }

        // Task {
        //     await notificationManager.debugPendingNotifications()
        // }
        
        Logger.log("🔍 Timer Debug:")
        Logger.log("Session Type: \(sessionType.displayName)")
        Logger.log("Total Seconds: \(totalSeconds)")
        Logger.log("Preset Name: \(durationMinutes) min")
    }

    // Pause the current timer
    func pause() {
        guard currentState == .running else { return }

        currentState = .paused
        stopTimer()
        triggerHaptic(.light)

        // Update Live Activity to show paused state
        Task {
            await activityManager.updateLiveActivity(
                sessionType: currentSessionType,
                totalSeconds: totalSeconds,
                remainingSeconds: remainingSeconds,
                isRunning: false
            )
        }

        notificationManager.cancelAllTimerNotifications()
    }

    // Resume the paused timer
    func resume() {
        guard currentState == .paused else { return }

        sessionEndTime = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        currentState = .running
        startTimer()

        triggerHaptic(.medium)

        // Update Live Activity to show running state
        Task {
            await activityManager.updateLiveActivity(
                sessionType: currentSessionType,
                totalSeconds: totalSeconds,
                remainingSeconds: remainingSeconds,
                isRunning: true
            )
        }

        Task {
            let durationMinutes = currentSessionType == .focus ? preferences.selectedFocusDuration : preferences.selectedBreakDuration

            await notificationManager.scheduleTimerCompletion(
                for: currentSessionType,
                in: TimeInterval(remainingSeconds),
                presetName: "\(durationMinutes)"
            )
        }
    }

    // Stop and reset the timer
    func stop() {
        currentState = .idle
        stopTimer()
        remainingSeconds = 0
        sessionEndTime = nil
        totalSeconds = 0
        sessionStartTime = nil

        triggerHaptic(.warning)

        // End Live Activity
        Task {
            await activityManager.endLiveActivity()
        }

        notificationManager.cancelAllTimerNotifications()
    }

    // Skip to break (when in focus session)
    func skipToBreak() {
        guard currentSessionType == .focus else { return }

        // Save the incomplete session if desired
        completeCurrentSession()

        // Start short break
        start(sessionType: .longBreak)
    }

    // Skip the current break
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timerTick()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.timerTick()
            }
        }
    }

    private func timerTick() {
        guard let endTime = sessionEndTime else { return }

        let remaining = max(0, Int(endTime.timeIntervalSince(Date())))
        remainingSeconds = remaining

        guard remaining > 0 else {
            timerCompleted()
            return
        }
        
        // Update Live Activity progress every 5 seconds (not every second to avoid throttling)
        if remaining % 5 == 0 {
            Task {
                await activityManager.updateLiveActivity(
                    sessionType: currentSessionType,
                    totalSeconds: totalSeconds,
                    remainingSeconds: remaining,
                    isRunning: true
                )
            }
        }
    }

    private func timerCompleted() {
        currentState = .completed
        stopTimer()

        // Save completed session
        completeCurrentSession()
        triggerHaptic(.success)

        // Create final state for Live Activity
        let finalState = TimerActivityAttributes.ContentState(
            sessionType: currentSessionType,
            totalSeconds: totalSeconds,
            isRunning: false,
            endTime: Date()
        )

        // End Live Activity with completion state
        Task {
            await activityManager.endLiveActivity(with: finalState)
        }

        // Auto-transition to break or notify completion
        autoTransition()
    }

    private func completeCurrentSession() {
        guard let startTime = sessionStartTime else { return }

        let session = Session(
            type: currentSessionType,
            startAt: startTime,
            endAt: Date(),
            tag: nil
        )

        Task {
            await saveSession(session)
            triggerHaptic(.success)
        }
    }

    private func autoTransition() {
        // Auto-start break after focus session
        if currentSessionType == .focus {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.start(sessionType: .longBreak)
            }
        }
        // After break, return to idle state
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.stop()
            }
        }
    }

    private func triggerHaptic(_ type: HapticType) {
        guard preferences.isHapticsEnabled else { return }
        switch type {
        case .light: HapticManager.shared.light()
        case .medium: HapticManager.shared.medium()
        case .success: HapticManager.shared.success()
        case .warning: HapticManager.shared.warning()
        }
    }
    
    // MARK: - Widget Data
    
    /// Updates widget data with current sessions and daily goal
    private func updateWidgetData() {
        WidgetDataProvider.shared.updateWidgetData(
            sessions: completedSessions,
            dailyGoal: preferences.dailyFocusGoal
        )
    }
}
