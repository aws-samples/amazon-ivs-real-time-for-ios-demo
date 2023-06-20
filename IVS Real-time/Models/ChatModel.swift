//
//  ChatModel.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import Foundation
import AmazonIVSChatMessaging

protocol ChatEventDelegate: AnyObject {
    func modeDidChange(_ attributes: [String: String]?)
    func seatsDidChange(_ seats: [String])
    func votesChanged(_ attributes: [String: String]?)
    func didReceive(_ reaction: String)
    func votingStarted()
}

class ChatModel: ObservableObject, Equatable, Hashable {

    enum StageEvent: String {
        case modeChange = "stage:MODE"
        case seatsChange = "stage:SEATS"
        case voteStart = "stage:VOTE_START"
        case vote = "stage:VOTE"
        case voteEnd = "stage:VOTE_END"
    }

    var eventDelegate: ChatEventDelegate?
    var tokenRequest: ChatTokenRequest?
    var room: ChatRoom?

    @Published var messages: [Message] = []

    func connectChatRoom(_ chatTokenRequest: ChatTokenRequest, onError: @escaping (String?) -> Void) {
        print("ℹ Connecting to stage chat room \(chatTokenRequest.stageHostId)")
        tokenRequest = chatTokenRequest
        room = nil
        room = ChatRoom(awsRegion: chatTokenRequest.awsRegion) {
            return ChatToken(token: chatTokenRequest.chatRoomToken?.token ?? "")
        }
        room?.delegate = self

        Task(priority: .background) {
            room?.connect({ _, error in
                if let error = error {
                    print("❌ Could not connect to chat room: \(error)")
                    onError(error.localizedDescription)
                }
            })
        }
    }

    func disconnect() {
        room?.disconnect()
        DispatchQueue.main.async {
            self.messages = []
        }
    }

    func sendMessage(_ message: String, user: User, onComplete: @escaping (String?) -> Void) {
        let sendRequest = SendMessageRequest(content: message)
        room?.sendMessage(with: sendRequest,
                          onSuccess: { _ in
            onComplete(nil)
        },
                          onFailure: { chatError in
            print("❌ Error sending message: \(chatError)")
            onComplete(chatError.localizedDescription)
        })
    }

    func sendReaction() {
        let request = SendMessageRequest(content: "heart",
                                         attributes: ["type": MessageType.event.rawValue,
                                                      "reaction": "heart"])
        room?.sendMessage(with: request,
                          onSuccess: { _ in print("ℹ reaction sent ✅") },
                          onFailure: { chatError in print("ℹ ❌ Error sending reaction: \(chatError)") })
    }

    static func == (lhs: ChatModel, rhs: ChatModel) -> Bool {
        return lhs.room == rhs.room
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(room)
    }
}

extension ChatModel: ChatRoomDelegate {
    func roomDidConnect(_ room: ChatRoom) {
        print("ℹ Did connect to chat room \(room)")
    }

    func roomDidDisconnect(_ room: ChatRoom) {
        print("ℹ Did disconnect from chat room \(room)")
    }

    func room(_ room: ChatRoom, didReceive message: ChatMessage) {
        print("ℹ Chat did receive message: \(message.content), attributes: \(message.attributes ?? [:])")

        if let type = message.attributes?["type"],
           type == MessageType.event.rawValue,
           let reaction = message.attributes?["reaction"] {
            eventDelegate?.didReceive(reaction)
        } else {
            DispatchQueue.main.async {
                self.messages.append(Message(type: .message, message: message))
                // Store only last 10 messages
                if self.messages.count > 10 {
                    self.messages.remove(at: 0)
                }
            }
        }
    }

    func room(_ room: ChatRoom, didReceive event: ChatEvent) {
        print("ℹ Chat did receive event: \(event.eventName)")
        print("ℹ event attributes: \(String(describing: event.attributes))")

        switch event.eventName {
            case StageEvent.modeChange.rawValue:
                eventDelegate?.modeDidChange(event.attributes)
            case StageEvent.seatsChange.rawValue:
                if let attributes = event.attributes?["seats"], let seats = convertToArray(text: attributes) {
                    eventDelegate?.seatsDidChange(seats)
                }
            case StageEvent.voteStart.rawValue:
                print("ℹ voting started")
                eventDelegate?.votingStarted()
                eventDelegate?.votesChanged(event.attributes)
            case StageEvent.vote.rawValue:
                print("ℹ new vote received")
                eventDelegate?.votesChanged(event.attributes)
            case StageEvent.voteEnd.rawValue:
                print("ℹ voting ended")
                eventDelegate?.votesChanged(event.attributes)
            default:
                appendEventMessages(event)
        }
    }

    private func appendEventMessages(_ event: ChatEvent) {
        if let message = event.attributes?["message"], !message.isEmpty {
            DispatchQueue.main.async {
                self.messages.append(Message(type: .joinEvent, message: nil, stringMessage: message))
            }
        }

        if let notice = event.attributes?["notice"], !notice.isEmpty {
            DispatchQueue.main.async {
                self.messages.append(Message(type: .joinEvent, message: nil, stringMessage: notice))
            }
        }
    }

    func convertToArray(text: String) -> [String]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
