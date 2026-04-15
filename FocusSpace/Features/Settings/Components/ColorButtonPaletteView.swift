//
//  ColorButtonPaletteView.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/14/26.
//

import SwiftUI

enum ColorButtonStyle {
    case normal
    case gradient
}

enum ColorButtonStage {
    case enable
    case disable
}

struct ColorButtonPaletteView: View {
    let waveColor: WaveColor
    let style: ColorButtonStyle
    let stage: ColorButtonStage
    let isSelected: Bool

    var body: some View {
        switch (style, stage) {
        case (.normal, .enable):
            normalEnabled
        case (.normal, .disable):
            normalDisabled
        case (.gradient, .enable):
            gradientEnabled
        case (.gradient, .disable):
            gradientDisabled
        }
    }

    private var normalEnabled: some View {
        Circle()
            .fill(waveColor.color)
            .opacity(0.5)
            .frame(width: 44, height: 44)
            .overlay(selectionRing)
    }

    private var normalDisabled: some View {
        ZStack {
            Circle()
                .fill(waveColor.color)
                .opacity(0.5)
                .frame(width: 44, height: 44)
            lockOverlay
        }
    }

    private var gradientEnabled: some View {
        Circle()
            .fill(waveColor.gradient)
            .frame(width: 44, height: 44)
            .shadow(color: waveColor.glowColor.opacity(0.5), radius: 6)
            .overlay(selectionRing)
    }

    private var gradientDisabled: some View {
        ZStack {
            Circle()
                .fill(waveColor.gradient)
                .frame(width: 44, height: 44)
                .shadow(color: waveColor.glowColor.opacity(0.5), radius: 6)
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 44, height: 44)
            Image(systemName: "lock.fill")
                .font(.body)
                .foregroundStyle(AppColors.primary)
        }
    }

    private var selectionRing: some View {
        Circle()
            .stroke(AppColors.primaryText, lineWidth: isSelected ? 1 : 0)
    }

    private var lockOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 44, height: 44)
            Image(systemName: "lock.fill")
                .font(.body)
                .foregroundStyle(AppColors.primary)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ColorButtonPaletteView(waveColor: .defaultColor, style: .normal, stage: .enable, isSelected: true)
        ColorButtonPaletteView(waveColor: .defaultColor, style: .gradient, stage: .enable, isSelected: false)
        ColorButtonPaletteView(waveColor: .defaultColor, style: .gradient, stage: .disable, isSelected: false)
    }
}
