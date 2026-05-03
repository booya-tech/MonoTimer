//
//  SessionTag.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/1/26.
//

import Foundation

/// A label users attach to focus sessions (e.g. "Study", "Work").
/// `id` is the stable identity persisted on `Session.tag`, so renames
/// propagate without rewriting historical session rows.
struct SessionTag: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    let isDefault: Bool
}

extension SessionTag {
    static let maxNameLength = 10

    /// Names of the tags seeded for every user on first sync.
    /// IDs are assigned by the database (one row per user).
    static let defaultNames: [String] = ["Study", "Work", "Coding"]
}
