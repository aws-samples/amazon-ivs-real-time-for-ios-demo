//
//  AppModel.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI
import AmazonIVSBroadcast

class AppModel: ObservableObject {
    @ObservedObject var server: ServerModel
    @ObservedObject var stagesModel: StagesModel
    @ObservedObject var stageModel: StageModel
    @Published var user: User

    @Published var isConnected: Bool = false
    @Published var wasConnected: Bool = false
    @Published var isSetupCompleted: Bool = false

    @Published var userWantsToJoinVideoStage: Bool = false
    @Published var userWantsToLeaveStage: Bool = false
    @Published var hostWantsToRemoveParticipant: Bool = false

    @Published var username: String = ""
    @Published private(set) var errorMessages: [String] = []

    @Published var isLoading: Bool = false

    @Published private(set) var activeStage: Stage?
    @Published private var activeStageHostUsername: String = ""
    @Published var activeStageSecondParticipant: User?
    @Published var activeStageHostParticipant: User?
    @Published var participantsChanged: Bool = false

    @Published var reactionViews: [ReactionView] = []

    @Published var votesCountHost: Int = 0
    @Published var votesCountParticipant: Int = 0
    @Published var votingSessionIsActive: Bool = false
    @Published var votingSessionStartedAt: Date?
    @Published var pkVotingWinVisualsActive: Bool = false

    private var stageJoinInProgress: Bool = false
    var chatModel: ChatModel?
    var shouldJoinActiveStage: Bool = false
    var activeVotingSessionTally: [String: Int]?
    let activeStageBottomSpace: CGFloat = 40
    let dateFormatter = DateFormatter()
    var hostAvatar: Avatar? {
        if user.isHost {
            return user.avatar
        } else {
            guard let attributes = user.participantToken?.hostAttributes else {
                return nil
            }
            return Avatar(colLeft: attributes["avatarColLeft"] ?? "",
                          colRight: attributes["avatarColRight"] ?? "",
                          colBottom: attributes["avatarColBottom"] ?? "")
        }
    }
    var maxBitrate: Int {
        var bitrate = UserDefaults.standard.integer(forKey: Constants.kMaxBitrate)
        if bitrate == 0 {
            bitrate = 400
        }
        return bitrate
    }

    init() {
        self.server = ServerModel()
        self.user = User(isLocal: true, username: UsernameProvider.getRandomUsername(), avatar: Avatar())
        self.stagesModel = StagesModel()
        self.stageModel = StageModel()
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        username = user.username
        stageModel.localUser = user

        server.delegate = self
        stagesModel.delegate = self
        stageModel.delegate = self
    }

    func generateRandomUsername() {
        username = UsernameProvider.getRandomUsername()
        user.username = username
    }

