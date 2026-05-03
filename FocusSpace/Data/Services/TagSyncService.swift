//
//  TagSyncService.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/2/26.
//

import Foundation

/// Coordinates session tag CRUD across the local cache and Supabase.
/// Mirrors `SessionSyncService`: writes go local first (immediate UI),
/// then best-effort remote; full sync replaces the local cache from remote.
@MainActor
final class TagSyncService: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?

    private let localRepository: LocalTagRepository
    private let remoteRepository: RemoteTagRepository

    init(
        localRepository: LocalTagRepository,
        remoteRepository: RemoteTagRepository
    ) {
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
    }

    // MARK: - Public Interface

    func getTags() async throws -> [SessionTag] {
        return try await localRepository.getTags()
    }

    func saveTag(_ tag: SessionTag) async throws {
        try await localRepository.save(tag)

        do {
            try await remoteRepository.save(tag)
        } catch {
            Logger.log("Remote tag save failed, will retry on next sync: \(error)")
        }
    }

    func deleteTag(id: UUID) async throws {
        try await localRepository.delete(id: id)

        do {
            try await remoteRepository.delete(id: id)
        } catch {
            Logger.log("Remote tag delete failed: \(error)")
        }
    }

    /// Pulls all tags from Supabase, seeds any missing defaults, and replaces
    /// the local cache. Safe to call on every app launch / foreground.
    func syncNow() async throws {
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            var remoteTags = try await remoteRepository.getTags()

            let inserted = try await seedMissingDefaults(existing: remoteTags)
            if !inserted.isEmpty {
                remoteTags = try await remoteRepository.getTags()
            }

            localRepository.replaceAll(with: remoteTags)
            lastSyncDate = Date()
            Logger.log("Tag sync completed: \(remoteTags.count) tags")
        } catch {
            Logger.log("Tag sync failed: \(error)")
            throw error
        }
    }

    func syncOnAppForeground() async {
        do {
            try await syncNow()
        } catch {
            Logger.log("Background tag sync failed: \(error)")
        }
    }

    // MARK: - Default Seeding

    /// Inserts any default tag (matched by name) that the user is missing.
    /// Returns the tags that were inserted.
    @discardableResult
    private func seedMissingDefaults(existing: [SessionTag]) async throws -> [SessionTag] {
        let existingNames = Set(existing.map { $0.name.lowercased() })

        let missing = SessionTag.defaultNames.filter {
            !existingNames.contains($0.lowercased())
        }

        guard !missing.isEmpty else { return [] }

        var inserted: [SessionTag] = []
        for name in missing {
            let tag = SessionTag(id: UUID(), name: name, isDefault: true)
            do {
                try await remoteRepository.save(tag)
                inserted.append(tag)
            } catch {
                Logger.log("Failed to seed default tag '\(name)': \(error)")
            }
        }
        return inserted
    }
}
