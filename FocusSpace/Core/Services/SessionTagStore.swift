//
//  SessionTagStore.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/1/26.
//
//  Facade over `TagSyncService` (Supabase-backed tags) and
//  `ProfileRepository` (last-selected tag). Mutations are exposed
//  synchronously to keep the existing picker UI unchanged: writes
//  update the in-memory list optimistically and the remote write
//  fires in the background.
//

import Combine
import Foundation

@MainActor
final class SessionTagStore: ObservableObject {
    static let shared = SessionTagStore()

    /// Per-user limit on custom (non-default) tags. Premium users get a
    /// higher cap. Re-evaluated whenever `AppPreferences.isPremiumUser` flips.
    var customLimit: Int {
        AppPreferences.shared.isPremiumUser
            ? AppConstants.Premium.premiumCustomTagLimit
            : AppConstants.Premium.freeCustomTagLimit
    }

    @Published private(set) var allTags: [SessionTag] = []
    @Published var selectedTagId: UUID? {
        didSet {
            guard !isApplyingRemoteSelection else { return }
            persistSelectedTagToRemote(selectedTagId)
        }
    }

    private let tagSync: TagSyncService
    private let profileRepository: ProfileRepository
    private var isApplyingRemoteSelection = false
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let local = LocalTagRepository()
        let remote = RemoteTagRepository()
        self.tagSync = TagSyncService(localRepository: local, remoteRepository: remote)
        self.profileRepository = ProfileRepository()

        wipeLegacyUserDefaultsIfNeeded()

        // Re-render observers when premium status flips so the picker
        // recomputes `canCreateMore` and the create-row affordance, and
        // fall back off any selection that's now locked over the free cap.
        AppPreferences.shared.$isPremiumUser
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                Task { @MainActor [weak self] in
                    self?.enforceSelectionGuard()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Reads

    var customTags: [SessionTag] { allTags.filter { !$0.isDefault } }

    var canCreateMore: Bool { customTags.count < customLimit }

    /// IDs of custom tags that exceed the current `customLimit`. Empty for premium.
    /// `customTags` is oldest-first (remote orders by `created_at ASC`), so the
    /// oldest `customLimit` tags stay usable and the rest are locked.
    var lockedCustomTagIds: Set<UUID> {
        guard !AppPreferences.shared.isPremiumUser else { return [] }
        let custom = customTags
        guard custom.count > customLimit else { return [] }
        return Set(custom.dropFirst(customLimit).map { $0.id })
    }

    func isLocked(_ tag: SessionTag) -> Bool {
        lockedCustomTagIds.contains(tag.id)
    }

    /// How many custom tags are over the current limit. Drives the "keep all N tags"
    /// upgrade copy in the picker.
    var overLimitCount: Int {
        max(0, customTags.count - customLimit)
    }

    func tag(for id: UUID?) -> SessionTag? {
        guard let id else { return nil }
        return allTags.first { $0.id == id }
    }

    var selectedTag: SessionTag? { tag(for: selectedTagId) }

    // MARK: - Mutations (sync API for picker)

    @discardableResult
    func create(name: String) throws -> SessionTag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SessionTagError.emptyName }
        guard trimmed.count <= SessionTag.maxNameLength else { throw SessionTagError.nameTooLong }
        guard canCreateMore else { throw SessionTagError.limitReached(limit: customLimit) }
        guard !nameExists(trimmed, excluding: nil) else { throw SessionTagError.duplicateName }

        let tag = SessionTag(id: UUID(), name: trimmed, isDefault: false)
        allTags.append(tag)

        let sync = tagSync
        Task {
            do { try await sync.saveTag(tag) }
            catch { Logger.log("Failed to save created tag '\(tag.name)': \(error)") }
        }
        return tag
    }

    func rename(id: UUID, to newName: String) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SessionTagError.emptyName }
        guard trimmed.count <= SessionTag.maxNameLength else { throw SessionTagError.nameTooLong }
        guard let index = allTags.firstIndex(where: { $0.id == id }),
              !allTags[index].isDefault else {
            throw SessionTagError.cannotModifyDefault
        }
        guard !nameExists(trimmed, excluding: id) else { throw SessionTagError.duplicateName }

        allTags[index].name = trimmed
        let updated = allTags[index]

        let sync = tagSync
        Task {
            do { try await sync.saveTag(updated) }
            catch { Logger.log("Failed to save renamed tag '\(updated.name)': \(error)") }
        }
    }

    func delete(id: UUID) {
        guard let index = allTags.firstIndex(where: { $0.id == id }),
              !allTags[index].isDefault else { return }

        allTags.remove(at: index)
        if selectedTagId == id {
            // didSet propagates the cleared value to `profiles.last_selected_tag_id`.
            // The DB also has ON DELETE SET NULL as a backstop.
            selectedTagId = nil
        }

        let sync = tagSync
        Task {
            do { try await sync.deleteTag(id: id) }
            catch { Logger.log("Failed to delete tag \(id): \(error)") }
        }
    }

    // MARK: - Sync

    /// Pulls tags from Supabase, seeds any missing defaults, and rehydrates
    /// `allTags` and `selectedTagId`. Safe to call on launch / foreground /
    /// after sign-in.
    func syncNow() async {
        do {
            try await tagSync.syncNow()
            self.allTags = try await tagSync.getTags()
            await hydrateSelectedTagFromRemote()
        } catch {
            Logger.log("Tag sync failed: \(error)")
        }
    }

    private func hydrateSelectedTagFromRemote() async {
        do {
            let id = try await profileRepository.getLastSelectedTagId()
            isApplyingRemoteSelection = true
            defer { isApplyingRemoteSelection = false }
            selectedTagId = id
        } catch {
            Logger.log("Failed to load last selected tag: \(error)")
        }
        // Run outside the suppression window so a fallback gets persisted.
        enforceSelectionGuard()
    }

    private func persistSelectedTagToRemote(_ id: UUID?) {
        let repo = profileRepository
        Task {
            do {
                try await repo.setLastSelectedTagId(id)
            } catch {
                Logger.log("Failed to persist selected tag: \(error)")
            }
        }
    }

    // MARK: - Helpers

    /// If the current selection points at a now-locked custom tag (e.g. after a
    /// premium downgrade), fall back to the first default tag. The `didSet` on
    /// `selectedTagId` persists the new value to `profiles.last_selected_tag_id`.
    private func enforceSelectionGuard() {
        guard !allTags.isEmpty,
            let selected = selectedTag,
            isLocked(selected)
        else { return }
        selectedTagId = allTags.first(where: { $0.isDefault })?.id
    }

    private func nameExists(_ name: String, excluding id: UUID?) -> Bool {
        allTags.contains { tag in
            tag.id != id && tag.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    // One-time cleanup of the pre-Supabase UserDefaults storage.
    private func wipeLegacyUserDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        let migratedKey = "tagsMigratedToSupabase"
        guard !defaults.bool(forKey: migratedKey) else { return }
        defaults.removeObject(forKey: "customSessionTags")
        defaults.removeObject(forKey: "selectedSessionTagId")
        defaults.set(true, forKey: migratedKey)
    }
}
