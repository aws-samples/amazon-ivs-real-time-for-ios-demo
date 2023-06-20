//
//  ControlButtonsView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import SwiftUI

struct ControlButtonsView: View {
    @EnvironmentObject var appModel: AppModel

    @ObservedObject var stage: Stage
    @ObservedObject var stageModel: StageModel

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            if !appModel.user.isHost, let avatar = appModel.hostAvatar {
                AvatarView(avatar: avatar, withBorder: true)
            }

            if appModel.user.isOnStage {
                ControlButton(icon: stageModel.localUserAudioMuted ? Image("microphone-slash") : Image("microphone"),
                              iconColor: stageModel.localUserAudioMuted ? Color("Red") : .white,
                              backColor: stageModel.localUserAudioMuted ? .white : Color("BackgroundDark").opacity(0.8)) {
                    stageModel.toggleLocalAudioMute()
                }
            }

            if stage.type == .video && appModel.user.isOnStage {
                ControlButton(icon: stageModel.localUserVideoMuted ? Image("video-camera-slash") : Image("video-camera"),
                              iconColor: stageModel.localUserVideoMuted ? Color("Red") : .white,
                              backColor: stageModel.localUserVideoMuted ? .white : Color("BackgroundDark").opacity(0.8)) {
                    stageModel.toggleLocalVideoMute()
                }

                ControlButton(icon: Image("arrow-path-rounded-square"),
                                          iconColor: stageModel.selectedCamera?.position == .front ? .white : .black,
                                          backColor: stageModel.selectedCamera?.position == .front ? Color("BackgroundDark").opacity(0.8) : .white) {
                    stageModel.swapCamera()
                }
            }

            if appModel.user.isOnStage {
                ControlButton(icon: Image("arrow-left-on-rectangle"),
                              backColor: Color("Red")) {
                    appModel.userWantsToLeaveStage = true
                }
            }

            if stage.type != .audio && !appModel.user.isOnStage && !appModel.user.isHost {
                ControlButton(icon: Image("user-plus"),
                              backColor: Color("ButtonBackgroundGray").opacity(0.8)) {
                    if appModel.activeStageSecondParticipant != nil {
                        appModel.appendErrorMessage("Unable to join stage. No spot available.")
                    } else {
                        withAnimation {
                            appModel.userWantsToJoinVideoStage = true
                        }
                    }
                }
            }

            if appModel.user.isHost || appModel.user.isOnStage {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.8))
                    .frame(width: 15, height: 1.5)
                    .padding(.vertical, 7)
            }

            if stage.type == .video && appModel.user.isHost {
                if appModel.activeStageSecondParticipant != nil {
                    ControlButton(icon: Image("user-minus"),
                                  backColor: Color("ButtonBackgroundGray").opacity(0.8)) {
                        appModel.hostWantsToRemoveParticipant = true
                    }
                }
            }

            ZStack {
                ControlButton(icon: Image("heart-icon"),
                              backColor: Color("ButtonBackgroundGray").opacity(0.8)) {
                    appModel.chatModel?.sendReaction()
                }

                ForEach(appModel.reactionViews) { view in
                    view
                        .task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            DispatchQueue.main.async {
                                if let index = appModel.reactionViews.firstIndex(of: view) {
                                    appModel.reactionViews.remove(at: index)
                                }
                            }
                        }
                }
            }
        }
        .padding(.trailing, 15)
        .padding(.bottom, 6)
    }
}

struct ControlButton: View {
    var icon: Image
    var iconColor: Color = .white
    var backColor: Color = Color("BackgroundDark").opacity(0.8)
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .foregroundColor(backColor)
                    .frame(width: 42, height: 42)
                icon
                    .renderingMode(.template)
                    .tint(iconColor)
            }
        }
    }
}