    private func toggleLoading(_ value: Bool) {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = value
            }
        }
    }

    func verify(silent: Bool = false, completion: @escaping (Bool) -> Void) {
        errorMessages.removeAll()
        isLoading = true
        server.verify(silent: silent) { [weak self] success in
            DispatchQueue.main.async {
                withAnimation {
                    self?.isConnected = success
                    self?.wasConnected = success
                    self?.isLoading = false
                }
            }
            completion(success)
        }
    }

    func getStages(completion: @escaping (Bool) -> Void) {
        print("ℹ getting stages...")

        server.getStages(onlyActive: !user.isHost) { [weak self] success, stageDetails in
            DispatchQueue.main.async {
                if success {
                    self?.stagesModel.setNewStages(stageDetails)
                }
            }
            completion(success)
        }
    }

    func disconnect() {
        print("ℹ disconnecting...")
        toggleLoading(true)

        stageModel.leaveStage()

        withAnimation {
            isConnected = false
        }

        toggleLoading(false)
    }

    func kickSecondParticipant() {
        toggleLoading(true)

        if let activeStage = activeStage {
            // Remove other participant by updating stage mode no NONE
            // because other participant should still remain in stage but stop publishig
            server.updateMode(activeStage.hostId, toStageMode: .none, user: user) { [weak self] success in
                print("ℹ removed second participant by updating stage mode: \(success ? "✅" : "❌")")
                DispatchQueue.main.async {
                    self?.hostWantsToRemoveParticipant = false
                }
                self?.toggleLoading(false)
            }

        } else {
            print("ℹ ❌ Can't remove second participant - some details missing")
            toggleLoading(false)
        }
    }

    func createStage(_ type: StageType) {
        toggleLoading(true)

        server.createStage(type: type, user: user) { [weak self] success, hostToken in
            if success {
                print("ℹ ✅ stage created")
                self?.stageModel.stageType = type
                self?.user.participantToken = nil
                self?.user.hostParticipantToken = hostToken
                self?.stageModel.collectInboundDebugData = false
                self?.user.participantId = hostToken?.tokenData.participantId

                DispatchQueue.main.async {
                    self?.activeStageHostParticipant = self?.user
                    self?.activeStageHostUsername = self?.user.username ?? ""
                }

                self?.stageModel.joinAsHost(onComplete: { [weak self] success in
                    print("ℹ stage joined as host: \(success ? "✅" : "❌")")

                    self?.getCreatedStage({ stage in
                        self?.finishStageCreation(stage)
                    })
                })
            }
        }
    }

    private func getCreatedStage(_ completion: @escaping (Stage) -> Void) {
        getStages(completion: { [weak self] _ in
            if let createdStage = self?.stagesModel.stages.first(where: { $0.hostId == self?.user.hostId }) {
                completion(createdStage)
            } else {
                print("ℹ retrying to get created stage")
                self?.getCreatedStage(completion)
            }
        })
    }

    private func finishStageCreation(_ createdStage: Stage) {
        print("ℹ found created stage (arn: \(createdStage.stageArn))")

        DispatchQueue.main.async {
            self.stagesModel.scrollTo(createdStage)
            createdStage.isJoined = true
            self.isSetupCompleted = true
        }

        print("ℹ host will connect to chat now")
        connectToChat(createdStage.hostId)

        if createdStage.type == .video {
            stageModel.stageType = .video
            publishToVideoStage(.none)
        }

        if createdStage.type == .audio {
            stageModel.stageType = .audio
            publishToAudioStage(inAudioSeat: 0)
        }

        toggleLoading(false)
    }

    func publishToAudioStage(inAudioSeat: Int) {
        guard let activeStage = activeStage, let participantId = user.participantId else {
            return
        }

        stageModel.toggleAudioOnlySubscribe(forParticipant: participantId)
        user.seatIndex = inAudioSeat
        activeStage.participant(participantId, joinedAudioSeat: inAudioSeat) { [weak self] in
            guard let user = self?.user, let seats = self?.activeStage?.audioSeats else { return }
            self?.server.updateSeats(activeStage.hostId, seats: seats, user: user) { [weak self] success in
                if success {
                    print("ℹ ✅ audio seats updated")
                }

                self?.getStages(completion: { [weak self] _ in
                    self?.toggleLoading(false)
                })
            }
        }

        DispatchQueue.main.async {
            self.user.isOnStage = true
        }
        stageModel.publish(user)
    }

    func changeSeat(to newIndex: Int) {
        guard let activeStage = activeStage,
              let participantId = user.participantId,
              let seatIndex = user.seatIndex else {
            return
        }

        activeStage.participant(leftAudioSeat: seatIndex) { [weak self] in
            self?.user.seatIndex = newIndex
            self?.activeStage?.participant(participantId, joinedAudioSeat: newIndex) { [weak self] in
                guard let user = self?.user, let seats = self?.activeStage?.audioSeats else { return }
                self?.server.updateSeats(activeStage.hostId, seats: seats, user: user) { [weak self] success in
                    if success {
                        print("ℹ ✅ audio seats updated")
                    }

                    self?.getStages(completion: { [weak self] _ in
                        self?.toggleLoading(false)
                    })
                }
            }
        }
    }

    func updateVideoConfiguration() {
        do {
            try stageModel.videoConfig.setMaxBitrate(maxBitrate * 1000)
        } catch {
            print("ℹ ❌ Failed to update maxBitrate: \(error)")
        }
        stageModel.updateLocalVideoStreamConfiguration(stageModel.videoConfig)
    }

    func publishToVideoStage(_ inMode: StageMode) {
        guard let activeStage = activeStage else {
            return
        }

        switch inMode {
            case .none:
                break
            case .spot:
                server.updateMode(activeStage.hostId, toStageMode: .spot, user: user) { success in
                    if success {
                        print("ℹ ✅ stage mode updated to SPOT")
                    }
                }
            case .pk:
                server.updateMode(activeStage.hostId, toStageMode: .pk, user: user) { success in
                    if success {
                        print("ℹ ✅ stage mode updated to PK/VS")
                    }
                }
        }

        DispatchQueue.main.async {
            self.user.isOnStage = true
            self.votesCountParticipant = 0
            self.votesCountHost = 0
        }
        stageModel.publish(user)
    }

    func endPublishingToStage(_ onComplete: @escaping () -> Void) {
        user.isOnStage = false
        stageModel.unpublish(user)

        if let stage = activeStage {
            if stage.type == .audio {
                if let participantId = user.participantId {
                    stageModel.toggleAudioOnlySubscribe(forParticipant: participantId)
                }
                if let seatIndex = user.seatIndex {
                    stage.participant(leftAudioSeat: seatIndex) { [weak self] in
                        guard let user = self?.user, let seats = self?.activeStage?.audioSeats else { return }
                        self?.server.updateSeats(stage.hostId, seats: seats, user: user) { _ in
                            onComplete()
                        }
                    }
                }
            }

            if stage.type == .video {
                server.updateMode(stage.hostId, toStageMode: .none, user: user) { _ in
                    onComplete()
                }
            }
        } else {
            onComplete()
        }
    }

    func connectToChat(_ hostId: String) {
        if let oldChatModel = chatModel {
            print("ℹ disconnecting previous stage chat...")
            oldChatModel.disconnect()
            chatModel = nil
        }

        print("ℹ connecting to new stage chat...")
        self.chatModel = ChatModel()
        chatModel?.eventDelegate = self

        server.createChatToken(for: user, stageHostId: hostId) { [weak self] _, chatAuthToken in
            guard let user = self?.user else { return }
            let region = user.isHost ? user.hostParticipantToken?.region : user.participantToken?.region
            let tokenRequest = ChatTokenRequest(user: user,
                                                stageHostId: hostId,
                                                awsRegion: region ?? "us-west-2",
                                                chatRoomToken: chatAuthToken)
            self?.chatModel?.connectChatRoom(tokenRequest) { error in
                print("ℹ ❌ Couldn't connect to chat: \(String(describing: error))")
            }
        }
    }

    func leaveActiveStage(_ onComplete: @escaping () -> Void) {
        guard let stage = activeStage else {
            print("ℹ ❌ Can't leave - no active stage")
            onComplete()
            return
        }

        print("ℹ 🏁 leaving active stage (arn: \(stage.stageArn))...")
        toggleLoading(true)

        DispatchQueue.main.async {
            stage.isJoined = false
        }

        stageModel.leaveStage()
        chatModel?.disconnect()

        if user.isHost {
            server.deleteStage(stageHostId: user.hostId) { [weak self] success in
                if success {
                    print("ℹ ✅ stage deleted")

                    DispatchQueue.main.async {
                        withAnimation {
                            self?.userWantsToLeaveStage = false
                        }
                    }
                }

                onComplete()
                self?.toggleLoading(false)
            }

            clearData()

        } else {
            if let seatIndex = user.seatIndex {
                stage.participant(leftAudioSeat: seatIndex) { [weak self] in
                    guard let user = self?.user, let seats = self?.activeStage?.audioSeats else { return }

                    switch stage.type {
                        case .audio:
                            self?.server.updateSeats(stage.hostId, seats: seats, user: user) { [weak self] _ in
                                self?.clearData()
                                onComplete()
                                self?.toggleLoading(false)
                            }
                        default:
                            self?.clearData()
                            onComplete()
                            self?.toggleLoading(false)
                    }
                }
            } else {
                clearData()
                onComplete()
                toggleLoading(false)
            }
        }
    }

    func appendErrorMessage(_ error: String) {
        DispatchQueue.main.async {
            if self.errorMessages.contains(error) { return }
            self.errorMessages.append(error)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.removeErrorMessage(error)
        }
    }

    func removeErrorMessage(_ error: String) {
        DispatchQueue.main.async {
            if let index = self.errorMessages.firstIndex(of: error) {
                self.errorMessages.remove(at: index)
            }
        }
    }

    private func activeStageChanged(_ newStage: Stage?) {
        guard activeStage?.id != newStage?.id, let newStage = newStage else { return }

        if activeStage != nil, !user.isHost {
            // Disconnect from old stage and chat
            leaveActiveStage { [weak self] in
                // Then join new one
                self?.join(newStage)
            }
        } else {
            join(newStage)
        }
    }

    private func join(_ stage: Stage) {
        guard !stageJoinInProgress else {
            print("ℹ stage is already being joined")
            return
        }
        stageJoinInProgress = true

        DispatchQueue.main.async {
            withAnimation {
                self.activeStage = stage
                self.votingSessionStartedAt = nil
                self.activeStageHostParticipant = nil
                self.activeStageSecondParticipant = nil
            }
        }

        guard shouldJoinActiveStage else {
            stageJoinInProgress = false
            return
        }

        toggleLoading(true)

        if stage.type == .video {
            print("ℹ 📺 joining \(stage.hostId) stage (arn: \(stage.stageArn))...")
            stageModel.stageType = .video
        } else {
            print("ℹ 📻 joining \(stage.hostId) stage (arn: \(stage.stageArn))...")
            stageModel.stageType = .audio
        }

        server.join(stage, user: user) { [weak self] success, participantToken in
            if success {
                guard let token = participantToken?.token else {
                    print("ℹ ❌ can't join - no participantToken")
                    self?.stageJoinInProgress = false
                    return
                }

                self?.stageModel.joinAsParticipant(token, onComplete: { _ in
                    self?.user.hostParticipantToken = nil
                    self?.user.participantToken = participantToken
                    self?.stageModel.collectInboundDebugData = true
                    self?.user.participantId = participantToken?.participantId

                    DispatchQueue.main.async {
                        self?.activeStageHostUsername = participantToken?.hostAttributes?["username"] ?? ""
                        withAnimation {
                            self?.userWantsToJoinVideoStage = false
                        }
                    }

                    self?.connectToChat(stage.hostId)
                })
                self?.toggleLoading(false)
                self?.stageJoinInProgress = false
            }

            DispatchQueue.main.async {
                stage.isJoined = success
            }
        }
    }

    func castVote(for user: User?) {
        guard let user = user,
              let stageId = activeStage?.hostId else {
            print("ℹ ❌ Could't cast vote: active stage or user missing")
            return
        }

        server.castVote(in: stageId, for: user) { success in
            print("ℹ vote casted for \(user.username): \(success ? "✅" : "❌")")
        }
    }

    private func applyActiveVotingTally() {
        guard let tally = activeVotingSessionTally else { return }

        if let key = activeStageHostParticipant?.username, let hostVotes = tally["\(key)"] {
            DispatchQueue.main.async {
                self.votesCountHost = hostVotes
                self.activeVotingSessionTally?.removeValue(forKey: key)
            }
        }

        if let key = activeStageSecondParticipant?.username, let participantVotes = tally["\(key)"] {
            DispatchQueue.main.async {
                self.votesCountParticipant = participantVotes
                self.activeVotingSessionTally?.removeValue(forKey: key)
            }
        }
    }

    func cleanUp() {
        stagesModel.clearStages()
        chatModel?.disconnect()
    }

    private func clearData() {
        DispatchQueue.main.async {
            self.user.isOnStage = false
            self.user.wantsAudioOnly = false
            self.activeStage?.mode = .none
            self.activeStage = nil
            self.votesCountParticipant = 0
            self.votesCountHost = 0
            self.votingSessionStartedAt = nil
        }
        user.seatIndex = nil
        user.hostParticipantToken = nil
        user.participantToken = nil
        user.participantId = nil
        user.participant = nil
        stageModel.collectInboundDebugData = true
        stageModel.debugData.clearAll()
    }
}

