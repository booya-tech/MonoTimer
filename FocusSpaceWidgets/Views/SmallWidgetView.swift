//
//  SmallWidgetView.swift
//  FocusSpaceWidgets
//
//  Small widget layout with progress ring and streak
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress ring with minutes inside
            ZStack {
                WidgetProgressRing(
                    progress: data.dailyGoalProgress,
                    size: 70,
                    lineWidth: 6
                )
                
                VStack(spacing: 0) {
                    Text("\(data.todayMinutes)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("min")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            // Streak indicator
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(data.currentStreak > 0 ? .primary : .secondary)
                
                Text("\(data.currentStreak)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(data.currentStreak > 0 ? .primary : .secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(as: .systemSmall) {
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
