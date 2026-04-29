//
//  FocusSpaceWidgetsLiveActivity.swift
//  FocusSpaceWidgets
//
//  Created by Panachai Sulsaksakul on 9/14/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FocusSpaceWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI (when user long presses or gets update)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(context.state.sessionType.color)
                            .frame(width: 16, height: 16)
                        VStack {
                            Text("Focus Session")
                                .font(.caption2)
                                .foregroundColor(.white)
                            
                            Text(context.state.sessionType.displayName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    // `Date()...endTime` would trap once the timer ends and
                    // the system re-renders during the 5s dismissal tail
                    // (lowerBound > upperBound). Gate on `isRunning` to fall
                    // back to a static label, and clamp the upper bound as a
                    // defensive guard against late re-renders.
                    if context.state.isRunning {
                        Text(timerInterval: Date()...max(Date(), context.state.endTime), countsDown: true)
                            .font(.title)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    } else {
                        Text(context.state.timeDisplay)
                            .font(.title)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
            } compactLeading: {
                // Compact leading (left side of notch) - main timer display
                Circle()
                    .fill(context.state.sessionType.color)
                    .frame(width: 16, height: 16)
            } compactTrailing: {
                // Compact trailing (right side of notch) - time display
                if context.state.isRunning {
                    Text(timerInterval: Date()...max(Date(), context.state.endTime), countsDown: true)
                        .font(.caption2)
                        .monospacedDigit()
                        .frame(width: 40)
                } else {
                    Text(context.state.timeDisplay)
                        .font(.caption2)
                        .monospacedDigit()
                        .frame(width: 40)
                }
            } minimal: {
                // Minimal state (when another activity takes priority)
                Circle()
                    .fill(context.state.sessionType.color)
                    .frame(width: 16, height: 16)
            }
        }
    }
}
