//
//  UserPlans.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 5/9/26.
//

enum UserPlans: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { self.rawValue }
}
