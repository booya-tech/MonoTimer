//
//  FocusSpaceWidgets.swift
//  FocusSpaceWidgets
//
//  Created by Panachai Sulsaksakul on 9/14/25.
//
//  Home screen widget displaying daily focus progress and stats
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct FocusWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), widgetData: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        // TEST: Use static data to verify widget loads without App Group
        let testData = WidgetData(
            todaySessions: 2,
            todayMinutes: 50,
            dailyGoal: 120,
            dailyGoalProgress: 0.42,
            currentStreak: 3,
            lastUpdated: Date()
        )
        let entry = SimpleEntry(date: Date(), widgetData: testData)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        // TEST: Use static data to verify widget loads without App Group
        let testData = WidgetData(
            todaySessions: 2,
            todayMinutes: 50,
            dailyGoal: 120,
            dailyGoalProgress: 0.42,
            currentStreak: 3,
            lastUpdated: Date()
        )
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, widgetData: testData)
        
        // Refresh timeline every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

// MARK: - Entry View

struct FocusSpaceWidgetsEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FocusWidgetProvider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(data: entry.widgetData)
            case .systemMedium:
                MediumWidgetView(data: entry.widgetData)
            case .systemLarge:
                LargeWidgetView(data: entry.widgetData)
            default:
                SmallWidgetView(data: entry.widgetData)
            }
        }
        .padding()
        .widgetURL(URL(string: "monotimer://"))
    }
}

// MARK: - Widget Configuration

struct FocusSpaceWidgets: Widget {
    let kind: String = "FocusSpaceWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            FocusSpaceWidgetsEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Focus Progress")
        .description("Track your daily focus sessions and streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
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

#Preview("Medium", as: .systemMedium) {
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

#Preview("Large", as: .systemLarge) {
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

#Preview("Empty State", as: .systemSmall) {
    FocusSpaceWidgets()
} timeline: {
    SimpleEntry(date: .now, widgetData: .empty)
}
