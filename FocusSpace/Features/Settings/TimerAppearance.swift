//
//  TimerAppearance.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 1/19/26.
//

import SwiftUI

struct TimerAppearance: View {
    @EnvironmentObject private var preferences: AppPreferences
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("WAVE COLOR")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primaryText)
            
            ZStack {
                Circle()
                    .stroke(AppColors.primary, lineWidth: 2)
                    .frame(
                        width:
                            AppConstants.UI.circleFrameSize,
                        height: AppConstants.UI.circleFrameSize
                    )
                
                WavePreview(waveColor: selectedColor, offset: waveOffset)
                    .frame(
                        width: AppConstants.UI.circleSize,
                        height: AppConstants.UI.circleSize
                    )
                    .clipShape(Circle())
                    .onAppear {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            waveOffset = 180
                        }
                    }
            }
            
            HStack(spacing: 8) {
                Text(selectedColor.name)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.secondaryText)
                
                if selectedColor.isPremium {
                    Text("PRO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryRevert)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.primary)
                        .cornerRadius(4)
                }
            }
            
            Text("Swipe to change")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText.opacity(0.5))
        }
    }
    
    // MARK: - Color Buttons
    private var colorButtons: some View {
        VStack(spacing: 16) {
            if preferences.isPremiumUser {
                // Free colors
                HStack(spacing: 16) {
                    ForEach(WaveColor.freeColors, id: \.rawValue) { waveColor in
                        colorButtonPremium(for: waveColor)
                    }
                }
                
                // Premium colors — row 1
                HStack(spacing: 16) {
                    ForEach(WaveColor.premiumColorsRow1, id: \.rawValue) { waveColor in
                        colorButtonPremium(for: waveColor)
                    }
                }
                
                // Premium colors — row 2
                HStack(spacing: 16) {
                    ForEach(WaveColor.premiumColorsRow2, id: \.rawValue) { waveColor in
                        colorButtonPremium(for: waveColor)
                    }
                }
            } else {
                // Free colors
                HStack(spacing: 16) {
                    ForEach(WaveColor.freeColors, id: \.rawValue) { waveColor in
                        colorButtonNotPremium(for: waveColor)
                    }
                }
                
                // Premium colors — row 1
                HStack(spacing: 16) {
                    ForEach(WaveColor.premiumColorsRow1, id: \.rawValue) { waveColor in
                        colorButtonNotPremium(for: waveColor)
                    }
                }
                
                // Premium colors — row 2
                HStack(spacing: 16) {
                    ForEach(WaveColor.premiumColorsRow2, id: \.rawValue) { waveColor in
                        colorButtonNotPremium(for: waveColor)
                    }
                }
            }
        }
    }
    
    private func colorButtonNotPremium(for waveColor: WaveColor) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                preferences.waveColorIndex = waveColor.rawValue
            }
            HapticManager.shared.light()
        } label: {
            ZStack {
                if waveColor.isPremium {
                    Group {
                        // Premium: gradient fill + glow
                        Circle()
                            .fill(waveColor.gradient)
                            .frame(width: 44, height: 44)
                            .shadow(color: waveColor.glowColor.opacity(0.5), radius: 6)
                        
                        
                        ZStack(alignment: .center) {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "lock.fill")
                                .font(.body)
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                } else {
                    // Free: solid color
                    Circle()
                        .fill(waveColor.color)
                        .opacity(0.5)
                        .frame(width: 44, height: 44)
                }
            }
            .overlay(
                Circle()
                    .stroke(AppColors.primaryText, lineWidth: selectedColor == waveColor ? 3 : 0)
            )
        }
        .disabled(waveColor.isPremium)
    }
    
    private func colorButtonPremium(for waveColor: WaveColor) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                preferences.waveColorIndex = waveColor.rawValue
            }
            HapticManager.shared.light()
        } label: {
            ZStack {
                if waveColor.isPremium {
                    // Premium: gradient fill + glow
                    Circle()
                        .fill(waveColor.gradient)
                        .frame(width: 44, height: 44)
                        .shadow(color: waveColor.glowColor.opacity(0.5), radius: 6)
                } else {
                    // Free: solid color
                    Circle()
                        .fill(waveColor.color)
                        .opacity(0.5)
                        .frame(width: 44, height: 44)
                }
            }
            .overlay(
                Circle()
                    .stroke(AppColors.primaryText, lineWidth: selectedColor == waveColor ? 3 : 0)
            )
        }
    }
    
    // MARK: - Swipe Gesture
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                let colors = preferences.isPremiumUser ? WaveColor.allCases : WaveColor.freeColors
                guard let currentIndex = colors.firstIndex(where: { $0.rawValue == preferences.waveColorIndex }) else { return }
                var newIndex: Int
                
                if value.translation.width < 0 {
                    // Swipe left - next color
                    newIndex = (currentIndex + 1) % colors.count
                } else {
                    // Swipe right - previous color
                    newIndex = (currentIndex - 1 + colors.count) % colors.count
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    preferences.waveColorIndex = colors[newIndex].rawValue
                }
                HapticManager.shared.light()
            }
    }
}

// MARK: - Wave Preview
private struct WavePreview: View {
    let waveColor: WaveColor
    let offset: CGFloat
    
    private var fillStyle: AnyShapeStyle {
        waveColor.isPremium
            ? AnyShapeStyle(waveColor.gradient)
            : AnyShapeStyle(waveColor.color.opacity(0.5))
    }
    
    var body: some View {
        GeometryReader { geometry in
            WavePreviewShape(offset: offset)
                .fill(fillStyle)
                .shadow(
                    color: waveColor.isPremium ? waveColor.glowColor.opacity(0.5) : .clear,
                    radius: waveColor.isPremium ? 12 : 0
                )
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

#Preview("Free User") {
    let prefs = AppPreferences.shared
    prefs.isPremiumUser = false
    prefs.waveColorIndex = 0
    return NavigationStack {
        TimerAppearance()
            .environmentObject(prefs)
    }
}

#Preview("Premium User") {
    let prefs = AppPreferences.shared
    prefs.isPremiumUser = true
    return NavigationStack {
        TimerAppearance()
            .environmentObject(prefs)
    }
}
