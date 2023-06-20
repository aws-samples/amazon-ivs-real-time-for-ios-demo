//
//  DebugDataView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 19/04/2023.
//

import SwiftUI

struct DebugDataView: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var user: User
    @StateObject var debugData: DebugData

    var body: some View {
        Group {
            switch appModel.activeStage?.type {
                case .video:
                    if user.isHost || user.isOnStage {
                        VideoParticipantDataView(debugData: debugData, user: user)
                    } else {
                        VideoViewerDebugDataView(debugData: debugData)
                    }
                case .audio:
                    if user.isHost || user.isOnStage {
                        AudioParticipantDebugDataView(debugData: debugData, user: user)
                    } else {
                        AudioListenerDebugDataView(debugData: debugData)
                    }
                default:
                    EmptyView()
            }
        }
        .onDisappear {
            appModel.stageModel.debugData.clearStats()
        }
    }
}

struct VideoParticipantDataView: View {
    @ObservedObject var debugData: DebugData
    @ObservedObject var user: User

    var stats: DebugStats? {
        debugData
            .videoParticipanStats
            .filter({ $0.value.username == user.username })
            .first?.value
    }

    var body: some View {
        VStack(spacing: 16) {
            DebugDataRow(title: "Stream quality", value: stats?.streamQuality ?? "-")
            DebugDataRow(title: "CPU-limited time", value: stats?.cpuLimitedTime ?? "-")
            DebugDataRow(title: "Network-limited time", value: stats?.networkLimitedTime ?? "-")
            Rectangle()
                .fill(Color("BackgroundGray"))
                .frame(height: 1)
            DebugDataRow(title: "Latency (roundtrip)", value: stats?.medianLatency ?? "-")
            DebugDataRow(title: "FPS", value: stats?.fps ?? "-")
            Rectangle()
                .fill(Color("BackgroundGray"))
                .frame(height: 1)
            DebugDataRow(title: "Packets loss", value: stats?.packetLossDown ?? "-")
            Rectangle()
                .fill(Color("BackgroundGray"))
                .frame(height: 1)
            DebugDataRow(title: "SDK version", value: debugData.sdkVersion)
        }
    }
}

struct VideoViewerDebugDataView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var debugData: DebugData

    var body: some View {
        VStack(spacing: 16) {
            if let hostStats = debugData.participantStats
                .filter({ $0.key.contains("video") })
                .first(where: { $0.value.username == appModel.activeStageHostParticipant?.username })?.value {
                VideoRoomParticipantStatsView(stats: hostStats, name: "Host")
            }

            if let participantStats = debugData.participantStats
                .filter({ $0.key.contains("video") })
                .first(where: { $0.value.username == appModel.activeStageSecondParticipant?.username })?.value {
                VideoRoomParticipantStatsView(stats: participantStats, name: "Guest")
            }

            Rectangle()
                .fill(Color("BackgroundGray"))
                .frame(height: 1)
            DebugDataRow(title: "SDK version", value: debugData.sdkVersion)
        }
    }
}

struct AudioParticipantDebugDataView: View {
    @ObservedObject var debugData: DebugData
    @ObservedObject var user: User

    var stats: DebugStats? {
        debugData
            .audioParticipanStats
            .filter({ $0.value.username == user.username })
            .first?.value
    }

    var body: some View {
        VStack(spacing: 16) {
            DebugDataRow(title: "Latency (roundtrip)", value: stats?.medianLatency ?? "-")
            DebugDataRow(title: "Packets lost", value: stats?.packetLossDown ?? "-")

            Rectangle()
                .fill(Color("BackgroundGray"))
                .frame(height: 1)
            DebugDataRow(title: "SDK version", value: debugData.sdkVersion)
        }
    }
}

struct AudioListenerDebugDataView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var debugData: DebugData

    var body: some View {
        @State var hostData = debugData.participantStats
            .filter({ $0.key.contains("audio") })
            .first(where: { $0.value.username == appModel.activeStageHostParticipant?.username })

        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                if let hostStats = hostData?.value {
                    AudioRoomParticipantStatsView(stats: hostStats, name: "Host")
                }

                ForEach(debugData.participantStats.filter({ $0.key.contains("audio") }).values.sorted(by: >), id: \.self) { participantStats in
                    if hostData?.value != participantStats {
                        AudioRoomParticipantStatsView(stats: participantStats, name: participantStats.username)
                    }
                }

                Rectangle()
                    .fill(Color("BackgroundGray"))
                    .frame(height: 1)
                DebugDataRow(title: "SDK version", value: debugData.sdkVersion)
            }
        }
    }
}

struct DebugDataRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
                .font(Constants.fRobotoMonoMedium18)
                .foregroundColor(Color("debugViewKeys"))
            Spacer()
            Text(value)
                .font(Constants.fRobotoMonoMedium18)
                .foregroundColor(.black)
        }
    }
}

struct VideoRoomParticipantStatsView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var stats: DebugStats
    var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(name) details")
                .font(Constants.fInterBold14)
                .foregroundColor(.black)
            Rectangle()
                .fill(Color("BackgroundGray"))
                .frame(height: 1)
            DebugDataRow(title: "Latency (roundtrip)", value: stats.medianLatency ?? "-")
            DebugDataRow(title: "FPS", value: stats.fps ?? "-")
            DebugDataRow(title: "Packets lost", value: stats.packetLossDown ?? "-")
        }
        .padding(.top, 12)
    }
}

struct AudioRoomParticipantStatsView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var stats: DebugStats
    var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(name) details")
                .font(Constants.fInterBold14)
                .foregroundColor(.black)
            Rectangle()
                .fill(Color("BackgroundGray"))
                .frame(height: 1)
            DebugDataRow(title: "Latency (roundtrip)", value: stats.medianLatency ?? "-")
            DebugDataRow(title: "Packets lost", value: stats.packetLossDown ?? "-")
        }
        .padding(.top, 16)
    }
}
