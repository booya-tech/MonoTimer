//
//  WaveColor.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 1/21/26.
//

import SwiftUI

/// Wave color options for the timer
enum WaveColor: Int, CaseIterable {
    // Free colors (0-3)
    case defaultColor = 0
    case blue = 1
    case teal = 2
    case indigo = 3
    
    // Premium colors (4+)
    case sunset = 4
    case ocean = 5
    case aurora = 6
    case roseGold = 7
    case cloudy = 8
    case navy = 9
    case galaxy = 10
    case mint = 11
    
    // MARK: - Premium Check
    var isPremium: Bool {
        switch self {
            case .sunset, .ocean, .aurora, .roseGold,
                 .cloudy, .navy, .galaxy, .mint: return true
            default: return false
        }
    }
    
    // MARK: - Solid Color (for free colors)
    var color: Color {
        switch self {
        case .defaultColor: return AppColors.primary
        case .blue: return .blue
        case .teal: return .teal
        case .indigo: return .indigo
        // Premium colors return their primary gradient color
        case .sunset: return Color(hex: "#FF6B6B")
        case .ocean: return Color(hex: "#1E3A5F")
        case .aurora: return Color(hex: "#10B981")
        case .roseGold: return Color(hex: "#F472B6")
        case .cloudy: return Color(hex: "#091413")
        case .navy: return Color(hex: "#0F2854")
        case .galaxy: return Color(hex: "#1E1B4B")
        case .mint: return Color(hex: "#0ABAB5")
        }
    }
    
    // MARK: - Gradient (for premium colors)
    var gradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var gradientColors: [Color] {
        switch self {
        // Free colors - single color gradient
        case .defaultColor: return [AppColors.primary]
        case .blue: return [.blue]
        case .teal: return [.teal]
        case .indigo: return [.indigo]
        // Premium gradients
        case .sunset: return [Color(hex: "#FF6B6B"), Color(hex: "#EE5A9B"), Color(hex: "#8B5CF6")]
        case .ocean: return [Color(hex: "#1E3A5F"), Color(hex: "#0D9488"), Color(hex: "#22D3EE")]
        case .aurora: return [Color(hex: "#10B981"), Color(hex: "#06B6D4"), Color(hex: "#A855F7")]
        case .roseGold: return [Color(hex: "#F472B6"), Color(hex: "#FBBF24"), Color(hex: "#F59E0B")]
        case .cloudy: return [Color(hex: "#BDE8F5"), Color(hex: "#BDE8F5"), Color(hex: "#EEEEEE")]
        case .navy: return [Color(hex: "#0F2854"), Color(hex: "#1C4D8D"), Color(hex: "#4988C4")]
        case .galaxy: return [Color(hex: "#4D2B8C"), Color(hex: "#7C3AED"), Color(hex: "#000000")]
        case .mint: return [Color(hex: "#0ABAB5"), Color(hex: "#56DFCF"), Color(hex: "#F6F6F6")]
        }
    }
    
    // MARK: - Glow Color (for shadow effect)
    var glowColor: Color {
        gradientColors.first ?? color
    }
    
    // MARK: - Display Name
    var name: String {
        switch self {
        case .defaultColor: return "Default"
        case .blue: return "Blue"
        case .teal: return "Teal"
        case .indigo: return "Indigo"
        case .sunset: return "Sunset"
        case .ocean: return "Ocean"
        case .aurora: return "Aurora"
        case .roseGold: return "Rose Gold"
        case .cloudy: return "Cloudy"
        case .navy: return "Navy"
        case .galaxy: return "Galaxy"
        case .mint: return "Mint"
        }
    }
    
    // MARK: - Free and Premium Collections
    static var freeColors: [WaveColor] {
        allCases.filter { !$0.isPremium }
    }
    
    static var premiumColors: [WaveColor] {
        allCases.filter { $0.isPremium }
    }
    
    /// First row of premium colors (original 4)
    static var premiumColorsRow1: [WaveColor] {
        [.sunset, .ocean, .aurora, .roseGold]
    }
    
    /// Second row of premium colors (new 4)
    static var premiumColorsRow2: [WaveColor] {
        [.cloudy, .navy, .galaxy, .mint]
    }
}
