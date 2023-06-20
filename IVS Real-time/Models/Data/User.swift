//
//  User.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import UIKit
import AmazonIVSBroadcast
import AmazonIVSChatMessaging

class User: ObservableObject {
    let isLocal: Bool
    var userId: String
    var hostId: String
    var username: String
    var avatar: Avatar
    var participantId: String?
    var participant: IVSParticipantInfo?
    var seatIndex: Int?

    var hostParticipantToken: HostParticipantToken?
    var isHost: Bool {
        return participantId != nil && hostParticipantToken != nil
    }

    var participantToken: ParticipantToken?
    var isInStage: Bool {
        return participantId != nil && participantToken != nil
    }

    @Published var isOnStage: Bool = false
    @Published var videoOn: Bool = true
    @Published var audioOn: Bool = true
    @Published var publishState: IVSParticipantPublishState = .notPublished
    @Published var streams: [IVSStageStream] = [] {
        didSet {
            videoMuted = streams.first(where: { $0.device is IVSImageDevice })?.isMuted ?? false
            audioMuted = streams.first(where: { $0.device is IVSAudioDevice })?.isMuted ?? false
        }
    }

    // The host-app has explicitly requested audio only
    @Published var wantsAudioOnly = false
    // The host-app is in the background and requires audio only
    @Published var requiresAudioOnly = false
    // The actual audio only state to be used for subscriptions
    var isAudioOnly: Bool {
        return wantsAudioOnly || requiresAudioOnly
    }

    var isPublishing: Bool {
        return publishState == .published
    }

    var wantsSubscribed = true
    @Published var videoMuted = false
    @Published var audioMuted = false
    @Published var isSpeaking: Bool = false
    var speakingThreshold: Float = -40

    var broadcastSlotName: String {
        if isLocal {
            return "localUser"
        } else {
            guard let participantId = participantId else {
                fatalError("non-local participants must have a participantId")
            }
            return "participant-\(participantId)"
        }
    }

    private var imageDevice: IVSImageDevice? {
        return streams.lazy.compactMap { $0.device as? IVSImageDevice }.first
    }

    private var timer: Timer?

    var previewView: StageParticipantView {
        var preview: IVSImagePreviewView?
        do {
            preview = try imageDevice?.previewView(with: .fill)
        } catch {
            print("ℹ ❌ got error when trying to get participant preview view from IVSImageDevice: \(error)")
        }
        let view = StageParticipantView(preview: preview, participant: self)
        return view
    }

    init(isLocal: Bool, username: String, avatar: Avatar) {
        self.username = username
        self.userId = username
        self.hostId = username
        self.isLocal = isLocal
        self.avatar = avatar
    }

    required init(from decoder: Decoder) throws {
        self.userId = UUID().uuidString
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoOn = try container.decode(Bool.self, forKey: .videoOn)
        audioOn = try container.decode(Bool.self, forKey: .audioOn)
        username = try container.decode(String.self, forKey: .username)
        participantId = try container.decode(String.self, forKey: .participantId)
        hostId = try container.decode(String.self, forKey: .hostId)
        avatar = Avatar()
        isLocal = try container.decode(Bool.self, forKey: .isLocal)
    }

    func toggleAudioMute() {
        audioMuted = !audioMuted
        streams
            .compactMap({ $0.device as? IVSAudioDevice })
            .first?
            .setGain(audioMuted ? 0 : 1)
    }

    func toggleVideoMute() {
        videoMuted = !videoMuted
    }

    func mutatingStreams(_ stream: IVSStageStream?, modifier: (inout IVSStageStream) -> Void) {
        guard let index = streams.firstIndex(where: { $0.device.descriptor().urn == stream?.device.descriptor().urn }) else {
            fatalError("Something is out of sync, investigate")
        }

        var stream = streams[index]
        modifier(&stream)
        streams[index] = stream
    }

    func setAudioStatsCallback(for stream: IVSStageStream) {
        if let audio = stream.device as? IVSAudioDevice {
            audio.setStatsCallback({ [weak self] stats in
                guard let threshold = self?.speakingThreshold else { return }
                DispatchQueue.main.async {
                    self?.isSpeaking = stats.rms > threshold
                }
            })
        }
    }
}

extension User: Codable, Hashable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.username == rhs.username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(username)
        hasher.combine(isHost)
        hasher.combine(userId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoOn, forKey: .videoOn)
        try container.encode(audioOn, forKey: .audioOn)
    }

    enum CodingKeys: CodingKey {
        case isHost, participantId, avatarUrl, username, audioOn, videoOn, hostId, isLocal
    }
}

struct Avatar: Decodable {
    let colLeft: String
    let colRight: String
    let colBottom: String

    var leftColor: UIColor {
        return UIColor(hex: colLeft)
    }
    var rightColor: UIColor {
        return UIColor(hex: colRight)
    }
    var bottomColor: UIColor {
        return UIColor(hex: colBottom)
    }

    init() {
        let avatarColors = 1...10
        colLeft = (UIColor(named: "\(avatarColors.randomElement()!)") ?? .black).toHexString()
        colRight = (UIColor(named: "\(avatarColors.randomElement()!)") ?? .black).toHexString()
        colBottom = (UIColor(named: "\(avatarColors.randomElement()!)") ?? .black).toHexString()
    }

    init(colLeft: String, colRight: String, colBottom: String) {
        self.colLeft = colLeft
        self.colRight = colRight
        self.colBottom = colBottom
    }

    init(_ chatUser: ChatUser) {
        self.colLeft = chatUser.attributes?["avatarColLeft"] ?? ""
        self.colRight = chatUser.attributes?["avatarColRight"] ?? ""
        self.colBottom = chatUser.attributes?["avatarColBottom"] ?? ""
    }
}
