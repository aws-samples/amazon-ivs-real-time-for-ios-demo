//
//  Stage.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import Foundation

enum StageType: String, Decodable {
    case video = "VIDEO", audio = "AUDIO"
}

enum StageMode: String, Decodable {
    case none = "NONE", pk = "PK", spot = "GUEST_SPOT"
}

class Stage: ObservableObject, Identifiable, Equatable, Hashable {
    static func == (lhs: Stage, rhs: Stage) -> Bool {
        return lhs.id == rhs.id
    }

    let id: String
    let stageArn: String
    var hostId: String
    var createdAt: String
    @Published var type: StageType
    @Published var mode: StageMode
    @Published var isJoined: Bool = false
    var status: String

    @Published var audioSeats: [String] = [
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        ""
    ]

    init(id: String,
         stageArn: String,
         hostId: String,
         type: StageType,
         mode: StageMode,
         status: String,
         seats: [String]?,
         createdAt: String? = nil) {

        self.id = id
        self.stageArn = stageArn
        self.hostId = hostId
        self.type = type
        self.mode = mode
        self.status = status
        self.createdAt = createdAt ?? String(describing: Date.now)

        if let seats = seats {
            self.audioSeats = seats
        }
    }

    func participant(_ participantId: String, joinedAudioSeat index: Int, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.audioSeats[index] = participantId
            completion()
        }
    }

    func participant(leftAudioSeat index: Int, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.audioSeats[index] = ""
            completion()
        }
    }

    func participantIdForSeat(at index: Int) -> String {
        return audioSeats[index]
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(hostId)
        hasher.combine(type)
        hasher.combine(mode)
    }

    func copy() -> Stage {
        return Stage(id: self.createdAt + "_copy",
                     stageArn: self.stageArn,
                     hostId: self.hostId,
                     type: self.type,
                     mode: self.mode,
                     status: self.status,
                     seats: self.audioSeats,
                     createdAt: self.createdAt)
    }
}

class StageSeatRow: Identifiable, ObservableObject {
    let id: String
    @Published var seats: [StageSeat]

    init(seats: [StageSeat]) {
        self.id = UUID().uuidString
        self.seats = seats
    }
}

class StageSeat: ObservableObject, Equatable, Identifiable {
    let id: String
    let index: Int
    let participantId: String?

    init(index: Int, participantId: String?) {
        self.id = UUID().uuidString
        self.index = index
        self.participantId = participantId
    }

    static func == (lhs: StageSeat, rhs: StageSeat) -> Bool {
        return lhs.id == rhs.id
    }
}

class DebugData: ObservableObject {
    @Published var participantStats: [String: DebugStats] = [:]

    var audioParticipanStats: [String: DebugStats] {
        return participantStats.filter({ $0.key.contains("audio") || $0.key.contains("microphone") })
    }
    var videoParticipanStats: [String: DebugStats] {
        return participantStats.filter({ $0.key.contains("video") || $0.key.contains("camera") })
    }

    var sdkVersion: String = Constants.sdk_version

    func clearStats() {
        for stat in participantStats {
            participantStats[stat.key] = DebugStats(username: stat.value.username)
        }
    }

    func clearAll() {
        participantStats = [:]
    }
}

class DebugStats: ObservableObject, Hashable, Comparable {
    let username: String
    @Published var clipboardString: String = ""
    @Published var streamQuality: String?
    @Published var cpuLimitedTime: String?
    @Published var networkLimitedTime: String?
    @Published var medianLatency: String?
    @Published var fps: String?
    @Published var packetLossDown: String?

    init(username: String) {
        self.username = username
    }

    static func == (lhs: DebugStats, rhs: DebugStats) -> Bool {
        return lhs.username == rhs.username
    }

    static func < (lhs: DebugStats, rhs: DebugStats) -> Bool {
        return lhs.username < rhs.username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(username)
    }
}
