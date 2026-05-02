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

    // Fixed UUIDs so default tags resolve identically across installs and
    // devices. Never change these once shipped.
    static let defaults: [SessionTag] = [
        SessionTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Study",
            isDefault: true
        ),
        SessionTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Work",
            isDefault: true
        ),
        SessionTag(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Coding",
            isDefault: true
        ),
    ]
}
