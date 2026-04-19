//
//  SettingsView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 9/21/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        List {
            Section("Timer Settings") {
                // Custom Focus Durations
                NavigationLink {
                    FocusDurationPickerView(selectedDuration: $preferences.selectedFocusDuration)
                } label: {
                    SettingsRow(
                        icon: "timer",
                        title: "Focus Duration",
                        subtitle: "\(preferences.selectedFocusDuration) min"
                    )
                }
                // Custom Break Durations
                NavigationLink {
                    BreakDurationPickerView(
                        selectedDuration: $preferences.selectedBreakDuration
                    )
                } label: {
                    SettingsRow(
                        icon: "pause.circle",
                        title: "Break Durations",
                        subtitle: "\(preferences.selectedBreakDuration) min"
                    )
                }
                
                // Strict Mode Toggle
                HStack {
                    SettingsRow(
                        icon: "lock.circle",
                        title: "Strict Mode",
                        subtitle: "Disable pause/resume"
                    )
                    Spacer()
                    Toggle("", isOn: $preferences.isStrictModeEnabled)
                        .labelsHidden()
                }
            }
            // MARK: - Goal & Tracking
            Section("Goal & Tracking") {
                // Daily Focus Goal
                NavigationLink {
                    DailyGoalView(goalMinutes: $preferences.dailyFocusGoal)
                } label: {
                    SettingsRow(
                        icon: "target",
                        title: "Daily Focus Goal",
                        subtitle: "\(preferences.dailyFocusGoal) minutes"
                    )
                }
            }
            
            // MARK: - Audio & Haptics
            Section("Audio & Haptics") {
                // Sound Toggle
                HStack {
                    SettingsRow(
                        icon: "speaker.wave.2",
                        title: "Completion Sounds",
                        subtitle: "Play sound when timer ends"
                    )
                    Spacer()
                    Toggle("", isOn: $preferences.isSoundEnabled)
                        .labelsHidden()
                }
                // Haptics Toggle
                HStack {
                    SettingsRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Haptic Feedback",
                        subtitle: "Vibrate on timer events"
                    )
                    Spacer()
                    Toggle("", isOn: $preferences.isHapticsEnabled)
                        .labelsHidden()
                }
            }
            
            // MARK: - Reset
            Section("Reset") {
                Button {
                    preferences.resetToDefaults()
                    HapticManager.shared.light()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.red)
                        Text("Reset to Defaults")
                            .foregroundColor(.red)
                    }
                }
            }
            
            //MARK: - Toggle Premium (Debug Only)
            if AppConstants.isDebugMode {
                Section("Premium") {
                    Button {
                        preferences.togglePremiumUser()
                        HapticManager.shared.light()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Toggle Premium")
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppPreferences.shared)
}
