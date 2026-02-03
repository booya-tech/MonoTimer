//
//  AuthError.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 10/30/25.
//

import Foundation

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidPassword
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated"
        case .invalidPassword: return "Invalid password"
        case .serviceUnavailable: return "Authentication service is unavailable"
        }
    }
}
