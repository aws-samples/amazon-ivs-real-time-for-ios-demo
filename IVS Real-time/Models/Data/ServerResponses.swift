//
//  Data.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import Foundation

struct Stages: Decodable {
    let stages: [StageDetails]
}

struct StageDetails: Decodable {
    let createdAt: String
    let hostId: String
    let mode: StageMode
    let type: StageType
    let status: String
    let seats: [String]?
    let stageArn: String
}

struct HostParticipantToken: Decodable {
    let region: String
    let tokenData: TokenData

    enum CodingKeys: String, CodingKey {
        case region, tokenData = "hostParticipantToken"
    }
}

struct TokenData: Decodable {
    let token: String
    let participantId: String
    let duration: Int
}

struct ParticipantToken: Decodable {
    let region: String
    let metadata: ParticipantMetadata
    let token: String
    let participantId: String
    let duration: Int
    let hostAttributes: [String: String]?
}

struct ParticipantMetadata: Decodable {
    let activeVotingSession: VotingSession?
}

struct VotingSession: Decodable {
    let startedAt: String
    let tally: [String: Int]
}
