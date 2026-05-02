//
//  RepositoryError.swift
//  FocusSpace
//

import Foundation

enum RepositoryError: LocalizedError {
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable: return "Remote storage service is unavailable"
        }
    }
}
