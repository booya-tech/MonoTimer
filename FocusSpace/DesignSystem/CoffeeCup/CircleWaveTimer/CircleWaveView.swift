//
//  CircleWaveView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 1/19/26.
//

import SwiftUI

// MARK: - Circle Wave View
struct CircleWaveView: View {
    let progress: Double
    let offset: CGFloat
    
    private var waveColor: Color {
        let index = AppPreferences.shared.waveColorIndex
        return WaveColor(rawValue: index)?.color ?? AppColors.primary
    }
    
    var body: some View {
        GeometryReader { geometry in
            CircleWaveShape(offset: offset, progress: progress)
                .fill(waveColor)
        }
    }
}

// MARK: - Circle Wave Shape
private struct CircleWaveShape: Shape {
    var offset: CGFloat
    let progress: Double
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight: CGFloat = 6
        let fillHeight = rect.height * progress
        let yStart = rect.height - fillHeight
        
        // Phase cycles 0 to 2π for seamless loop
        let phase = (offset / rect.width) * .pi * 2
        
        path.move(to: CGPoint(x: 0, y: yStart))
        
        // Draw wave at the top of the fill
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            // Wave shape (3 half-cycles) + animated phase
            let sine = sin(relativeX * .pi * 3 + phase)
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
    CircleWaveView(
        progress: 0.5,
        offset: 0.5
    )
}
