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

import Foundation

@MainActor
final class SessionTagStore: ObservableObject {
    static let shared = SessionTagStore()

    nonisolated static let customLimit = 3

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

    private init() {
        let local = LocalTagRepository()
        let remote = RemoteTagRepository()
        self.tagSync = TagSyncService(localRepository: local, remoteRepository: remote)
        self.profileRepository = ProfileRepository()

        wipeLegacyUserDefaultsIfNeeded()
    }

    // MARK: - Reads

    var customTags: [SessionTag] { allTags.filter { !$0.isDefault } }

    var canCreateMore: Bool { customTags.count < Self.customLimit }

    func tag(for id: UUID?) -> SessionTag? {
        guard let id else { return nil }
        return allTags.first { $0.id == id }
    }

    var selectedTag: SessionTag? { tag(for: selectedTagId) }

    // MARK: - Mutations (sync API for picker)

    func create(name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SessionTagError.emptyName }
        guard trimmed.count <= SessionTag.maxNameLength else { throw SessionTagError.nameTooLong }
        guard canCreateMore else { throw SessionTagError.limitReached }
        guard !nameExists(trimmed, excluding: nil) else { throw SessionTagError.duplicateName }

        let tag = SessionTag(id: UUID(), name: trimmed, isDefault: false)
        allTags.append(tag)

        let sync = tagSync
        Task { try? await sync.saveTag(tag) }
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
        Task { try? await sync.saveTag(updated) }
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
        Task { try? await sync.deleteTag(id: id) }
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
            let remoteId = try await profileRepository.getLastSelectedTagId()
            isApplyingRemoteSelection = true
            selectedTagId = remoteId
            isApplyingRemoteSelection = false
        } catch {
            Logger.log("Failed to load last selected tag: \(error)")
        }
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

    private func nameExists(_ name: String, excluding id: UUID?) -> Bool {
        allTags.contains { tag in
            tag.id != id && tag.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    // One-time cleanup of the pre-Supabase UserDefaults storage.
    private func wipeLegacyUserDefaultsIfNeeded() {
        print("BEFORE WIPE: \(UserDefaults.standard.dictionaryRepresentation())")
        let defaults = UserDefaults.standard
        let migratedKey = "tagsMigratedToSupabase"
        guard !defaults.bool(forKey: migratedKey) else { return }
        defaults.removeObject(forKey: "customSessionTags")
        defaults.removeObject(forKey: "selectedSessionTagId")
        defaults.set(true, forKey: migratedKey)
        print("AFTER WIPED: \(UserDefaults.standard.dictionaryRepresentation())")
    }
}
