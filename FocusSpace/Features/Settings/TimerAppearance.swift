//
//  TimerAppearance.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 1/19/26.
//

import SwiftUI

/// Wave color options for the timer
enum WaveColor: Int, CaseIterable {
    case defaultColor = 0
    case blue = 1
    case green = 2
    case purple = 3
    
    var color: Color {
        switch self {
        case .defaultColor: return AppColors.primary
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        }
    }
    
    var name: String {
        switch self {
        case .defaultColor: return "Default"
        case .blue: return "Blue"
        case .green: return "Green"
        case .purple: return "Purple"
        }
    }
}

struct TimerAppearance: View {
    @ObservedObject private var preferences = AppPreferences.shared
    @State private var waveOffset: CGFloat = 0
    
    private var selectedColor: WaveColor {
        WaveColor(rawValue: preferences.waveColorIndex) ?? .defaultColor
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Preview
            previewSection
            
            // Color selector buttons
            colorButtons
            
            Spacer()
        }
        .padding()
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .gesture(swipeGesture)
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Wave Color")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primaryText)
            
            ZStack {
                Circle()
                    .stroke(selectedColor.color, lineWidth: 2)
                    .frame(width: 180, height: 180)
                
                WavePreview(color: selectedColor.color, offset: waveOffset)
                    .frame(width: 180, height: 180)
                    .clipShape(Circle())
                    .onAppear {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            waveOffset = 180
                        }
                    }
            }
            
            Text(selectedColor.name)
                .font(AppTypography.body)
                .foregroundColor(AppColors.secondaryText)
            
            Text("Swipe left or right to change")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText.opacity(0.6))
        }
    }
    
    // MARK: - Color Buttons
    private var colorButtons: some View {
        HStack(spacing: 20) {
            ForEach(WaveColor.allCases, id: \.rawValue) { waveColor in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        preferences.waveColorIndex = waveColor.rawValue
                    }
                    HapticManager.shared.light()
                } label: {
                    Circle()
                        .fill(waveColor.color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(AppColors.primaryText, lineWidth: selectedColor == waveColor ? 3 : 0)
                        )
                }
            }
        }
    }
    
    // MARK: - Swipe Gesture
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let colors = WaveColor.allCases
                var newIndex = preferences.waveColorIndex
                
                if value.translation.width < 0 {
                    // Swipe left - next color
                    newIndex = (newIndex + 1) % colors.count
                } else {
                    // Swipe right - previous color
                    newIndex = (newIndex - 1 + colors.count) % colors.count
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    preferences.waveColorIndex = newIndex
                }
                HapticManager.shared.light()
            }
    }
}

// MARK: - Wave Preview
private struct WavePreview: View {
    let color: Color
    let offset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            WavePreviewShape(offset: offset)
                .fill(color)
        }
    }
}

private struct WavePreviewShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let progress = 0.5
        let waveHeight: CGFloat = 5
        let fillHeight = rect.height * progress
        let yStart = rect.height - fillHeight
        let phase = (offset / rect.width) * .pi * 2
        
        path.move(to: CGPoint(x: 0, y: yStart))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 3 + phase)
            let y = yStart + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    NavigationStack {
        TimerAppearance()
    }
}
