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
    @EnvironmentObject var preferences: AppPreferences
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var timerViewModel: TimerViewModel
    @StateObject private var habitStreaksVM = HabitStreaksBoardViewModel()
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var showingSignOutAlert = false
    @State private var showPaywall = false
    @State private var isRestoring = false
    
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

                // Premium Section
                if preferences.isPremiumUser {
                    premiumSection
                } else {
                    notPremiumSection
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
        .analyticsScreen("Profile")
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

    // MARK: - Premium Section
    private var notPremiumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subscription")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primaryText)

            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.body)
                    Text("Go Premium")
                        .font(AppTypography.body)
                    Spacer()
                    Image(systemName: AppConstants.Icon.chevronRight)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .foregroundStyle(AppColors.primaryText)
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
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(source: "profile")
        }
    }

    // MARK: - Premium Section (active subscriber)
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subscription")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.primaryText)

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.body)
                    Text("\(storeKit.currentPlan.rawValue) Plan")
                        .font(AppTypography.body)
                    Spacer()
                    Text("Active")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .foregroundStyle(AppColors.primaryText)
                .padding()

                Divider().padding(.leading)

                Button {
                    Task {
                        isRestoring = true
                        await storeKit.restorePurchases()
                        isRestoring = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.body)
                        Text(AppString.paywallRestorePurchases)
                            .font(AppTypography.body)
                        Spacer()
                        if isRestoring {
                            ProgressView().scaleEffect(0.8)
                        }
                    }
                    .foregroundStyle(AppColors.primaryText)
                    .padding()
                }
                .buttonStyle(.plain)
                .disabled(isRestoring)

                Divider().padding(.leading)

                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                            .font(.body)
                        Text("Manage Subscription")
                            .font(AppTypography.body)
                        Spacer()
                        Image(systemName: AppConstants.Icon.chevronRight)
                            .font(.caption)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .foregroundStyle(AppColors.primaryText)
                    .padding()
                }
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
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AppPreferences.shared)
            .environmentObject(AuthService())
            .environmentObject(TimerViewModel(sessionSync: SessionSyncService(
                localRepository: LocalSessionRepository(),
                remoteRepository: RemoteSessionRepository()
            )))
    }
}
