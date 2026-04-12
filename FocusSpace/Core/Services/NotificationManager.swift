//
//  NotificationManager.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 9/19/25.
//
//  Local notification management for timer completion
//

import Foundation
import UserNotifications
import UIKit

/// Manages local notifications for timer events
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // Request notification permissions from user
    func requestPermission() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

            await checkAuthorizationStatus()

            if granted {
                Logger.log("✅ Notification permission granted")
            } else {
                Logger.log("❌ Notification permission denied")
            }
        } catch {
            Logger.log("❌ Failed to request notification permission: \(error)")
        }
    }

    private func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = authorizationStatus == .authorized
    }

    // MARK: - Notification Scheduling
    
    /// Schedule notification for timer completion
    func scheduleTimerCompletion(
        for sessionType: SessionType,
        in seconds: TimeInterval,
        presetName: String
    ) async {
        guard isAuthorized else {
            Logger.log("⚠️ Notifications not authorized")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = sessionType.notificationTitle
        content.body = sessionType.notificationBody(presetName: presetName)
        content.sound = .default
        content.badge = 1
        
        // Create trigger for specified time
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )
        
        // Create request with unique identifier
        let identifier = "timer_\(sessionType.rawValue)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            Logger.log("📱 Scheduled notification for \(sessionType.displayName) in \(Int(seconds))s")
        } catch {
            Logger.log("❌ Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Daily Reminders
    func scheduleDailyReminders() async {
        guard isAuthorized else {
            Logger.log("⚠️ Notifications not authorized, skipping daily reminders")
            return
        }

        for reminder in DailyReminder.allCases {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: reminder.rawValue,
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                Logger.log("📅 Scheduled daily reminder: \(reminder.rawValue) at \(reminder.hour):00")
            } catch {
                Logger.log("❌ Failed to schedule daily reminder \(reminder.rawValue): \(error)")
            }
        }

        
        let testContent = UNMutableNotificationContent()
        testContent.title = "Test Daily Reminder"
        testContent.body = "This should appear in ~60 seconds."
        testContent.sound = .default

        //        await scheduleTestNotification()
    }

    private func scheduleTestNotification() async {
        let testContent = UNMutableNotificationContent()
        testContent.title = "Test Daily Reminder 🔥"
        testContent.body = "This should appear in ~60 seconds. 💎 🌊"
        testContent.sound = .default

        let testTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let testRequest = UNNotificationRequest(
            identifier: "daily_test",
            content: testContent,
            trigger: testTrigger
        )
        try? await notificationCenter.add(testRequest)
        Logger.log("🧪 Test notification scheduled for 60s from now")
    }

    /// Cancel all pending timer notifications
    func cancelAllTimerNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let timerIDs = requests
            .filter { $0.identifier.hasPrefix("timer_") }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: timerIDs)
        Logger.log("🗑️ Cancelled \(timerIDs.count) timer notifications")
    }

    /// Cancel specific timer notification
    func cancelTimerNotification(for sessionType: SessionType) {
        let identifiers = ["timer_\(sessionType.rawValue)"]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        Logger.log("🗑️ Cancelled \(sessionType.displayName) notification")
    }

    //MARK: - Debugging Methods
    // Add this method to NotificationManager class
    func debugPendingNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        Logger.log("🔍 Pending Notifications: \(requests.count)")
        for request in requests {
            Logger.log("ID: \(request.identifier)")
            if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                Logger.log("Time Interval: \(trigger.timeInterval)s")
            }
        }
    }

    // Add this method to NotificationManager class
    func debugAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        Logger.log("🔍 Notification Debug:")
        Logger.log("Authorization Status: \(settings.authorizationStatus.rawValue)")
        Logger.log("Alert Setting: \(settings.alertSetting.rawValue)")
        Logger.log("Sound Setting: \(settings.soundSetting.rawValue)")
        Logger.log("Badge Setting: \(settings.badgeSetting.rawValue)")
        Logger.log("isAuthorized: \(isAuthorized)")
    }
}
