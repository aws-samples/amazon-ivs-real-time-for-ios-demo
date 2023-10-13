//
//  VideoView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import SwiftUI

struct VideoView: View {
    @EnvironmentObject var appModel: AppModel

    @ObservedObject var stage: Stage

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                if let participant = appModel.activeStageHostParticipant {
                    participant.previewView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color("BackgroundDark")
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
            )

            if stage.mode == .spot && appModel.activeStageSecondParticipant != nil {
                ZStack {
                    if let participant2 = appModel.activeStageSecondParticipant {
                        participant2.previewView
                    }
                }
                .frame(width: 141, height: 200)
                .background(
                    Color.black
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                )
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white, lineWidth: 1)
                )
                .padding(.trailing, 16)
                .padding(.top, 120)
                .transition(.opacity)
            }
        }
        .background(Color("BackgroundDark"))
    }
}
