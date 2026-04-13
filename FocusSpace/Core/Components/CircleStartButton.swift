//
//  CircleStartButton.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/12/25.
//

import SwiftUI

/// Minimal circle start button with 3-second countdown animation
struct CircleStartButton: View {
    let action: () -> Void
    let isHapticsEnabled: Bool
    
    @State private var countdown: Int = 3
    @State private var isCountingDown = false
    @State private var progress: Double = 1.0
    
    var body: some View {
        Button(action: startCountdown) {
            ZStack {
                // Background circle
                Circle()
                    .fill(AppColors.background)
                    .frame(width: 80, height: 80)
                
                // Progress ring
                if isCountingDown {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppColors.primary,
                            style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round
                            )
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: progress)
                }
                
                // Border circle
                Circle()
                    .stroke(AppColors.primary, lineWidth: 2)
                    .frame(width: 80, height: 80)
                
                // Icon or countdown number
                if isCountingDown {
                    Text("\(countdown)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primary)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Focus")
                        .fontWeight(.bold)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCountingDown)
    }
    
    private func startCountdown() {
        guard !isCountingDown else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isCountingDown = true
        }
        
        countdown = 3
        progress = 1.0
        
        // Countdown timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
                progress = Double(countdown) / 3.0
                
                // Haptic feedback
                if isHapticsEnabled {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            } else {
                progress = 0.0
                timer.invalidate()
                
                // Start action
                // DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {

                // }
                action()

                // Reset state
                withAnimation {
                    isCountingDown = false
                    countdown = 3
                    progress = 1.0
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Circle Start Button") {
    VStack(spacing: 40) {
        Text("Tap to start countdown")
            .font(.caption)
            .foregroundColor(.gray)
        
        CircleStartButton(action: {
            Logger.log("Timer started!")
        }, isHapticsEnabled: true)
    }
    .padding()
}
