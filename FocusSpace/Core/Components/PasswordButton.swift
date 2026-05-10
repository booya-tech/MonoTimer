//
//  PasswordButton.swift
//  MonoTimer
//
//  Created by Panachai Sulsaksakul on 5/4/26.
//

import SwiftUI

struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textFieldStyle(MonoTextFieldStyle())
            .analyticsMask()

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye" : "eye.slash")
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.trailing, 12)
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var isVisible = false
    PasswordField(placeholder: "Password", text: $text, isVisible: $isVisible)
        .padding()
}
