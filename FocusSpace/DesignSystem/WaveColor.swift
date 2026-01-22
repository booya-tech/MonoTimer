//
//  WaveColor.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 1/21/26.
//

import SwiftUI

/// Wave color options for the timer
enum WaveColor: Int, CaseIterable {
    case defaultColor = 0
    case blue = 1
    case teal = 2
    case indigo = 3
    
    var color: Color {
        switch self {
        case .defaultColor: return AppColors.primary
        case .blue: return .blue
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
    
    var name: String {
        switch self {
        case .defaultColor: return "Default"
        case .blue: return "Blue"
        case .teal: return "Teal"
        case .indigo: return "Indigo"
        }
    }
}
