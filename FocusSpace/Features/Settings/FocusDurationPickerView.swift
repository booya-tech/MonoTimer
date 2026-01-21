//
//  FocusDurationPickerView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/8/25.
//

import SwiftUI

struct FocusDurationPickerView: View {
    @Binding var selectedDuration: Int
    
    let availableDurations = [1, 30, 35, 40, 45, 50, 60, 90, 120]
    
    var body: some View {
        List {
            Section {
                ForEach(availableDurations, id: \.self) { duration in
                    HStack {
                        Text("\(duration) min")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.primaryText)
                        
                        Spacer()
                        
                        if selectedDuration == duration {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDuration = duration
                        HapticManager.shared.light()
                    }
                }
            } header: {
                Text("Select Focus Duration")
            } footer: {
                Text("Choose how long your focus sessions will last.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .navigationTitle("Focus Duration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FocusDurationPickerView(selectedDuration: .constant(25))
    }
}
