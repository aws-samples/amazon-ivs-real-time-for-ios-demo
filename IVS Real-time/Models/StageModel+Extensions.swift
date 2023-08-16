//
//  StageModel+Extensions.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 31/03/2023.
//

import AmazonIVSBroadcast

extension StageModel: IVSMicrophoneDelegate {
    func underlyingInputSourceChanged(for microphone: IVSMicrophone, toInputSource inputSource: IVSDeviceDescriptor?) {
        guard localStreams.contains(where: { $0.device === microphone }) else { return }
        selectedMicrophone = inputSource
    }
}

extension StageModel: IVSErrorDelegate {
    func source(_ source: IVSErrorSource, didEmitError error: Error) {
        print("ℹ ❌ IVSError \(error)")
    }
}

// These callbacks are triggered by `IVSStage.refreshStrategy()`
// Call `IVSStage.refreshStrategy()` whenever we want to update the answers to these questions
extension StageModel: IVSStageStrategy {
    func stage(_ stage: IVSStage, shouldSubscribeToParticipant participant: IVSParticipantInfo) -> IVSStageSubscribeType {
        guard let data = dataForParticipant(participant.participantId) else {
            return .none
        }
        let subType: IVSStageSubscribeType
        if data.wantsSubscribed {
            subType = data.isAudioOnly ? .audioOnly : .audioVideo
        } else {
            subType = .none
        }

        return subType
    }

    func stage(_ stage: IVSStage, shouldPublishParticipant participant: IVSParticipantInfo) -> Bool {
        // start/stop publishing
        return localUserWantsPublish
    }

    func stage(_ stage: IVSStage, streamsToPublishForParticipant participant: IVSParticipantInfo) -> [IVSLocalStageStream] {
        guard participantUsers[0].participantId == participant.participantId else {
            return []
        }
        return localStreams
    }
}

extension StageModel: IVSStageRenderer {
    func stage(_ stage: IVSStage, participantDidJoin participant: IVSParticipantInfo) {
        print("ℹ participant \(participant.participantId) did join")

        if participant.isLocal {
            // Update local participant
            self.participantUsers[0].participantId = participant.participantId
            self.participantUsers[0].participant = participant
        } else {
            if self.participantUsers.contains(where: { $0.participantId == participant.participantId }) {
                print("ℹ not adding \(participant.participantId) to participants list - already exists there")
                return
            }

            // Create and store User for newly joined participant
            let newUser = User(isLocal: false,
                               username: participant.attributes["username"] ?? "",
                               avatar: Avatar(
                colLeft: participant.attributes["avatarColLeft"] ?? "",
                colRight: participant.attributes["avatarColRight"] ?? "",
                colBottom: participant.attributes["avatarColBottom"] ?? ""))
            newUser.participantId = participant.participantId
            newUser.participant = participant
            self.participantUsers.append(newUser)
        }
        self.delegate?.participantJoined(participant)
    }

    func stage(_ stage: IVSStage, participantDidLeave participant: IVSParticipantInfo) {
        print("ℹ participant \(participant.participantId) did leave")

        if participant.isLocal {
            // Reset local participant ID
            self.participantUsers[0].participantId = nil
        } else {
            if let index = participantUsers.firstIndex(where: { $0.participantId == participant.participantId }) {
                self.participantUsers.remove(at: index)
            }
        }
        delegate?.participantLeftOrStoppedPublishing(participant)
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChange publishState: IVSParticipantPublishState) {
        print("ℹ participant \(participant.participantId) didChangePublishState to '\(publishState.text)'")
        mutatingParticipant(participant.participantId) { data in
            data.publishState = publishState
        }
        self.delegate?.participantJoined(participant)
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChange subscribeState: IVSParticipantSubscribeState) {
        print("ℹ participant \(participant.participantId) didChangeSubscribeState to '\(subscribeState.text)'")

    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didAdd streams: [IVSStageStream]) {
        print("ℹ participant \(participant.participantId) didAdd \(streams.count) streams")

        for stream in streams {
            let username = participantUsers.first(where: { $0.participant == participant })?.username
            createRTCStats(for: stream, username: username)
        }

        mutatingParticipant(participant.participantId) { data in
            data.streams.append(contentsOf: streams)
            data.streams.forEach { stream in
                stream.delegate = self
                data.setAudioStatsCallback(for: stream)
            }
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didRemove streams: [IVSStageStream]) {
        print("ℹ participant \(participant.participantId) didRemove \(streams.count) streams")

        for stream in streams {
            removeRTCStats(for: stream)
        }

        mutatingParticipant(participant.participantId) { data in
            // Use unique device locator to remove designated streams for participant
            let oldUrns = streams.map { $0.device.descriptor().urn }
            data.streams.removeAll(where: { stream in
                return oldUrns.contains(stream.device.descriptor().urn)
            })
        }
        delegate?.participantLeftOrStoppedPublishing(participant)
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChangeMutedStreams streams: [IVSStageStream]) {
        print("ℹ participant \(participant.participantId) didChangeMutedStreams")
        for stream in streams {
            print("ℹ is muted: \(stream.isMuted)")
            mutatingParticipant(participant.participantId) { data in
                if [.microphone, .userAudio].contains(stream.device.descriptor().type) {
                    data.audioMuted = stream.isMuted
                }

                if [.camera, .userImage].contains(stream.device.descriptor().type) {
                    data.videoMuted = stream.isMuted
                }

                if let index = data.streams.firstIndex(of: stream) {
                    data.streams[index] = stream
                }
            }
        }
    }

    func stage(_ stage: IVSStage, didChange connectionState: IVSStageConnectionState, withError error: Error?) {
        print("ℹ didChangeConnectionStateWithError state '\(connectionState.text)', error: \(String(describing: error))")
        stageConnectionState = connectionState
        delegate?.connectionStateChanged()
    }
}

extension StageModel: IVSStageStreamDelegate {
    func streamDidChangeIsMuted(_ stream: IVSStageStream) {
        print("ℹ \(stream.description) didChangeIsMuted \(stream.isMuted)")
    }

    func stream(_ stream: IVSStageStream, didGenerateRTCStats stats: [String: [String: String]]) {
        parseRTCStats(for: stream, stats: stats)
    }
}

// MARK: - State extensions

extension IVSStageConnectionState {
    var text: String {
        switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .connected: return "Connected"
            @unknown default: return "Unknown connection state"
        }
    }
}

extension IVSParticipantPublishState {
    var text: String {
        switch self {
            case .notPublished: return "Not Published"
            case .attemptingPublish: return "Attempting to Publish"
            case .published: return "Published"
            @unknown default: return "Unknown publish state"
        }
    }
}

extension IVSParticipantSubscribeState {
    var text: String {
        switch self {
            case .subscribed: return "Subscribed"
            case .notSubscribed: return "Not Subscribed"
            case .attemptingSubscribe: return "Attempting Subscribe"
            @unknown default: return "Unknown subscribe state"
        }
    }
}

extension IVSDeviceType {
    var text: String {
        switch self {
            case .microphone: return "Microphone"
            case .camera: return "Camera"
            case .userAudio: return "User Audio"
            case .userImage: return "User Image"
            case .unknown: return "Unknown"
            @unknown default: return "Unknown connection state"
        }
    }
}
