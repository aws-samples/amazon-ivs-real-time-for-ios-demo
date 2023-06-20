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
        ZStack(alignment: .top) {
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
    }
}
