//
//  LargeWidgetView.swift
//  FocusSpaceWidgets
//
//  Large widget layout with full stats display
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with app name
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("MonoTimer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("\(data.currentStreak)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(data.currentStreak > 0 ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.1))
                .clipShape(Capsule())
            }
            
            // Main progress section
            HStack(spacing: 20) {
                // Large progress ring
                ZStack {
                    WidgetProgressRing(
                        progress: data.dailyGoalProgress,
                        size: 100,
                        lineWidth: 9
                    )
                    
                    VStack(spacing: 2) {
                        Text("\(data.todayMinutes)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("of \(data.dailyGoal)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Text("minutes")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats column
                VStack(alignment: .leading, spacing: 16) {
                    LargeStatItem(
                        icon: "checkmark.circle.fill",
                        value: "\(data.todaySessions)",
                        label: "Sessions Today"
                    )
                    
                    LargeStatItem(
                        icon: "chart.bar.fill",
                        value: "\(Int(data.dailyGoalProgress * 100))%",
                        label: "Goal Progress"
                    )
                    
                    LargeStatItem(
                        icon: "flame.fill",
                        value: "\(data.currentStreak)",
                        label: "Day Streak"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            // Bottom motivational text
            Text(motivationalText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var motivationalText: String {
        let progress = data.dailyGoalProgress
        let remaining = data.dailyGoal - data.todayMinutes
        
        if progress >= 1.0 {
            return "Excellent! You've reached your daily goal."
        } else if progress >= 0.75 {
            return "Almost there! \(remaining) minutes to go."
        } else if progress >= 0.5 {
            return "Halfway! Keep up the great work."
        } else if data.todayMinutes > 0 {
            return "Good start! \(remaining) minutes remaining."
        } else {
            return "Tap to start your first focus session."
        }
    }
}

/// Large stat item for the large widget
struct LargeStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview(as: .systemLarge) {
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
