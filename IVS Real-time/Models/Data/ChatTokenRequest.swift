//
//  ChatTokenRequest.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import Foundation
import AmazonIVSChatMessaging

struct ChatAuthToken: Codable {
    let token: String
    let sessionExpirationTime: String
    let tokenExpirationTime: String
}

enum MessageType: String {
    case message = "MESSAGE"
    case event = "EVENT"
    case joinEvent = "JOIN_EVENT"
}

struct Message: Equatable {
    let id: String
    let type: MessageType
    let message: ChatMessage?
    let stringMessage: String?

    init(type: MessageType, message: ChatMessage? = nil, stringMessage: String? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.message = message
        self.stringMessage = stringMessage
    }
}

struct ChatTokenRequest: Codable {
    enum UserCapability: String, Codable {
        case deleteMessage = "DELETE_MESSAGE"
        case disconnectUser = "DISCONNECT_USER"
        case sendMessage = "SEND_MESSAGE"
    }

    enum TokenRequestError: Error {
        case serverNotSet
    }

    let user: User
    let stageHostId: String
    let awsRegion: String
    var chatRoomToken: ChatAuthToken?

    func fetchResponse() async throws -> Data {
        print("ℹ Requesting new chat auth token")
        let customerCode = UserDefaults.standard.string(forKey: Constants.kCustomerCode) ?? ""
        guard let url = URL(string: "https://\(customerCode).\(Constants.API_URL)/chatToken/create") else {
            print("❌ Server url invalid")
            throw TokenRequestError.serverNotSet
        }
        let authSession = URLSession(configuration: .default)
        var authRequest = URLRequest(url: url)
        authRequest.httpMethod = "POST"
        authRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        authRequest.httpBody = """
            {
                "hostId": "\(stageHostId)",
                "userId": "\(user.userId)",
                "attributes": {
                    "avatarColBottom": "\(user.avatar.colBottom)",
                    "avatarColLeft": "\(user.avatar.colLeft)",
                    "avatarColRight": "\(user.avatar.colRight)",
                    "username": "\(user.username)"
                }
            }
        """.data(using: .utf8)
        authRequest.timeoutInterval = 10

        return try await authSession.data(for: authRequest).0
    }
}
