//
//  RemoteSessionRepository.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 9/6/25.
//
//  Supabase implementation for session storage
//

import Foundation
import Supabase

/// Supabase remote session storage
final class RemoteSessionRepository: SessionRepository {
    private var supabase: SupabaseClient? { SupabaseManager.shared.client }

    func getSessions(from startDate: Date?, to endDate: Date?) async throws -> [Session] {
        guard let supabase else { throw RepositoryError.serviceUnavailable }
        
        let response: [SessionDTO] =
            try await supabase
            .from("sessions")
            .select()
            .order("start_at", ascending: false)
            .execute()
            .value

        var sessions = response.map { $0.toSession() }

        if let startDate = startDate {
            sessions = sessions.filter { $0.startAt >= startDate }
        }

        if let endDate = endDate {
            sessions = sessions.filter { $0.endAt <= endDate }
        }

        return sessions
    }

    func save(_ session: Session) async throws {
        guard let supabase else { throw RepositoryError.serviceUnavailable }
        
        let userId = try await supabase.auth.session.user.id.uuidString
        let dto = SessionDTO(from: session, userId: userId)

        try await supabase
            .from("sessions")
            .upsert(dto)
            .execute()
    }

    func delete(id: UUID) async throws {
        guard let supabase else { throw RepositoryError.serviceUnavailable }
        
        try await supabase
            .from("sessions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Repository Error
enum RepositoryError: LocalizedError {
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable: return "Remote storage service is unavailable"
        }
    }
}
