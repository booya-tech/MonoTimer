//
//  CircleTimerView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 1/18/26.
//

import SwiftUI

/// Animated circle that fills based on timer progress with wave animation
struct CircleTimerView: View {
    let progress: Double // 0.0 to 1.0
    let sessionType: SessionType
    let formattedTime: String
    
    @State private var waveOffset: CGFloat = 0
    
    private let size: CGFloat = 220
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Circle outline
                Circle()
                    .stroke(AppColors.primary, lineWidth: 2)
                    .frame(width: size, height: size)
                
                // Wave fill
                CircleWaveView(progress: progress, offset: waveOffset)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .onAppear {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            waveOffset = size
                        }
                    }
                
                // Bubble decorations
                bubbleOverlay
                    .clipShape(Circle())
                    .frame(width: size, height: size)
                
                // Center text
                Text("focus")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(AppColors.primaryRevert)
            }
            
            // Time display
            Text(formattedTime)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.primaryText)
        }
        .padding()
    }
    
    // MARK: - Bubble Overlay
    private var bubbleOverlay: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryRevert.opacity(0.1))
                .frame(width: 15, height: 15)
                .offset(x: -20, y: 30)
            
            Circle()
                .fill(AppColors.primaryRevert.opacity(0.1))
                .frame(width: 15, height: 15)
                .offset(x: 40, y: 50)
            
            Circle()
                .fill(AppColors.primaryRevert.opacity(0.1))
                .frame(width: 25, height: 25)
                .offset(x: -30, y: 70)
            
            Circle()
                .fill(AppColors.primaryRevert.opacity(0.1))
                .frame(width: 20, height: 20)
                .offset(x: 50, y: 60)
            
            Circle()
                .fill(AppColors.primaryRevert.opacity(0.1))
                .frame(width: 10, height: 10)
                .offset(x: -40, y: 40)
        }
    }
}

// MARK: - Preview
#Preview("Circle Timer") {
    VStack(spacing: 40) {
        CircleTimerView(
            progress: 0.7,
            sessionType: .focus,
            formattedTime: "25:00"
        )
        
        CircleTimerView(
            progress: 0.3,
            sessionType: .shortBreak,
            formattedTime: "05:00"
        )
    }
}
