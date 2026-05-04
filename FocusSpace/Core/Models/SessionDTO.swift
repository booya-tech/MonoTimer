//
//  SessionDTO.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 9/6/25.
//

import Foundation

/// DTO for Supabase sessions table
struct SessionDTO: Codable {
    let id: String
    let user_id: String?
    let session_type: String
    let start_at: String
    let end_at: String
    let duration_minutes: Int
    let tag: String?
    let created_at: String?
    
    init(from session: Session, userId: String) {
        self.id = session.id.uuidString
        self.user_id = userId
        self.session_type = session.type.rawValue
        self.start_at = session.startAt.ISO8601Format()
        self.end_at = session.endAt.ISO8601Format()
        self.duration_minutes = session.durationMinutes
        self.tag = session.tag
        self.created_at = nil
    }
    
    func toSession() -> Session {
        Session(
            id: UUID(uuidString: id) ?? {
                Logger.log("SessionDTO: invalid UUID '\(id)', generating fallback")
                return UUID()
            }(),
            type: SessionType(rawValue: session_type) ?? .focus,
            startAt: Self.iso8601.date(from: start_at) ?? Date(),
            endAt: Self.iso8601.date(from: end_at) ?? Date(),
            tag: tag
        )
    }

    private static let iso8601 = ISO8601DateFormatter()
}
