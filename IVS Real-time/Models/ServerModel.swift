//
//  ServerModel.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 30/03/2023.
//

import Foundation
import SwiftUI

protocol ServerDelegate: AnyObject {
    func didEmitError(error: String)
    func activeVotingSessionInProgress(_ session: VotingSession)
}

class ServerModel: ObservableObject {
    var delegate: ServerDelegate?
    var decoder = JSONDecoder()

    func verify(silent: Bool, _ onComplete: @escaping (Bool) -> Void) {
        send(silent: silent, "GET", endpoint: "verify", body: nil) { _, _, error in
            if let error = error {
                print("ℹ ❌ Could not verify customer code: \(error)")
                self.delegate?.didEmitError(error: "Invalid code")
                onComplete(false)
                return
            }

            onComplete(true)
        }
    }

    func getStages(onlyActive: Bool = true, _ onComplete: @escaping (Bool, [StageDetails]) -> Void) {
        send("GET",
             endpoint: "",
             body: nil,
             queryItems: onlyActive ? [URLQueryItem(name: "status", value: "active")] : nil,
             onComplete: { [weak self] success, data, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false, [])
            }

            guard let data = data else {
                print("ℹ ❌ No data in response")
                onComplete(false, [])
                return
            }

            do {
                let rawStages = try self?.decoder.decode(Stages.self, from: data)
                guard let stages = rawStages?.stages else {
                    print("ℹ ❌ Got something else than stages array")
                    onComplete(false, [])
                    return
                }
                print("ℹ got \(stages.count) stages")
                onComplete(success, stages)

            } catch {
                print("❌ \(error)")
                onComplete(false, [])
                return
            }
        })
    }

    func createStage(type: StageType, user: User, onComplete: @escaping (Bool, HostParticipantToken?) -> Void) {
        guard let customerCode = UserDefaults.standard.string(forKey: Constants.kCustomerCode) else {
            delegate?.didEmitError(error: "Customer code not set")
            return
        }

        let body = """
            {
                "cid": "\(customerCode)",
                "hostId": "\(user.hostId)",
                "hostAttributes": {
                    "avatarColBottom": "\(user.avatar.colBottom)",
                    "avatarColLeft": "\(user.avatar.colLeft)",
                    "avatarColRight": "\(user.avatar.colRight)",
                    "username": "\(user.username)"
                },
                "type": "\(type.rawValue)"
            }
        """

        send("POST", endpoint: "create", body: body, onComplete: { [weak self] _, data, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false, nil)
            }

            guard let data = data else {
                print("ℹ ❌ No data in response")
                onComplete(false, nil)
                return
            }

            do {
                let hostParticipantToken = try self?.decoder.decode(HostParticipantToken.self, from: data)
                print("ℹ got host participant token: \(String(describing: hostParticipantToken))")
                onComplete(true, hostParticipantToken)
            } catch {
                print("ℹ ❌ \(error)")
                onComplete(false, nil)
                return
            }
        })
    }

    func createChatToken(for user: User, stageHostId: String, onComplete: @escaping (Bool, ChatAuthToken?) -> Void) {
        let body = """
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
        """

        send("POST", endpoint: "chatToken/create", body: body, onComplete: { [weak self] _, data, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false, nil)
            }

            guard let data = data else {
                print("ℹ ❌ No data in response")
                onComplete(false, nil)
                return
            }

            do {
                let chatToken = try self?.decoder.decode(ChatAuthToken.self, from: data)
                print("ℹ got chat token: \(String(describing: chatToken))")
                onComplete(true, chatToken)
            } catch {
                print("ℹ ❌ \(error)")
                onComplete(false, nil)
                return
            }
        })
    }

    func join(_ stage: Stage, user: User, onComplete: @escaping (Bool, ParticipantToken?) -> Void) {
        let body = """
            {
                "hostId": "\(stage.hostId)",
                "userId": "\(user.userId)",
                "attributes": {
                    "avatarColBottom": "\(user.avatar.colBottom)",
                    "avatarColLeft": "\(user.avatar.colLeft)",
                    "avatarColRight": "\(user.avatar.colRight)",
                    "username": "\(user.username)"
                }
            }
        """

        send("POST", endpoint: "join", body: body, onComplete: { [weak self] _, data, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false, nil)
            }

            guard let data = data else {
                print("ℹ ❌ No data in response")
                onComplete(false, nil)
                return
            }

            do {
                let participantToken = try self?.decoder.decode(ParticipantToken.self, from: data)
                print("ℹ got participant token: \(String(describing: participantToken))")

                self?.checkForActiveVotingSession(participantToken)

                onComplete(true, participantToken)
            } catch {
                print("ℹ ❌ \(error)")
                onComplete(false, nil)
                return
            }
        })
    }

    func deleteStage(stageHostId: String, onComplete: @escaping (Bool) -> Void) {
        let body = """
            {
                "hostId": "\(stageHostId)"
            }
        """

        send("DELETE", endpoint: "", body: body, onComplete: { success, _, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false)
            }

            onComplete(success)
        })
    }

    func updateMode(_ stageId: String, toStageMode: StageMode, user: User, onComplete: @escaping (Bool) -> Void) {
        let body = """
            {
                "hostId": "\(stageId)",
                "userId": "\(user.userId)",
                "mode": "\(toStageMode.rawValue)"
            }
        """

        send("PUT", endpoint: "update/mode", body: body, onComplete: { success, _, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false)
            }

            onComplete(success)
        })
    }

    func updateSeats(_ stageId: String, seats: [String], user: User, onComplete: @escaping (Bool) -> Void) {
        let body = """
            {
                "hostId": "\(stageId)",
                "userId": "\(user.userId)",
                "seats": \(seats)
            }
        """

        send("PUT", endpoint: "update/seats", body: body, onComplete: { success, _, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false)
            }

            onComplete(success)
        })
    }

    func castVote(in stageId: String, for user: User, onComplete: @escaping (Bool) -> Void) {
        let body = """
            {
                "hostId": "\(stageId)",
                "vote": "\(user.userId)"
            }
        """

        send("POST", endpoint: "castVote", body: body, onComplete: { success, _, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false)
            }

            onComplete(success)
        })
    }

    func disconnectUser(from stageHostId: String, userId: String, participantId: String, onComplete: @escaping (Bool) -> Void) {
        let body = """
            {
                "hostId": "\(stageHostId)",
                "userId": "\(userId)",
                "participantId": "\(participantId)"
            }
        """

        send("PUT", endpoint: "disconnect", body: body, onComplete: { success, _, errorMessage in
            if let error = errorMessage {
                print("ℹ ❌ \(error)")
                onComplete(false)
            }

            onComplete(success)
        })
    }

    // MARK: Private

    private func checkForActiveVotingSession(_ token: ParticipantToken?) {
        print("ℹ checking for active voting session...")
        if let session = token?.metadata.activeVotingSession {
            delegate?.activeVotingSessionInProgress(session)
        }
    }

    private func send(silent: Bool = false, _ method: String, endpoint: String, body: String?, queryItems: [URLQueryItem]? = nil, onComplete: @escaping (Bool, Data?, String?) -> Void) {
        guard let customerCode = UserDefaults.standard.string(forKey: Constants.kCustomerCode) else {
            if silent { return }
            delegate?.didEmitError(error: "Customer code not set")
            return
        }

        let urlComponents = NSURLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "\(customerCode).\(Constants.API_URL)"
        urlComponents.queryItems = queryItems
        urlComponents.path = "/\(endpoint)"

        guard let url = urlComponents.url else {
            onComplete(false, nil, "Couldn't get url from URLComponents")
            return
        }

        let session = URLSession(configuration: .default)
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(UserDefaults.standard.string(forKey: Constants.kApiKey) ?? "", forHTTPHeaderField: "x-api-key")

        if let body = body {
            request.httpBody = body.data(using: .utf8)
        }

        print("ℹ 🔗 sending \(method) '\(url.absoluteString)' \(body != nil ? "with body: \(body!)" : "")")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("ℹ 🔗 ❌ Failed to send '\(method)' to '\(endpoint)': \(error)")
                onComplete(false, nil, silent ? nil : error.localizedDescription)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if ![200, 201, 204].contains(httpResponse.statusCode) {
                    print("ℹ 🔗 Got status code \(httpResponse.statusCode) when sending \(request)")
                    if let data = data, let response = String(data: data, encoding: .utf8) {
                        print(response)
                        onComplete(false, nil, "Got status code \(httpResponse.statusCode) with response: \(response)")
                    } else {
                        print("ℹ 🔗 ❌ Got status code \(httpResponse.statusCode) when sending \(method) to \(request)")
                    }
                    return
                }

                print("ℹ 🔗 sent \(method) to '\(endpoint)' successfully")
                onComplete(true, data, nil)
            }
        }
        .resume()
    }
}
