//
//  View.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 4/4/26.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
