//
//  TimerControlsView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/31/25.
//

import SwiftUI

struct TimerControlsView: View {
    @ObservedObject var timerViewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 16) {
            if timerViewModel.isIdle {
                CircleStartButton {
                    timerViewModel.start()
                }
            } else if timerViewModel.isRunning {
                if !timerViewModel.preferences.isStrictModeEnabled {
                    PrimaryButton(title: "Pause") {
                        timerViewModel.pause()
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.circle.fill")
                            .foregroundColor(AppColors.accent)
                            .font(.title3)
                        Text("Strict Mode")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                if timerViewModel.currentSessionType == .focus {
                    if timerViewModel.preferences.isStrictModeEnabled {
                        PrimaryButton(title: "Stop Session", isDestructive: true) {
                            timerViewModel.stop()
                        }
                    } else {
                        PrimaryButton(title: "Skip to Break", isDestructive: true) {
                            timerViewModel.skipToBreak()
                        }
                    }
                } else if timerViewModel.currentSessionType == .longBreak {
                    PrimaryButton(title: "Stop Break", isDestructive: true) {
                        timerViewModel.stop()
                    }
                }
            } else if timerViewModel.isPaused {
                PrimaryButton(title: "Resume") {
                    timerViewModel.resume()
                }
                
                PrimaryButton(title: "Stop", isDestructive: true) {
                    timerViewModel.stop()
                }
            }
        }
    }
}

#Preview {
    let localRepo = LocalSessionRepository()
    let remoteRepo = RemoteSessionRepository()
    let syncService = SessionSyncService(
        localRepository: localRepo,
        remoteRepository: remoteRepo
    )
    let timerViewModel = TimerViewModel(sessionSync: syncService)
    
    TimerControlsView(timerViewModel: timerViewModel)
}
