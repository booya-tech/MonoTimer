//
//  SessionTagStore.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/1/26.
//
//  Local-first store for session tags (defaults + user-created customs)
//  and the user's last-selected tag. Supabase sync is a follow-up.
//

import Foundation

@MainActor
final class SessionTagStore: ObservableObject {
    static let shared = SessionTagStore()

    static let customLimit = 3

    @Published private(set) var customTags: [SessionTag] {
        didSet { persistCustomTags() }
    }

    @Published var selectedTagId: UUID? {
        didSet {
            defaults.set(selectedTagId?.uuidString, forKey: Keys.selectedTagId)
        }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let customTags = "customSessionTags"
        static let selectedTagId = "selectedSessionTagId"
    }

    private init() {
        if let data = defaults.data(forKey: Keys.customTags),
           let decoded = try? JSONDecoder().decode([SessionTag].self, from: data) {
            self.customTags = decoded
        } else {
            self.customTags = []
        }

        if let raw = defaults.string(forKey: Keys.selectedTagId),
           let id = UUID(uuidString: raw) {
            self.selectedTagId = id
        } else {
            self.selectedTagId = nil
        }
    }

    // MARK: - Reads

    var allTags: [SessionTag] { SessionTag.defaults + customTags }

    var canCreateMore: Bool { customTags.count < Self.customLimit }

    func tag(for id: UUID?) -> SessionTag? {
        guard let id else { return nil }
        return allTags.first { $0.id == id }
    }

    var selectedTag: SessionTag? { tag(for: selectedTagId) }

    // MARK: - Mutations

    func create(name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SessionTagError.emptyName }
        guard trimmed.count <= SessionTag.maxNameLength else { throw SessionTagError.nameTooLong }
        guard canCreateMore else { throw SessionTagError.limitReached }
        guard !nameExists(trimmed, excluding: nil) else { throw SessionTagError.duplicateName }

        let tag = SessionTag(id: UUID(), name: trimmed, isDefault: false)
        customTags.append(tag)
    }

    func rename(id: UUID, to newName: String) throws {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SessionTagError.emptyName }
        guard trimmed.count <= SessionTag.maxNameLength else { throw SessionTagError.nameTooLong }
        guard let index = customTags.firstIndex(where: { $0.id == id }) else {
            throw SessionTagError.cannotModifyDefault
        }
        guard !nameExists(trimmed, excluding: id) else { throw SessionTagError.duplicateName }

        customTags[index].name = trimmed
    }

    func delete(id: UUID) {
        guard customTags.contains(where: { $0.id == id }) else { return }
        customTags.removeAll { $0.id == id }
        if selectedTagId == id {
            selectedTagId = nil
        }
    }

    // MARK: - Helpers

    private func nameExists(_ name: String, excluding id: UUID?) -> Bool {
        allTags.contains { tag in
            tag.id != id && tag.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private func persistCustomTags() {
        guard let data = try? JSONEncoder().encode(customTags) else { return }
        defaults.set(data, forKey: Keys.customTags)
    }
}
