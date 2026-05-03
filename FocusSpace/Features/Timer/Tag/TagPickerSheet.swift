//
//  TagPickerSheet.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/1/26.
//

import SwiftUI

/// Bottom sheet to select, create, rename, and delete session tags.
/// Default tags are read-only. Custom tags are limited to `SessionTagStore.customLimit`.
struct TagPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = SessionTagStore.shared
    @ObservedObject private var preferences = AppPreferences.shared

    @State private var editingTagId: UUID?
    @State private var draftName: String = ""
    @State private var isCreating = false
    @State private var newTagName: String = ""
    @State private var errorMessage: String?
    @State private var showPaywall = false

    @FocusState private var focusedField: Field?

    private let analytics: AnalyticsService = AnalyticsBootstrap.shared

    private var shouldShowUpgradeRow: Bool {
        !preferences.isPremiumUser && !store.canCreateMore
    }

    private enum Field: Hashable {
        case rename(UUID)
        case create
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.allTags) { tag in
                        row(for: tag)
                    }
                }

                if store.canCreateMore || shouldShowUpgradeRow {
                    Section {
                        createRow
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.error)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(AppConstants.Tag.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppConstants.Tag.done) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showPaywall) {
            PaywallView(source: "tag_picker")
        }
        .task {
            if shouldShowUpgradeRow {
                analytics.capture(.tagLimitReached(
                    limit: store.customLimit,
                    isPremium: preferences.isPremiumUser
                ))
            }
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for tag: SessionTag) -> some View {
        if editingTagId == tag.id {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField(AppConstants.Tag.tagNamePlaceholder, text: $draftName)
                        .focused($focusedField, equals: .rename(tag.id))
                        .submitLabel(.done)
                        .onSubmit { commitRename(for: tag.id) }
                        .onChange(of: draftName) { _, new in
                            if new.count > SessionTag.maxNameLength {
                                draftName = String(new.prefix(SessionTag.maxNameLength))
                            }
                        }

                    Text("Up to \(SessionTag.maxNameLength) characters")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.secondaryText)
                }

                Button(AppConstants.Tag.save) { commitRename(for: tag.id) }
                    .buttonStyle(.borderless)
                Button(AppConstants.Tag.cancel) { cancelEditing() }
                    .buttonStyle(.borderless)
                    .foregroundColor(AppColors.secondaryText)
            }
        } else {
            let locked = store.isLocked(tag)
            HStack {
                Button {
                    if locked {
                        analytics.capture(.tagUpgradeTapped)
                        showPaywall = true
                    } else {
                        selectAndDismiss(tag)
                    }
                } label: {
                    HStack {
                        if locked {
                            Image(systemName: AppConstants.Icon.lockFill)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        Text(tag.name)
                            .foregroundColor(AppColors.primaryText)
                        Spacer()
                        if store.selectedTagId == tag.id {
                            Image(systemName: AppConstants.Icon.checkmark)
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if !tag.isDefault && !locked {
                    Button {
                        beginEditing(tag)
                    } label: {
                        Image(systemName: AppConstants.Icon.pencil)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .opacity(locked ? 0.5 : 1)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !tag.isDefault {
                    Button(role: .destructive) {
                        analytics.capture(.tagDeleted(
                            tagId: tag.id.uuidString,
                            customCount: store.customTags.count - 1
                        ))
                        store.delete(id: tag.id)
                    } label: {
                        Label(AppConstants.Tag.delete, systemImage: AppConstants.Icon.trash)
                    }
                }
            }
        }
    }

    private var createRow: some View {
        Group {
            if isCreating {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(AppConstants.Tag.newTagNamePlaceholder, text: $newTagName)
                            .focused($focusedField, equals: .create)
                            .submitLabel(.done)
                            .onSubmit { commitCreate() }
                            .onChange(of: newTagName) { _, new in
                                if new.count > SessionTag.maxNameLength {
                                    newTagName = String(new.prefix(SessionTag.maxNameLength))
                                }
                            }

                        Text("Up to \(SessionTag.maxNameLength) characters")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }

                    Button(AppConstants.Tag.add) { commitCreate() }
                        .buttonStyle(.borderless)
                    Button(AppConstants.Tag.cancel) { cancelCreate() }
                        .buttonStyle(.borderless)
                        .foregroundColor(AppColors.secondaryText)
                }
            } else if shouldShowUpgradeRow {
                Button {
                    analytics.capture(.tagUpgradeTapped)
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: AppConstants.Icon.lockFill)
                        Text(store.overLimitCount > 0
                             ? AppConstants.Tag.upgradeOverLimitLabel(count: store.customTags.count)
                             : AppConstants.Tag.upgradeLabel)
                        Spacer()
                        // Hide the n/limit fraction when over-limit; the count
                        // is already conveyed by the "keep all N tags" copy.
                        if store.overLimitCount == 0 {
                            Text("\(store.customTags.count)/\(store.customLimit)")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    .foregroundColor(AppColors.primaryText)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    beginCreate()
                } label: {
                    HStack {
                        Image(systemName: AppConstants.Icon.plus)
                        Text(AppConstants.Tag.createNew)
                        Spacer()
                        Text("\(store.customTags.count)/\(store.customLimit)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .foregroundColor(AppColors.primaryText)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func selectAndDismiss(_ tag: SessionTag) {
        analytics.capture(.tagSelected(
            tagId: tag.id.uuidString,
            isDefault: tag.isDefault
        ))
        store.selectedTagId = tag.id
        dismiss()
    }

    private func beginEditing(_ tag: SessionTag) {
        cancelCreate()
        editingTagId = tag.id
        draftName = tag.name
        errorMessage = nil
        focusedField = .rename(tag.id)
    }

    private func cancelEditing() {
        editingTagId = nil
        draftName = ""
        errorMessage = nil
        focusedField = nil
    }

    private func commitRename(for id: UUID) {
        do {
            try store.rename(id: id, to: draftName)
            analytics.capture(.tagRenamed(tagId: id.uuidString))
            cancelEditing()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func beginCreate() {
        cancelEditing()
        isCreating = true
        newTagName = ""
        errorMessage = nil
        focusedField = .create
    }

    private func cancelCreate() {
        isCreating = false
        newTagName = ""
        errorMessage = nil
        if focusedField == .create { focusedField = nil }
    }

    private func commitCreate() {
        do {
            let tag = try store.create(name: newTagName)
            analytics.capture(.tagCreated(
                tagId: tag.id.uuidString,
                customCount: store.customTags.count
            ))
            cancelCreate()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    Color.gray
        .sheet(isPresented: .constant(true)) {
            TagPickerSheet()
        }
}
