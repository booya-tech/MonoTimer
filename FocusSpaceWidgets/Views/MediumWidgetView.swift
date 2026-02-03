//
//  MediumWidgetView.swift
//  FocusSpaceWidgets
//
//  Medium widget layout with progress ring and stats
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Progress ring with daily info
            VStack(spacing: 4) {
                ZStack {
                    WidgetProgressRing(
                        progress: data.dailyGoalProgress,
                        size: 80,
                        lineWidth: 7
                    )
                    
                    VStack(spacing: 0) {
                        Text("\(data.todayMinutes)")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("min")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("of \(data.dailyGoal) min")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            // Right: Stats stack
            VStack(alignment: .leading, spacing: 12) {
                // Sessions today
                StatRow(
                    icon: "checkmark.circle.fill",
                    value: "\(data.todaySessions)",
                    label: "sessions"
                )
                
                // Current streak
                StatRow(
                    icon: "flame.fill",
                    value: "\(data.currentStreak)",
                    label: "day streak"
                )
                
                // Goal progress text
                Text(progressText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var progressText: String {
        let percentage = Int(data.dailyGoalProgress * 100)
        if percentage >= 100 {
            return "Goal reached!"
        } else if percentage > 0 {
            return "\(percentage)% of daily goal"
        } else {
            return "Start your first session"
        }
    }
}

/// Reusable stat row for medium/large widgets
struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(width: 18)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}

#Preview(as: .systemMedium) {
    FocusSpaceWidgets()
} timeline: {
    SimpleEntry(
        date: .now,
        widgetData: WidgetData(
            todaySessions: 3,
            todayMinutes: 75,
            dailyGoal: 120,
            dailyGoalProgress: 0.625,
            currentStreak: 5,
            lastUpdated: Date()
        )
    )
}
