//
//  LocalTagRepository.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/2/26.
//
//  Local in-memory storage for session tags (cache, populated by sync)
//

import Foundation

/// Local in-memory tag storage. Order from `replaceAll` is preserved so the
/// remote ordering (defaults first, then customs by created_at) flows through.
@MainActor
final class LocalTagRepository: TagRepository, ObservableObject {
    @Published private(set) var tags: [SessionTag] = []

    func getTags() async throws -> [SessionTag] {
        return tags
    }

    func save(_ tag: SessionTag) async throws {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index] = tag
        } else {
            tags.append(tag)
        }
    }

    func delete(id: UUID) async throws {
        tags.removeAll { $0.id == id }
    }

    func replaceAll(with newTags: [SessionTag]) {
        tags = newTags
    }
}
