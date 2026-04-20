//
//  PresetButton.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/31/25.
//

import SwiftUI

struct PresetButton: View {
    let preset: TimerPreset
    let isSelected: Bool
    let isHapticsEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isHapticsEnabled {
                HapticManager.shared.light()
            }
            action()
        }) {
            Text("\(preset.minutes)m")
                .font(AppTypography.body)
                .foregroundColor(isSelected ? AppColors.background : AppColors.primaryText)
                .frame(width: 60, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? AppColors.primaryText : AppColors.background)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.primaryText, lineWidth: 1)
                        }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PresetButton(preset: TimerPreset.defaults[0], isSelected: false, isHapticsEnabled: true, action: {})
    PresetButton(preset: TimerPreset.defaults[0], isSelected: true, isHapticsEnabled: true, action: {})
}
