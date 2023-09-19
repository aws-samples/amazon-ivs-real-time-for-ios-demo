//
//  StageModel.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 31/03/2023.
//

import SwiftUI
import AmazonIVSBroadcast

protocol StageModelDelegate: AnyObject {
    func didEmitError(_ error: String)
    func participantJoined(_ participant: IVSParticipantInfo?)
    func participantLeftOrStoppedPublishing(_ participant: IVSParticipantInfo?)
    func connectionStateChanged()
    func participantUsersChanged()
}

class StageModel: NSObject, ObservableObject {
    @Published var primaryCameraName = "None"
    @Published var primaryMicrophoneName = "None"
    @Published var sessionRunning: Bool = false
    @Published var stageConnectionState: IVSStageConnectionState = .disconnected
    @Published var localUserAudioMuted: Bool = false
    @Published var localUserVideoMuted: Bool = false
    @Published var localUserWantsPublish: Bool = false
    @Published var remoteAudioMuted: Bool = false

    @ObservedObject var debugData: DebugData

    var localUser: User
    var stageType: StageType = .video
    var localStreams: [IVSLocalStageStream] = []
    var delegate: StageModelDelegate?
    var collectInboundDebugData: Bool = true

    let deviceDiscovery = IVSDeviceDiscovery()
    let deviceSlotName = UUID().uuidString

    private var debugTimer: Timer?
    private(set) var videoConfig = IVSLocalStageStreamVideoConfiguration()
    private var shouldRepublishWhenEnteringForeground = false
    private var stage: IVSStage?

    var participantUsers: [User] = [] {
        didSet {
            delegate?.participantUsersChanged()
        }
    }

    var selectedCamera: IVSDeviceDescriptor? {
        didSet {
            primaryCameraName = selectedCamera?.friendlyName ?? "None"
        }
    }

    var selectedMicrophone: IVSDeviceDescriptor? {
        didSet {
            primaryMicrophoneName = selectedMicrophone?.friendlyName ?? "None"
        }
    }

