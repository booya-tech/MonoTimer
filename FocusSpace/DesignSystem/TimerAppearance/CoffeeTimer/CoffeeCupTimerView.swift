//
//  CoffeeCupTimerView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/6/25.
//  Animated coffee cup timer display
//

import SwiftUI

/// Animated coffee cup that fills based on timer progress
struct CoffeeCupTimerView: View {
    let progress: Double // 0.0 to 1.0
    let sessionType: SessionType
    let formattedTime: String
    let cupStyle: CupStyle
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Cup outline and fill
                ZStack(alignment: .bottom) {
                    // Filling liquid with wave animation
                    if cupStyle == .glass {
                        // Cup
                        ZStack(alignment: .bottom) {
                            CoffeeWaveView(progress: progress, cupStyle: cupStyle)
                                .frame(width: 200, height: 240)
                        }
                        .mask(
                            cupShape
                                .frame(width: 200, height: 240)
                        )
                        
                        // Cup Handle
                        GlassCupHandleShape()
                            .stroke(AppColors.primary, lineWidth: 2)
                            .frame(width: 200, height: 240)
                    } else {
                        // Standard fill for minimal style
                        cupShape
                            .fill(AppColors.primary)
                            .frame(width: 200, height: 240)
                            .mask(
                                Rectangle()
                                    .frame(height: 240 * progress)
                                    .frame(maxHeight: .infinity, alignment: .bottom)
                            )
                            .animation(.easeInOut(duration: 1.0), value: progress)
                    }

                    // Cup outline
                    cupShape
                        .stroke(AppColors.primary, lineWidth: 2)
                        .frame(width: 200, height: 240)
                }
                .frame(width: 200, height: 280)
                .frame(maxWidth: .infinity)

                // Code icon in center of cup
                if cupStyle == .glass {
                    Text("focus")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(AppColors.primaryRevert)
                }
            }

            // Time Display
            Text(formattedTime)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.primaryText)
        }
        .padding()
    }

    // MARK: - Computed Properties
    private var cupShape: some Shape {
        switch cupStyle {
        case .glass:
            return AnyShape(GlassCupShape())
        case .mug:
            return AnyShape(MugCupShape())
        case .minimal:
            return AnyShape(MinimalCupShape())
        }
    }
    
     private var fillColor: Color {
         switch sessionType {
         case .focus:
             return AppColors.primary
         case .shortBreak, .longBreak:
             return AppColors.primary
         }
     }
}

// MARK: - Preview
#Preview("All Styles") {
    ScrollView(showsIndicators: false) {
        VStack(spacing: 40) {
            // Coder Glass Style
            VStack {
                Text("Mug Style (with waves)")
                    .font(.caption)
                    .foregroundColor(.gray)
                CoffeeCupTimerView(
                    progress: 0.8,
                    sessionType: .focus,
                    formattedTime: "25:00",
                    cupStyle: .glass
                )
            }
            
            // Mug Style
            VStack {
                Text("Mug Style (60%)")
                    .font(.caption)
                    .foregroundColor(.gray)
                CoffeeCupTimerView(
                    progress: 0.6,
                    sessionType: .longBreak,
                    formattedTime: "05:00",
                    cupStyle: .mug
                )
            }
            
            // Minimal style
            VStack {
                Text("Minimal Style")
                    .font(.caption)
                    .foregroundColor(.gray)
                CoffeeCupTimerView(
                    progress: 0.3,
                    sessionType: .shortBreak,
                    formattedTime: "15:00",
                    cupStyle: .minimal
                )
            }
        }
        .padding()
    }
}
