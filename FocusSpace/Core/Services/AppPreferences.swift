//
//  AppPreferences.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 9/21/25.
//
//  User preferences and settings management
//

import Foundation
import SwiftUI

@MainActor
final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    private let defaults = UserDefaults.standard

    // MARK: - Timer Settings
    // Custom focus durations (in minutes)
    // Custom focus duration (in minutes)
    @Published var selectedFocusDuration: Int {
        didSet { defaults.set(selectedFocusDuration, forKey: "selectedFocusDuration") }
    }
    // Custom break durations (in minutes)
    @Published var selectedBreakDuration: Int {
        didSet { defaults.set(selectedBreakDuration, forKey: "selectedBreakDuration") }
    }
    // Strict mode (disable pause/resume)
    @Published var isStrictModeEnabled: Bool {
        didSet { defaults.set(isStrictModeEnabled, forKey: "isStrictModeEnabled") }
    }

    // MARK: - Goal & Tracking
    @Published var dailyFocusGoal: Int {
        didSet { defaults.set(dailyFocusGoal, forKey: "dailyFocusGoal")}
    }

    // MARK: - Appearance
    @Published var waveColorIndex: Int {
        didSet { defaults.set(waveColorIndex, forKey: "waveColorIndex") }
    }
    
    // MARK: - Audio & Haptics
    // Enable completion sounds
    @Published var isSoundEnabled: Bool {
        didSet { defaults.set(isSoundEnabled, forKey: "isSoundEnabled") }
    }
    // Enable haptic feedback
    @Published var isHapticsEnabled: Bool {
        didSet { defaults.set(isHapticsEnabled, forKey: "isHapticsEnabled") }
    }

    // MARK: - Initialization
    private init() {
        self.selectedFocusDuration = defaults.object(forKey: "selectedFocusDuration") as? Int ?? 25
        self.selectedBreakDuration = defaults.object(forKey: "selectedBreakDuration") as? Int ?? 5
        self.isStrictModeEnabled = defaults.bool(forKey: "isStrictModeEnabled")
        self.dailyFocusGoal = defaults.object(forKey: "dailyFocusGoal") as? Int ?? 120
        self.waveColorIndex = defaults.object(forKey: "waveColorIndex") as? Int ?? 0
        self.isSoundEnabled = defaults.object(forKey: "isSoundEnabled") as? Bool ?? true
        self.isHapticsEnabled = defaults.object(forKey: "isHapticsEnabled") as? Bool ?? true
    }

    // Reset all preferences to defaults
    func resetToDefaults() {
        selectedFocusDuration = 25
        selectedBreakDuration = 5
        isStrictModeEnabled = false
        dailyFocusGoal = 120
        waveColorIndex = 0
        isSoundEnabled = true
        isHapticsEnabled = true
    }
}