extension AppModel: ServerDelegate {
    func didEmitError(error: String) {
        self.appendErrorMessage(error)
        self.toggleLoading(false)
    }

    func activeVotingSessionInProgress(_ session: VotingSession) {
        print("ℹ voting session is active: \(session)")
        activeVotingSessionTally = session.tally
        DispatchQueue.main.async {
            self.votingSessionStartedAt = self.dateFormatter.date(from: session.startedAt)
        }
    }
}

extension AppModel: StagesModelDelegate {
    func activeStageChanged(to stage: Stage?) {
        activeStageChanged(stage)
    }
}

extension AppModel: StageModelDelegate {
    func didEmitError(_ error: String) {
        self.appendErrorMessage(error)
        self.toggleLoading(false)
    }

    func participantJoined(_ participant: IVSParticipantInfo?) {
        print("ℹ participant joined \(participant?.participantId ?? "nil")")
        guard let participantId = participant?.participantId,
              let newUser = stageModel.dataForParticipant(participantId) else {
            print("ℹ ❌ could not get user for participantId \(String(describing: participant?.participantId))")
            return
        }

        if participant?.isLocal ?? false {
            guard user.isOnStage else {
                print("ℹ will not set local user as active participant - user is not on stage")
                return
            }

            DispatchQueue.main.async {
                if self.user.isHost {
                    self.activeStageHostParticipant = self.user
                    print("ℹ active stage host set to local user")
                } else {
                    self.activeStageSecondParticipant = self.user
                    print("ℹ active 2nd participant set to local user")
                }
            }

        } else {
            guard newUser.streams.count == 0 else {
                print("ℹ will not set new user as active participant - new user has 0 streams")
                return
            }

            guard let username = participant?.attributes["username"] else {
                print("ℹ ❌ participant joined with no attributes - username missing")
                return
            }

            DispatchQueue.main.async {
                if username == self.activeStageHostUsername {
                    self.activeStageHostParticipant = newUser
                    print("ℹ active stage host set to new user")
                    self.applyActiveVotingTally()
                } else {
                    self.activeStageSecondParticipant = newUser
                    print("ℹ active 2nd participant set to new user")
                    self.applyActiveVotingTally()
                }
            }
        }
    }

