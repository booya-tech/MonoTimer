//
//  CircleStartButton.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/12/25.
//

import SwiftUI

/// Minimal circle start button with 3-second countdown.
/// Tap once to start; tap again during countdown to cancel.
struct CircleStartButton: View {
    let action: () -> Void
    let isHapticsEnabled: Bool

    @State private var countdown: Int = 3
    @State private var isCountingDown = false
    @State private var progress: Double = 1.0
    @State private var countdownTask: Task<Void, Never>?

    private let size: CGFloat = 80

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                Circle()
                    .fill(AppColors.background)
                    .frame(width: size, height: size)

                if isCountingDown {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppColors.primary,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: AppColors.primary.opacity(0.25), radius: 4)
                        .animation(.easeInOut(duration: 1.0), value: progress)
                        .transition(.opacity)
                }

                Circle()
                    .stroke(AppColors.primary, lineWidth: 2)
                    .frame(width: size, height: size)

                if isCountingDown {
                    Text("\(countdown)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primary)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: countdown)
                        .accessibilityLabel("Cancel countdown")
                } else {
                    Text("Focus")
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                        .transition(.opacity)
                        .accessibilityLabel("Start focus")
                }
            }
        }
        .buttonStyle(PressableCircleStyle())
        .onDisappear { countdownTask?.cancel() }
    }

    private func handleTap() {
        if isCountingDown {
            cancelCountdown()
        } else {
            startCountdown()
        }
    }

    private func startCountdown() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isCountingDown = true
        }
        countdown = 3
        progress = 1.0

        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            for tick in stride(from: 2, through: 0, by: -1) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }

                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    countdown = tick
                }
                progress = Double(tick) / 3.0

                if isHapticsEnabled {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if Task.isCancelled { return }

            if isHapticsEnabled {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            action()
            resetState(animated: true)
        }
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil

        if isHapticsEnabled {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        resetState(animated: true)
    }

    private func resetState(animated: Bool) {
        let apply = {
            isCountingDown = false
            countdown = 3
            progress = 1.0
        }
        if animated {
            withAnimation(.easeOut(duration: 0.25), apply)
        } else {
            apply()
        }
    }
}

// MARK: - Pressable Style

private struct PressableCircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview("Circle Start Button") {
    VStack(spacing: 40) {
        Text("Tap to start, tap again to cancel")
            .font(.caption)
            .foregroundColor(.gray)

        CircleStartButton(action: {
            Logger.log("Timer started!")
        }, isHapticsEnabled: true)
    }
    .padding()
}
