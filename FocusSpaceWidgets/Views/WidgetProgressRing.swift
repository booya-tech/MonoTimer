//
//  WidgetProgressRing.swift
//  FocusSpaceWidgets
//
//  Static progress ring for widget display
//

import SwiftUI

/// A circular progress ring for displaying daily goal progress in widgets
struct WidgetProgressRing: View {
    /// Progress value from 0.0 to 1.0
    let progress: Double
    
    /// Size of the ring
    let size: CGFloat
    
    /// Line width of the ring stroke
    var lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.primary.opacity(0.15),
                    lineWidth: lineWidth
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    Color.primary,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

/// A filled circular progress view (alternative style)
struct WidgetProgressCircle: View {
    /// Progress value from 0.0 to 1.0
    let progress: Double
    
    /// Size of the circle
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.primary.opacity(0.1))
            
            // Progress fill using wave-like shape
            WidgetWaveShape(progress: progress)
                .fill(Color.primary.opacity(0.3))
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }
}

/// Static wave shape for widget (no animation)
private struct WidgetWaveShape: Shape {
    let progress: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let fillHeight = rect.height * progress
        let yStart = rect.height - fillHeight
        let waveHeight: CGFloat = min(4, fillHeight * 0.1)
        
        path.move(to: CGPoint(x: 0, y: yStart))
        
        // Draw subtle wave at the top of the fill
        for x in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 3)
            let y = yStart + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Complete the fill area
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        WidgetProgressRing(progress: 0.65, size: 80)
        WidgetProgressRing(progress: 0.3, size: 60, lineWidth: 6)
        WidgetProgressCircle(progress: 0.5, size: 80)
    }
    .padding()
}
