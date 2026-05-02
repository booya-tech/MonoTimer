//
//  SessionTagError.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 5/2/26.
//

import Foundation

enum SessionTagError: LocalizedError {
    case emptyName
    case nameTooLong
    case duplicateName
    case limitReached
    case cannotModifyDefault

    var errorDescription: String? {
        switch self {
        case .emptyName: return "Tag name cannot be empty."
        case .nameTooLong: return "Tag name can't be longer than \(SessionTag.maxNameLength) characters."
        case .duplicateName: return "A tag with this name already exists."
        case .limitReached: return "You can only create up to \(SessionTagStore.customLimit) custom tags."
        case .cannotModifyDefault: return "Default tags cannot be edited or deleted."
        }
    }
}
