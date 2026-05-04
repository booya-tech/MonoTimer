//
//  Session.swift
//  FocusSpace
//
//  Created by Panachai Sulsaksakul on 8/30/25.
//


import Foundation
import SwiftUI

enum SessionType: String, CaseIterable, Codable {
    case focus = "focus"
    case shortBreak = "short_break"
    case longBreak = "long_break"

    var displayName: String {
        switch self {
            case .focus: return "Time to Focus"
            case .shortBreak: return "Time to Focus"
            case .longBreak: return "Time to Focus"
        }
    }

    var defaultMinutes: Int {
        switch self {
            case .focus: return 25
            case .shortBreak: return 5
            case .longBreak: return 10
        }
    }
    
    var color: Color {
        switch self {
        case .focus:
            return .white
        case .shortBreak, .longBreak:
            return .blue
        }
    }
}

struct Session: Identifiable, Hashable {
    let id: UUID
    let type: SessionType
    let startAt: Date
    let endAt: Date
    let tag: String?

    init(id: UUID = UUID(), type: SessionType, startAt: Date, endAt: Date, tag: String?) {
        self.id = id
        self.type = type
        self.startAt = startAt
        self.endAt = endAt
        self.tag = tag
    }

    // Duration in seconds
    var duration: TimeInterval {
        endAt.timeIntervalSince(startAt)
    }

    // Duration in minutes
    var durationMinutes: Int {
        Int(duration / 60)
    }
}
