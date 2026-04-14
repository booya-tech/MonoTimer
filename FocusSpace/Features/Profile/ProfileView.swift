//
//  ProfileView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/19/25.
//
//  Professional profile screen with stats and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var timerViewModel: TimerViewModel
    @StateObject private var habitStreaksVM = HabitStreaksBoardViewModel()
    @State private var showingSignOutAlert = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // User Info Section
                UserInfoSection(
                    email: authService.currentUser?.email ?? AppString.unknown,
                    memberSince: memberSinceDate
                )

                // Habit Streaks Board
                HabitStreaksBoardView(vm: habitStreaksVM)
                    .onAppear {
                        habitStreaksVM.updateSessions(timerViewModel.completedSessions)
                    }
                    .onChange(of: timerViewModel.completedSessions) { _, sessions in
                        habitStreaksVM.updateSessions(sessions)
                    }
                
                // Quick Stats Section
                quickStatsSection
                
                // App Info Section
                appInfoSection

                // Delete Account Section
                deleteAccountSection
                
                // Sign Out Button
                signOutSection
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(AppString.profileViewTitle)
        .navigationBarTitleDisplayMode(.large)
        .alert(AppString.signOut, isPresented: $showingSignOutAlert) {
            Button(AppString.cancel, role: .cancel) { }
            Button(AppString.signOut, role: .destructive) {
                Task {
                    try? await authService.signOut()
                }
            }
        } message: {
            Text(AppString.profileViewSignOutTitle)
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppString.profileViewStatsTitle)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primaryText)
            
            VStack(spacing: 12) {
                StatRow(
                    icon: AppIcon.checkmarkCircleFill,
                    title: AppString.profileViewStateRowSessions,
                    value: "\(totalSessions)"
                )
                
                StatRow(
                    icon: AppIcon.clockFill,
                    title: AppString.profileViewStateRowFocusTime,
                    value: "\(totalMinutes) min"
                )
                
                StatRow(
                    icon: AppIcon.flameFill,
                    title: AppString.profileViewStateRowCurrentStreak,
                    value: "\(currentStreak) days"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.secondaryBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.secondaryText.opacity(0.2), lineWidth: 1)
                    }
            )
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppString.about)
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primaryText)
            
            VStack(spacing: 0) {
                InfoRow(
                    title: AppString.version,
                    value: appVersion,
                    icon: ""
                )
                
                //                Divider()
                //                    .background(AppColors.secondaryText.opacity(0.2))
                
                //                InfoRow(title: "Build", value: buildNumber)
                
                /// Description
                /// might use in the future
                //                Divider()
                //                    .background(AppColors.secondaryText.opacity(0.2))
                
                //                Button(action: openGitHub) {
                //                    HStack {
                //                        Text("GitHub")
                //                            .font(AppTypography.body)
                //                            .foregroundColor(AppColors.primaryText)
                //                        Spacer()
                //                        Image(systemName: "arrow.up.right")
                //                            .font(.caption)
                //                            .foregroundColor(AppColors.secondaryText)
                //                    }
                //                    .padding()
                //                }
                //
                //                Divider()
                //                    .background(AppColors.secondaryText.opacity(0.2))
                //
                //                Button(action: openPrivacyPolicy) {
                //                    HStack {
                //                        Text("Privacy Policy")
                //                            .font(AppTypography.body)
                //                            .foregroundColor(AppColors.primaryText)
                //                        Spacer()
                //                        Image(systemName: "arrow.up.right")
                //                            .font(.caption)
                //                            .foregroundColor(AppColors.secondaryText)
                //                    }
                //                    .padding()
                //                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.secondaryBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.secondaryText.opacity(0.2), lineWidth: 1)
                    }
            )
        }
    }

    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primaryText)
            
            NavigationLink {
                DeleteAccountView(authService: authService)
                    .environmentObject(authService)
            } label: {
                InfoRow(title: AppString.profileViewDeleteAccount, value: "", icon: AppIcon.chevronRight)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.secondaryBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.secondaryText.opacity(0.2), lineWidth: 1)
                            }
                    )
            }
        }
    }
    
    // MARK: - Sign Out Section
    private var signOutSection: some View {
        Button(action: { showingSignOutAlert = true }) {
            HStack {
                Text(AppString.signOut)
            }
            .font(AppTypography.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red)
            )
        }
    }
    
    // MARK: - Computed Properties
    private var memberSinceDate: String {
        if let user = authService.currentUser {
            return user.createdAt.mediumFormat
        }
        return AppString.unknown
    }
    
    private var totalSessions: Int {
        StatsCalculator.totalFocusSessions(from: timerViewModel.completedSessions)
    }
    
    private var totalMinutes: Int {
        StatsCalculator.totalFocusMinutes(from: timerViewModel.completedSessions)
    }
    
    private var currentStreak: Int {
        StatsCalculator.calculateStreak(from: timerViewModel.completedSessions)
    }
    
    private var appVersion: String {
        AppInfo.version
    }
    
    private var buildNumber: String {
        AppInfo.build
    }
    
    // MARK: - Helper Methods
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let sessions = timerViewModel.completedSessions
            .filter { $0.type == .focus }
            .sorted { $0.startAt > $1.startAt }
        
        guard !sessions.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for session in sessions {
            let sessionDate = calendar.startOfDay(for: session.startAt)
            
            if calendar.isDate(sessionDate, inSameDayAs: currentDate) {
                if streak == 0 { streak = 1 }
                continue
            } else if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate),
                      calendar.isDate(sessionDate, inSameDayAs: previousDay) {
                streak += 1
                currentDate = previousDay
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func openGitHub() {
        if let url = URL(string: "https://github.com/booya-tech/FocusSpace") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://github.com/booya-tech/FocusSpace/blob/main/docs/privacy-policy.md") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthService())
            .environmentObject(TimerViewModel(sessionSync: SessionSyncService(
                localRepository: LocalSessionRepository(),
                remoteRepository: RemoteSessionRepository()
            )))
    }
}
