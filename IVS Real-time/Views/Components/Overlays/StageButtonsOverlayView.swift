//
//  StageButtonsOverlayView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import SwiftUI

struct StageButtonsOverlayView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var opacity: Double = 0

    @ObservedObject var stage: Stage

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: UIScreen.main.bounds.width,
                       height: UIScreen.main.bounds.height/2,
                       alignment: .bottom)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.45), .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )

            HStack(alignment: .bottom) {
                ChatView(stage: stage)

                ControlButtonsView(stage: stage, stageModel: appModel.stageModel)
            }
            .frame(height: 400, alignment: .bottom)
            .padding(.bottom, 8)
            .keyboardAwarePadding()
        }
        .frame(width: UIScreen.main.bounds.width)
        .opacity(opacity)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            opacity = appModel.user.isHost ? 1 : 0
        }
        .onChange(of: stage.isJoined, perform: { isJoined in
            withAnimation(.easeInOut) {
                opacity = isJoined ? 1 : 0
            }
        })
    }
}
