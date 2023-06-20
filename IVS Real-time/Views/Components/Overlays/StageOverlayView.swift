//
//  StageOverlayView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct StageOverlayView: View {

    enum TapState {
        case inactive, active
    }

    @EnvironmentObject var appModel: AppModel

    @ObservedObject var stage: Stage

    @GestureState private var state = TapState.inactive

    @State private var overlayHidden: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            if stage.type == .video {
                MultiTapView {
                    withAnimation {
                        overlayHidden.toggle()
                    }
                }
            }

            VStack {
                OverlayHeaderView()
                    .opacity(overlayHidden ? 0 : 1)
                Spacer()
                StageButtonsOverlayView(stage: stage)
                    .opacity(overlayHidden ? 0 : 1)
            }
        }
        .frame(maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
}

struct OverlayHeaderView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        HStack {
            Button {
                withAnimation {
                    appModel.isSetupCompleted.toggle()
                }

                if appModel.user.isOnStage {
                    appModel.endPublishingToStage {
                        appModel.leaveActiveStage {}
                    }
                } else {
                    appModel.leaveActiveStage {}
                }

            } label: {
                Image("arrow-small-left")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 150)
        .padding(.leading, 20)
        .padding(.top, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }
}
