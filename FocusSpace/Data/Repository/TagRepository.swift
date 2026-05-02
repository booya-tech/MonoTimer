//
//  TagRepository.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 5/2/26.
//
//  Protocol for session tag data management
//

import Foundation

/// Repository protocol for managing session tag data
protocol TagRepository {
    func getTags() async throws -> [SessionTag]
    func save(_ tag: SessionTag) async throws
    func delete(id: UUID) async throws
}
