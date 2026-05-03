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

        var query = supabase
            .from("sessions")
            .select()

        if let startDate {
            query = query.gte("start_at", value: startDate.ISO8601Format())
        }
        if let endDate {
            query = query.lte("end_at", value: endDate.ISO8601Format())
        }

        let response: [SessionDTO] = try await query
            .order("start_at", ascending: false)
            .execute()
            .value
        return response.map { $0.toSession() }
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