    override init() {
        self.localUser = User(isLocal: true, username: "", avatar: Avatar())
        self.debugData = DebugData()
        super.init()
        self.setupLocalUser()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mediaServicesLost),
                                               name: AVAudioSession.mediaServicesWereLostNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mediaServicesReset),
                                               name: AVAudioSession.mediaServicesWereResetNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.mediaServicesWereLostNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }

    private func setupLocalUser() {
        setupLocalCamera(to: .front)

        // Setup local audio stream for publishing microphone
        let devices = getLocalDevices()
        if let microphone = devices
            .compactMap({ $0 as? IVSMicrophone })
            .first {
            microphone.delegate = self
            // Enable echo cancellation for microphone device
            microphone.isEchoCancellationEnabled = true
            // Add stream with local audio device to localStreams
            self.localStreams.append(IVSLocalStageStream(device: microphone))
        }

        DispatchQueue.main.async {
            self.participantUsers.append(self.localUser)
        }
        localUser.streams = self.localStreams
    }

    private func setupLocalCamera(to position: IVSDevicePosition) {
        if let camera = getLocalDevices().compactMap({ $0 as? IVSCamera }).first {
            if let cameraSource = camera.listAvailableInputSources()
                .first(where: { position == .back ? $0.position == position && $0.isDefault : $0.position == position }) {
                print("ℹ local camera source: \(cameraSource)")
                camera.setPreferredInputSource(cameraSource) { [weak self] in
                    if let error = $0 {
                        print("ℹ ❌ Error on setting preferred input source: \(error)")
                    } else {
                        self?.selectedCamera = cameraSource
                    }
                    print("ℹ localy selected camera: \(String(describing: self?.selectedCamera))")
                }
            }
            self.localStreams.append(IVSLocalStageStream(device: camera, configuration: self.videoConfig))
        }
    }

    @objc private func applicationDidEnterBackground() {
        // By default any active broadcast will stop, and all I/O devices will be shutdown until
        // the app is foregrounded again.
        // This behaviour can be changed by using -createAppBackgroundImageSourceWithAttemptTrim:OnComplete:
        // (read more in the documentation)

        let connectingOrConnected = (stageConnectionState == .connecting) || (stageConnectionState == .connected)
        if connectingOrConnected {
            shouldRepublishWhenEnteringForeground = localUserWantsPublish
            localUserWantsPublish = false
            participantUsers
                .compactMap { $0.participantId }
                .forEach {
                    mutatingParticipant($0) { data in
                        data.requiresAudioOnly = true
                    }
                }
            // after changes, refresh stage strategy state
            stage?.refreshStrategy()
        }
    }

    @objc private func applicationWillEnterForeground() {
        if shouldRepublishWhenEnteringForeground {
            localUserWantsPublish = true
            shouldRepublishWhenEnteringForeground = false
        }
        if !participantUsers.isEmpty {
            participantUsers
                .compactMap { $0.participantId }
                .forEach {
                    mutatingParticipant($0) { data in
                        data.requiresAudioOnly = stageType == .audio
                    }
                }
            // after changes, refresh stage strategy state
            stage?.refreshStrategy()
        }
    }

    @objc private func mediaServicesLost() {
        print("ℹ ❌ media services were lost")
    }

    @objc private func mediaServicesReset() {
        print("ℹ media services were reset")
    }

    func joinAsParticipant(_ token: String, onComplete: (Bool) -> Void) {
        print("ℹ Joining stage as participant...")
        joinStage(token, onComplete: onComplete)
    }

    func joinAsHost(onComplete: @escaping (Bool) -> Void) {
        print("ℹ Joining stage as host...")

        guard let hostToken = localUser.hostParticipantToken else {
            print("❌ Can't join - no auth token in host stage details")
            onComplete(false)
            return
        }

        joinStage(hostToken.tokenData.token) { success in
            print("ℹ Stage joined as host")
            onComplete(success)
        }
    }

    private func joinStage(_ token: String, onComplete: (Bool) -> Void) {
        print("ℹ Joining stage")
        do {
            self.stage = nil
            let stage = try IVSStage(token: token, strategy: self)

            // set created stage IVSStageRenderer to self to get all the necessary information about it
            stage.addRenderer(self)
            stage.errorDelegate = self

            try stage.join()
            self.stage = stage

            print("ℹ ✅ stage joined")

            DispatchQueue.main.async {
                self.sessionRunning = true
            }
            onComplete(true)

        } catch {
            print("ℹ ❌ Error joining stage: \(error)")
            onComplete(false)
        }
    }

    func publish(_ user: User) {
        print("ℹ 📢 publishing to stage")
        DispatchQueue.main.async {
            self.localUserWantsPublish = true
        }

        if let participantId = user.participantId {
            toggleSubscribed(forParticipant: participantId)
        }

        delegate?.participantJoined(user.participant)
    }

    func unpublish(_ user: User) {
        print("ℹ ending publishing to stage")
        DispatchQueue.main.async {
            self.localUserWantsPublish = false
        }

        if let participantId = user.participantId {
            toggleSubscribed(forParticipant: participantId)
        }

        delegate?.participantLeftOrStoppedPublishing(user.participant)
    }

    func leaveStage() {
        print("ℹ Leaving stage")
        stage?.leave()
        DispatchQueue.main.async {
            while self.participantUsers.count > 1 {
                self.participantUsers.remove(at: self.participantUsers.count - 1)
            }
        }
        DispatchQueue.main.async {
            self.sessionRunning = false
            self.localUserWantsPublish = false
        }
        stage = nil
        endRTCStats()
    }

    func toggleLocalAudioMute() {
        // Find local audio device and update the mute state
        localStreams
            .filter { $0.device is IVSAudioDevice }
            .forEach {
                $0.setMuted(!$0.isMuted)
                localUserAudioMuted = $0.isMuted
                if let audioDevice = $0.device as? IVSAudioDevice {
                    // audio device can be muted by setting its gain to 0
                    audioDevice.setGain(localUserAudioMuted ? 0 : 1)
                }
            }
        localUser.audioOn = !localUserAudioMuted
        localUser.audioMuted = localUserAudioMuted
        print("ℹ Toggled audio, is muted: \(localUserAudioMuted)")
    }

    func toggleLocalVideoMute() {
        // Find local image device and update the mute state
        localStreams
            .filter { $0.device is IVSImageDevice }
            .forEach {
                // image device mute state can be toggled by using `setMuted(Bool)`
                $0.setMuted(!$0.isMuted)
                localUserVideoMuted = $0.isMuted
            }
        localUser.videoOn = !localUserVideoMuted
        print("ℹ Toggled video, is muted: \(localUserVideoMuted)")
    }

    func toggleRemoteAudioMute() {
        participantUsers.forEach { user in
            if user.isLocal { return }
            mutatingParticipant(user.participantId) { data in
                data.toggleAudioMute()
            }
        }
        remoteAudioMuted.toggle()
        print("ℹ Toggled remote audio, is muted: \(remoteAudioMuted)")
    }

    func swapCamera() {
        print("ℹ swapping camera to \(selectedCamera?.position == .front ? "back" : "front")")
        setupLocalCamera(to: selectedCamera?.position == .front ? .back : .front)
    }

    func updateLocalVideoStreamConfiguration() {
        localStreams
            .filter { $0.device is IVSImageDevice }
            .forEach {
                print("Updating VideoConfig for \($0.device.descriptor().friendlyName)")
                $0.setConfiguration(videoConfig)
            }
    }

    func setCamera(_ device: IVSDeviceDescriptor?) {
        setDevice(device, outDevice: \Self.selectedCamera, type: IVSCamera.self, logSource: "setCamera")
    }

    func setMicrophone(_ device: IVSDeviceDescriptor?) {
        setDevice(device, outDevice: \Self.selectedMicrophone, type: IVSMicrophone.self, logSource: "setMicrophone")
    }

    private func getLocalDevices() -> [Any] {
#if targetEnvironment(simulator)
        // We can't use IVSDeviceDiscovery when using simulator
        return []
#else
        // List available devices
        return deviceDiscovery.listLocalDevices()
#endif
    }

    private func setDevice<DeviceType: IVSMultiSourceDevice>(_ inDevice: IVSDeviceDescriptor?,
                                                             outDevice: ReferenceWritableKeyPath<StageModel, IVSDeviceDescriptor?>,
                                                             type: DeviceType.Type,
                                                             logSource: String) {
        guard let localDevice = getLocalDevices().compactMap({ $0 as? DeviceType }).first else { return }

        if let inputSource = inDevice {
            localDevice.setPreferredInputSource(inputSource) { [weak self] in
                if let error = $0 {
                    print("ℹ ❌ error setting device: \(error)")
                } else {
                    self?[keyPath: outDevice] = inputSource
                }
            }
        }

        var localStreamsDidChange = false
        let index = localStreams.firstIndex(where: { $0.device === localDevice })
        if let index = index, inDevice == nil {
            localStreams.remove(at: index)
            localStreamsDidChange = true
        } else if index == nil, inDevice != nil {
            localStreams.append(IVSLocalStageStream(device: localDevice, configuration: videoConfig))
            localStreamsDidChange = true
        }

        if localStreamsDidChange {
            self[keyPath: outDevice] = inDevice
            stage?.refreshStrategy()
            participantUsers[0].streams = localStreams
        }
    }

    func toggleSubscribed(forParticipant participantId: String) {
        mutatingParticipant(participantId) { $0.wantsSubscribed.toggle() }
        // Call `refreshStrategy` to trigger a refresh of all the `IVSStageStrategy` functions
        stage?.refreshStrategy()
    }

    func toggleAudioOnlySubscribe(forParticipant participantId: String) {
        var shouldRefresh = false
        mutatingParticipant(participantId) {
            shouldRefresh = $0.wantsSubscribed
            $0.wantsAudioOnly.toggle()
        }
        if shouldRefresh {
            // Call `refreshStrategy` to trigger a refresh of all the `IVSStageStrategy` functions
            stage?.refreshStrategy()
        }
    }

    func dataForParticipant(_ participantId: String) -> User? {
        if participantId.isEmpty { return nil }
        guard let participant = participantUsers.first(where: { $0.participantId == participantId }) else {
            print("ℹ ❌ StageModel: could not find user for participant with id \(participantId)")
            return nil
        }
        return participant
    }

    func mutatingParticipant(_ participantId: String?, modifier: (inout User) -> Void) {
        guard let index = participantUsers.firstIndex(where: { $0.participantId == participantId }) else {
            print("ℹ ❌ Something is out of sync, investigate")
            return
        }

        var participant = participantUsers[index]
        modifier(&participant)
        self.participantUsers[index] = participant
    }

    // MARK: - RTC stats
    // To obtain RTC stats, call requestRTCStats() on IVSStageStream and wait for
    // the stream(didGenerateRTCStats:) callback on IVSStageStreamDelegate

    func startRTCStats() {
        // get stats each second
        guard debugTimer == nil else { return }
        debugTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.getRTCStats()
        })
    }

    func endRTCStats() {
        // stop getting stats
        debugTimer?.invalidate()
        debugTimer = nil
    }

    func createRTCStats(for stream: IVSStageStream, username: String?) {
        if debugData.participantStats[stream.device.tag()] == nil {
            debugData.participantStats[stream.device.tag()] = DebugStats(username: username ?? "")
            print("ℹ created participant stats slot for \(stream.device.tag())")
        }
    }

    func removeRTCStats(for stream: IVSStageStream) {
        if let index = debugData.participantStats.index(forKey: stream.device.tag()) {
            debugData.participantStats.remove(at: index)
            print("ℹ removed participant stats slot for \(stream.device.tag())")
        }
    }

    private func getRTCStats() {
        participantUsers.forEach { user in
            user.streams.forEach { stream in
                do {
                    try stream.requestRTCStats()
                } catch {
                    print("ℹ ❌ failed to request RTC stats: \(error)")
                }
            }
        }
    }

    func parseRTCStats(for stream: IVSStageStream, stats: [String: [String: String]]) {
        print("ℹ \(stream.description) didGenerate stats for device with tag \(stream.device.tag())")
        if stream.device is IVSAudioDevice {
            parseAudio(for: stream, stats)
        } else if stream.device is IVSImageDevice {
            parseVideo(for: stream, stats)
        } else {
            print("ℹ will not parse: \(stats)")
        }
    }

    private func parseBaseData(for stream: IVSStageStream, from stats: [String: [String: String]]) {
        let selectedCandidatePairId = stats["T01"]?["selectedCandidatePairId"] ?? ""
        let candidatePair = stats[selectedCandidatePairId]
        let remoteInbound = stats["remote-inbound-rtp"]
        let inbound = stats["inbound-rtp"]

        DispatchQueue.main.async {
            if let roundTripTime = Float(candidatePair?["currentRoundTripTime"] ?? "") {
                self.debugData.participantStats[stream.device.tag()]?.medianLatency = String(format: "%.0fms", roundTripTime * 1000)
            } else {
                print("ℹ ❌ Could not parse currentRoundTripTime to float from '\(candidatePair?["currentRoundTripTime"] ?? "")'")
                self.debugData.participantStats[stream.device.tag()]?.medianLatency = "-"
            }
            self.debugData.participantStats[stream.device.tag()]?.packetLossDown = remoteInbound?["packetsLost"] ?? inbound?["packetsLost"]

            for user in self.participantUsers {
                user.latency = self.debugData.videoParticipanStats
                    .filter({ $0.value.username == user.username })
                    .first?.value.medianLatency
            }
        }
    }

    private func parseVideo(for stream: IVSStageStream, _ stats: [String: [String: String]]) {
        print("ℹ VIDEO didGenerateRTCStats: \(stats)")
        parseBaseData(for: stream, from: stats)

        let outbound = stats["outbound-rtp"]
        let inbound = stats["inbound-rtp"]

        if let inbound = inbound {
            parseInbound(for: stream, inbound)
        } else if let outbound = outbound {
            parseOutbound(for: stream, outbound)
        }

        DispatchQueue.main.async {
            self.debugData.participantStats[stream.device.tag()]?.clipboardString = "\(stats)"
        }
    }

    private func parseAudio(for stream: IVSStageStream, _ stats: [String: [String: String]]) {
        print("ℹ AUDIO didGenerateRTCStats: \(stats)")
        parseBaseData(for: stream, from: stats)

        DispatchQueue.main.async {
            self.debugData.participantStats[stream.device.tag()]?.clipboardString = "\(stats)"
        }
    }

    private func parseOutbound(for stream: IVSStageStream, _ outbound: [String: String]) {
        let reason = outbound["qualityLimitationReason"]
        DispatchQueue.main.async {
            self.debugData.participantStats[stream.device.tag()]?.streamQuality = reason == "none" ? "Normal" : "Degraded"
            self.debugData.participantStats[stream.device.tag()]?.fps = outbound["framesPerSecond"]
        }

        if var durationsString = outbound["qualityLimitationDurations"] {
            durationsString = durationsString.replacingOccurrences(of: "{", with: "")
            durationsString = durationsString.replacingOccurrences(of: "}", with: "")
            let durations = durationsString.components(separatedBy: ",")
            var durationsJson: [String: String] = [:]
            durations.forEach { str in
                let key = str.components(separatedBy: ":").first ?? ""
                let value = str.components(separatedBy: ":").last ?? ""
                durationsJson[key] = value
            }

            DispatchQueue.main.async {
                self.debugData.participantStats[stream.device.tag()]?.cpuLimitedTime = durationsJson["cpu"]
                self.debugData.participantStats[stream.device.tag()]?.networkLimitedTime = durationsJson["bandwidth"]
            }
        }
    }

    private func parseInbound(for stream: IVSStageStream, _ inbound: [String: String]) {
        DispatchQueue.main.async {
            self.debugData.participantStats[stream.device.tag()]?.fps = inbound["framesPerSecond"]
        }
    }
}
