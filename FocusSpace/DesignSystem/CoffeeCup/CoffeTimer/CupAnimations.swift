//
//  CupAnimations.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/7/25.
//

import SwiftUI

// MARK: - Foam Layer
struct FoamLayer: View {
    let cupStyle: CupStyle
    @State private var bubbleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Main foam ellipse
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color(white: 0.95).opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: foamWidth, height: 18)
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            
            // Foam bubbles
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: CGFloat.random(in: 4...8))
                        .offset(y: bubbleOffset)
                }
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    bubbleOffset = CGFloat.random(in: -2...2)
                }
            }
        }
    }
    
    private var foamWidth: CGFloat {
        switch cupStyle {
        case .glass: return 175
        case .mug: return 135
        case .minimal: return 115
        }
    }
}

// MARK: - Coffee Wave Animation
struct CoffeeWaveView: View {
    let progress: Double
    let cupStyle: CupStyle
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            WaveShape(offset: waveOffset, progress: progress)
                .fill(AppColors.primary)
                .frame(height: geometry.size.height * progress)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .onAppear {
                    withAnimation(
                        .linear(duration: 3.0)
                        .repeatForever(autoreverses: false)
                    ) {
                        waveOffset = geometry.size.width
                    }
                }
        }
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var offset: CGFloat
    let progress: Double
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight: CGFloat = 8
        let yOffset = rect.height * (1 - progress)
        
        path.move(to: CGPoint(x: 0, y: yOffset))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin((relativeX + offset / rect.width) * .pi * 4)
            let y = yOffset + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}