    func participantLeftOrStoppedPublishing(_ participant: IVSParticipantInfo?) {
        print("ℹ participant \(participant?.participantId ?? "nil") left or stopped publishing")
        if activeStageHostParticipant?.participantId == participant?.participantId {
            activeStageHostParticipant = nil
        }

        if activeStageSecondParticipant?.participantId == participant?.participantId {
            activeStageSecondParticipant = nil
        }
    }

    func connectionStateChanged() {
        if stageModel.stageConnectionState == .disconnected {
            if user.isOnStage {
                endPublishingToStage {}
            }

            endPublishingToStage {
                DispatchQueue.main.async {
                    self.activeStageHostParticipant = nil
                    self.activeStageSecondParticipant = nil
                }
            }
        }
    }

    func participantUsersChanged() {
        DispatchQueue.main.async {
            self.participantsChanged.toggle()
        }
    }
}

extension AppModel: ChatEventDelegate {
    func modeDidChange(_ attributes: [String: String]?) {
        guard let attributes = attributes,
              let newModeString = attributes["mode"],
              let newMode = StageMode(rawValue: newModeString) else { return }

        // Stop publishing (if I'm not the host) in case mode changed to NONE
        if user.isOnStage, !user.isHost && newMode == .none {
            DispatchQueue.main.async {
                self.endPublishingToStage {}
            }
        }

        DispatchQueue.main.async {
            withAnimation {
                self.stagesModel.stages.first(where: { $0.hostId == self.activeStage?.hostId })?.mode = newMode
            }
            self.votesCountParticipant = 0
            self.votesCountHost = 0
        }
    }

    func seatsDidChange(_ seats: [String]) {
        DispatchQueue.main.async {
            self.activeStage?.audioSeats = seats
        }
    }

    func votesChanged(_ attributes: [String: String]?) {
        print("ℹ votes changed: \(String(describing: attributes))")
        guard let attributes = attributes else {
            print("ℹ ❌ could not process vote attributes: no attributes")
            return
        }

        if let hostVotes = attributes["\(activeStageHostParticipant?.username ?? "")"] {
            if self.votesCountHost > Int(hostVotes) ?? 0 { return }

            DispatchQueue.main.async {
                self.votesCountHost = Int(hostVotes) ?? 0
            }
        }

        if let participantVotes = attributes["\(activeStageSecondParticipant?.username ?? "")"] {
            if self.votesCountParticipant > Int(participantVotes) ?? 0 { return }

            DispatchQueue.main.async {
                self.votesCountParticipant = Int(participantVotes) ?? 0
            }
        }
    }

    func votingStarted() {
        DispatchQueue.main.async {
            self.votingSessionStartedAt = Date.now
        }
    }

    func didReceive(_ reaction: String) {
        DispatchQueue.main.async {
            self.reactionViews.append(ReactionView(reaction: reaction))
        }
    }
}
