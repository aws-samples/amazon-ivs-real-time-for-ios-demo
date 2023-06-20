//
//  ChatMessagesView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import SwiftUI
import AmazonIVSChatMessaging

struct ChatMessagesView: View {
    @ObservedObject var chatModel: ChatModel

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chatModel.messages, id: \.id) { message in
                            MessageView(message: message)
                        }
                    }
                    .rotationEffect(.radians(.pi))
                    .scaleEffect(x: -1, y: 1, anchor: .center)
                    .animation(.easeInOut(duration: 0.25), value: chatModel.messages)
                }
                .disabled(true)
                .rotationEffect(.radians(.pi))
                .scaleEffect(x: -1, y: 1, anchor: .center)
                .onChange(of: chatModel.messages, perform: { _ in
                    guard let lastMessage = chatModel.messages.last else { return }
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                })
                .padding(.bottom, 12)
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.25)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom)
                )
            }
        }
        .frame(maxHeight: 210)
    }
}

struct MessageView: View {
    @State var message: Message
    @State private var offsetY: CGFloat = 50
    @State private var opacity: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MessagePreviewView(message: message)
        }
        .offset(y: offsetY)
        .opacity(opacity)
        .onAppear {
            withAnimation {
                offsetY = 0
                opacity = 1
            }
        }
    }
}

struct MessagePreviewView: View {
    @State var message: Message

    var body: some View {
        if let message = message.message {
            HStack(alignment: .top) {
                AvatarView(avatar: Avatar(message.sender))

                VStack(alignment: .leading, spacing: 4) {
                    Text(message.sender.attributes?["username"] ?? "")
                        .font(Constants.fInterSemiBold14)
                        .foregroundColor(.white)
                    Text(message.content)
                        .font(Constants.fInterRegular14)
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 12)
        } else {
            Text(message.stringMessage ?? "")
                .font(Constants.fInterBold14)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Color("ButtonBackgroundGray")
                        .opacity(0.4)
                )
                .cornerRadius(100)
                .padding(.leading, 12)
        }
    }
}
