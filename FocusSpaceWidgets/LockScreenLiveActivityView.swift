//
//  LockScreenLiveActivityView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 9/14/25.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header with session type and time
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(context.state.sessionType.color)
                        .frame(width: 10, height: 10)

                    Text(context.state.sessionType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                if context.state.isRunning {
                    // Clamp the upper bound: ClosedRange traps when
                    // `Date() > endTime`, which can happen if the system
                    // re-renders just after the timer hits zero.
                    Text(timerInterval: Date()...max(Date(), context.state.endTime), countsDown: true)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                } else {
                    Text(context.state.timeDisplay)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
            }

            // Progress section
            VStack(spacing: 4) {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(
                        LinearProgressViewStyle(tint: context.state.sessionType.color))

                HStack {
                    Text(context.attributes.presetName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: context.state.isRunning ? "play.fill" : "pause.fill")
                            .font(.caption2)
                        Text(context.state.isRunning ? "Running" : "Paused")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview("Lock Screen") {
    VStack(spacing: 12) {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(.green).frame(width: 10, height: 10)
                Text("Focus").font(.subheadline).fontWeight(.medium)
            }
            Spacer()
            Text("15:00").font(.title2).fontWeight(.semibold).monospacedDigit()
        }
        VStack(spacing: 4) {
            ProgressView(value: 0.4).progressViewStyle(LinearProgressViewStyle(tint: .green))
            HStack {
                Text("25 min").font(.caption).foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "play.fill").font(.caption2)
                    Text("Running").font(.caption)
                }.foregroundColor(.secondary)
            }
        }
    }
    .padding(16)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .previewLayout(.sizeThatFits)
    .padding()
}
