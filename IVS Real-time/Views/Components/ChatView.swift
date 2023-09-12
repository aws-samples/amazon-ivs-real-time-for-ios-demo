//
//  ChatView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appModel: AppModel

    var stage: Stage
    @State var message: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if let chatModel = appModel.chatModel {
                ChatMessagesView(chatModel: chatModel)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 13) {
                if stage.mode == .pk {
                    HStack(alignment: .top) {
                        VoteButton(votes: $appModel.votesCountHost, backFill: Color("RedStar")) {
                            appModel.castVote(for: appModel.activeStageHostParticipant)
                            appModel.votesCountHost += 1
                        }

                        VoteButton(votes: $appModel.votesCountParticipant, backFill: Color("BlueStar")) {
                            appModel.castVote(for: appModel.activeStageSecondParticipant)
                            appModel.votesCountParticipant += 1
                        }
                    }
                    .padding(.horizontal, 5)
                    .padding(.top, 5)
                    .transition(.opacity)
                }

                HStack(alignment: .bottom) {
                    AvatarView(avatar: appModel.user.avatar)
                        .padding(.leading, 8)

                    CustomTextField(
                        text: $message,
                        font: UIFont(name: "Inter-Regular", size: 15),
                        textColor: UIColor.white,
                        background: UIColor(named: "ButtonBackgroundGray")?.withAlphaComponent(0.4),
                        cornerRadius: 21
                    ) {
                        if message.isEmpty {
                            return
                        }
                        appModel.chatModel?.sendMessage(message, user: appModel.user, onComplete: { error in
                            if let error = error {
                                print("ℹ ❌ Could not send chat message: \(error)")
                            } else {
                                message = ""
                            }
                        })
                    }
                    .placeholder(when: message.isEmpty, alignment: .leading) {
                        Text("Say something...")
                            .font(Constants.fInterRegular15)
                            .foregroundColor(.white)
                            .background(Color.clear)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .padding(.horizontal, 0)
                    .padding(.trailing, 5)
                }
                .padding(.bottom, 5)
            }
            .background(
                backgroundView()
            )
            .padding(.leading, 4)
        }
    }

    @ViewBuilder
    private func backgroundView() -> some View {
        if stage.mode == .pk {
            Color("ButtonBackgroundGray")
                .opacity(0.8)
                .cornerRadius(10, corners: [.topLeft, .topRight])
                .cornerRadius(25, corners: [.bottomLeft, .bottomRight])
        } else {
            EmptyView()
        }
    }
}

struct VoteButton: View {
    @Binding var votes: Int
    let backFill: Color
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Circle()
                    .fill(backFill)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image("star")
                            .resizable()
                            .frame(width: 12, height: 12)
                    }

                Text(String(votes))
                    .font(Constants.fInterBold14)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
        .background {
            Color.white
                .cornerRadius(10)
                .opacity(0.3)
        }
    }
}
