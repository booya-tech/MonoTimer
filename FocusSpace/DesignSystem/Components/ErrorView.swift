//
//  ErrorView.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 10/20/25.
//
//  Error state display component
//

import SwiftUI

struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?
    
    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.accent.opacity(0.6))
            
            // Error Message
            VStack(spacing: 8) {
                Text(AppString.errorViewTitle)
                    .font(AppTypography.title)
                    .foregroundColor(AppColors.primaryText)
                
                if let description = error.errorDescription {
                    Text(description)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.tertiaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 32)
            
            // Retry Button (if recoverable)
            if error.isRecoverable, let retryAction = retryAction {
                PrimaryButton(title: AppString.errorViewRetry) {
                    retryAction()
                }
                .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        ErrorView(
            error: .networkUnavailable,
            retryAction: { print("Retry tapped") }
        )
        
        Divider()
        
        ErrorView(
            error: .sessionExpired,
            retryAction: nil
        )
    }
}
