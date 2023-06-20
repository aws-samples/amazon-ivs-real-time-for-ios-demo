//
//  AvatarView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 31/03/2023.
//

import SwiftUI

struct AvatarView: View {
    var avatar: Avatar
    var withBorder: Bool = false
    var borderColor: Color = .white
    var size: CGFloat = 42

    var body: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(uiColor: avatar.bottomColor).opacity(1))
                    .frame(width: size, height: size)
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(uiColor: avatar.rightColor).opacity(1))
                        .frame(width: size/2, height: size/2)
                    Rectangle()
                        .fill(Color(uiColor: avatar.leftColor).opacity(1))
                        .frame(width: size/2, height: size/2)
                }
                .offset(y: -size/4)
            }
            .rotationEffect(Angle(degrees: 180))
            .frame(width: size, height: size)
            .clipShape(Circle())
            .transition(.opacity)
            .overlay {
                if withBorder {
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(borderColor, lineWidth: 2)
                }
            }
    }
}
