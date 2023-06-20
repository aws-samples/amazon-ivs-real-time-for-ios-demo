//
//  Modifiers.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct PrimaryButton: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    var color: Color = Color("Orange")
    var textColor: Color = .black
    var font: Font = Constants.fInterBold18

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .foregroundColor(textColor)
            .font(font)
            .background(isEnabled ? color : Color.gray)
            .cornerRadius(30)
            .contentShape(Rectangle())
    }
}
