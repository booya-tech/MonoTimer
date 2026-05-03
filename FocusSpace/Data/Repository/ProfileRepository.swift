//
//  ProfileRepository.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/2/26.
//
//  Minimal Supabase wrapper for the bits of `profiles` the app reads/writes.
//

import Foundation
import Supabase

/// Reads/writes the small set of `profiles` columns the app currently needs.
/// UPSERT is used so the row is created on demand if the user has never had
/// a profile row written before (the table can be empty for legacy users).
final class ProfileRepository {
    private var supabase: SupabaseClient? { SupabaseManager.shared.client }

    func getLastSelectedTagId() async throws -> UUID? {
        guard let supabase else { throw RepositoryError.serviceUnavailable }

        let userId = try await supabase.auth.session.user.id

        let rows: [LastSelectedTagRow] =
            try await supabase
            .from("profiles")
            .select("last_selected_tag_id")
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let raw = rows.first?.last_selected_tag_id else { return nil }
        return UUID(uuidString: raw)
    }

    func setLastSelectedTagId(_ id: UUID?) async throws {
        guard let supabase else { throw RepositoryError.serviceUnavailable }

        let userId = try await supabase.auth.session.user.id.uuidString
        let payload = ProfileUpsertPayload(
            id: userId,
            last_selected_tag_id: id?.uuidString
        )

        try await supabase
            .from("profiles")
            .upsert(payload, onConflict: "id")
            .execute()
    }
}

// MARK: - DTOs (file-private; only used by ProfileRepository)

private struct LastSelectedTagRow: Codable {
    let last_selected_tag_id: String?
}

private struct ProfileUpsertPayload: Codable {
    let id: String
    let last_selected_tag_id: String?
}
