//
//  SessionTagDTO.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/2/26.
//

import Foundation

/// DTO for Supabase `tags` table
struct SessionTagDTO: Codable {
    let id: String
    let user_id: String?
    let name: String
    let is_default: Bool
    let created_at: String?

    init(from tag: SessionTag, userId: String) {
        self.id = tag.id.uuidString
        self.user_id = userId
        self.name = tag.name
        self.is_default = tag.isDefault
        self.created_at = nil
    }

    func toSessionTag() -> SessionTag? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return SessionTag(id: uuid, name: name, isDefault: is_default)
    }
}
