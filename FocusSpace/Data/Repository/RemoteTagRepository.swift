//
//  RemoteTagRepository.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/2/26.
//
//  Supabase implementation for session tag storage
//

import Foundation
import Supabase

/// Supabase remote tag storage. Reads `user_id` from the auth session for
/// inserts so RLS policies can match `auth.uid() = user_id`.
final class RemoteTagRepository: TagRepository {
    private var supabase: SupabaseClient? { SupabaseManager.shared.client }

    func getTags() async throws -> [SessionTag] {
        guard let supabase else { throw RepositoryError.serviceUnavailable }

        let response: [SessionTagDTO] =
            try await supabase
            .from("tags")
            .select()
            .order("is_default", ascending: false)
            .order("created_at", ascending: true)
            .execute()
            .value

        return response.compactMap { $0.toSessionTag() }
    }

    func save(_ tag: SessionTag) async throws {
        guard let supabase else { throw RepositoryError.serviceUnavailable }

        let userId = try await supabase.auth.session.user.id.uuidString
        let dto = SessionTagDTO(from: tag, userId: userId)

        try await supabase
            .from("tags")
            .upsert(dto)
            .execute()
    }

    func delete(id: UUID) async throws {
        guard let supabase else { throw RepositoryError.serviceUnavailable }

        try await supabase
            .from("tags")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
