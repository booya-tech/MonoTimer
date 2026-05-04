//
//  TagFloatingButton.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/1/26.
//

import SwiftUI

/// Floating control rendered at the bottom-right of the timer circle.
/// Shows a "+" when no tag is selected, or a pill with the tag name.
struct TagFloatingButton: View {
    @ObservedObject private var store = SessionTagStore.shared
    @State private var showPicker = false

    private let analytics: AnalyticsService = AnalyticsBootstrap.shared

    var body: some View {
        Button {
            analytics.capture(.tagPickerOpened(source: "floating_button"))
            showPicker = true
        } label: {
            content
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.selectedTag?.name ?? AppConstants.Tag.addTagAccessibility)
        .sheet(isPresented: $showPicker) {
            TagPickerSheet()
        }
    }

    @ViewBuilder
    private var content: some View {
        if let tag = store.selectedTag {
            ChatBubble {
                Text(tag.name)
                    .font(AppTypography.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 80, alignment: .leading)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(.white)
            }
        } else {
            Image(systemName: AppConstants.Icon.plus)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primaryText)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(AppColors.cardBackground)
                        .overlay(Circle().stroke(AppColors.separator, lineWidth: 1))
                )
        }
    }
}

/// iMessage-style chat bubble with a small tail dot on the bottom-left.
private struct ChatBubble<Content: View>: View {
    @ViewBuilder var content: () -> Content

    private let bubbleColor = Color(red: 0.157, green: 0.149, blue: 0.169)

    var body: some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(bubbleColor)
            )
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(bubbleColor)
                    .frame(width: 8, height: 8)
                    .offset(x: -3, y: 3)
            }
    }
}

#Preview("No tag selected") {
    TagFloatingButton()
}
