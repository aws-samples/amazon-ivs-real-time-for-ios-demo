//
//  JitterView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 25/04/2023.
//

import SwiftUI

struct JitterView: View {
    var count: Int = 1
    var width: CGFloat = 5

    @State private var offsetOne: Double = -1
    @State private var offsetTwo: Double = 1

    var body: some View {
        VStack(spacing: 0) {
            ForEach((1...count), id: \.self) { index in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width)
                    .shadow(color: Color.white, radius: 2)
                    .shadow(color: Color.white, radius: 4)
                    .shadow(color: Color.white, radius: 6)
                    .blur(radius: 4)
                    .offset(x: index % 2 == 0 ? offsetOne : offsetTwo)
                    .animation(
                        Animation
                            .easeInOut(duration: 0.1)
                            .speed(0.8)
                            .repeatForever(autoreverses: true),
                        value: index % 2 == 0 ? offsetOne : offsetTwo
                    )
                    .opacity(0.5)
            }
        }
        .onAppear {
            offsetOne = -offsetOne
            offsetTwo = -offsetTwo
        }
        .overlay {
            Rectangle()
                .fill(Color.white)
                .frame(width: width)
                .blur(radius: 2)
        }
    }
}
