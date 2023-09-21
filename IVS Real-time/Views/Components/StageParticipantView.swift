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
                GeometryReader { geometry in
                    IVSImagePreviewViewWrapper(previewView: preview)
                        .overlay(alignment: .topTrailing) {
                            if appModel.isStatsOn {
                                Text("\(participant.timeToVideo != nil ? "[\(participant.timeToVideo!)]" : "") \(participant.latency != nil ? " [\(participant.latency!)]" : "")")
                                    .font(Constants.fInterBold14)
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    .padding(.horizontal, geometry.size.width * 0.05)
                                    .padding(.top, geometry.size.height * 0.08)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .frame(alignment: .trailing)
                                    .onAppear {
                                        appModel.stageModel.startRTCStats()
                                    }
                            }
                        }
                        .onAppear {
                            participant.videoRequestedAt = Date()
                        }
                }
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
