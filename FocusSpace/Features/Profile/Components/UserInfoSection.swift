//
//  UserInfoSection.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/19/25.
//
//  User information header component
//

import SwiftUI

struct UserInfoSection: View {
    @EnvironmentObject private var preferences: AppPreferences
    let email: String
    let memberSince: String
    
    var body: some View {
        VStack(spacing: 12) {
            /// Description
            /// might support user's profile image in the future
            // Profile Icon
            //            Circle()
            //                .fill(AppColors.primary)
            //                .frame(width: 80, height: 80)
            //                .overlay {
            //                    Image(systemName: "person.fill")
            //                        .font(.system(size: 36))
            //                        .foregroundColor(AppColors.background)
            //                }
            ZStack {
                // Profile Circle
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        ZStack {
                            if preferences.isPremiumUser {
                                Text("👑")
                                    .font(.title2)
                                    .rotationEffect(.degrees(28))
                                    .offset(x: 30, y: -44)
                            }
                            Text("Hi")
                                .font(.system(size: 36))
                                .foregroundColor(AppColors.background)
                        }
                    )
            }
            
            // Email
            Text(email)
                .font(AppTypography.body)
                .foregroundColor(AppColors.primaryText)
                .analyticsMask()
            
            // Member Since
            Text("Member since \(memberSince)")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    UserInfoSection(
        email: "user@example.com",
        memberSince: "Jan 19, 2025"
    )
}
