//
//  StageParticipantView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 31/03/2023.
//

import SwiftUI
import AmazonIVSBroadcast

struct StageParticipantView: View {
    @EnvironmentObject var appModel: AppModel

    var preview: IVSImagePreviewView?
    weak var audioDevice: IVSAudioDevice?
    @ObservedObject var participant: User

    var body: some View {
        ZStack(alignment: .bottom) {
            if let preview = preview {
                IVSImagePreviewViewWrapper(previewView: preview)
            }

            if participant.videoMuted || (participant.isLocal && appModel.stageModel.localUserVideoMuted) {
                ZStack {
                    Color.black

                    Image("video-camera-slash")
                        .resizable()
                        .frame(width: 60, height: 60)
                }
            }
        }
        .background(Color("BackgroundDark"))
    }
}
