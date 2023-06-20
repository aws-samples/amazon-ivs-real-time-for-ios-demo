//
//  AudioStageView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct AudioStageView: View {
    @EnvironmentObject var appModel: AppModel
    @StateObject var stage: Stage
    @State var stageSeatRows: [StageSeatRow] = []

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                ForEach(stageSeatRows) { row in
                    HStack {
                        ForEach(row.seats) { seat in
                            let participantId = stage.participantIdForSeat(at: seat.index)
                            if let participant = appModel.stageModel.dataForParticipant(participantId) {
                                TakenSeat(seat: seat, user: participant)
                            } else {
                                EmptySeat(seat: seat, stage: stage)
                            }
                        }
                    }
                }
            }
            .offset(y: -120)
        }
        .edgesIgnoringSafeArea(.top)
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - appModel.activeStageBottomSpace)
        .background(
            Image("AUDIO_STAGE_BG")
                .resizable()
        )
        .cornerRadius(30)
        .overlay {
            StageOverlayView(stage: stage)
        }
        .onAppear {
            setSeats()
        }
    }

    func setSeats() {
        stageSeatRows = []
        var index: Int = 0
        for _ in 0...2 {
            var seats: [StageSeat] = []
            for _ in 0...3 {
                seats.append(StageSeat(index: index,
                                       participantId: stage.participantIdForSeat(at: index)))
                index += 1
            }
            let row = StageSeatRow(seats: seats)
            stageSeatRows.append(row)
            seats = []
        }
    }
}

struct EmptySeat: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var seat: StageSeat
    @ObservedObject var stage: Stage

    var body: some View {
        ZStack {
            if stage.participantIdForSeat(at: seat.index).isEmpty {
                Button {
                    if appModel.user.isHost { return }

                    if appModel.user.isOnStage {
                        appModel.changeSeat(to: seat.index)
                    } else {
                        appModel.publishToAudioStage(inAudioSeat: seat.index)
                    }
                } label: {
                    Image("PlusOutline")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
            } else {
                ProgressView()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color.clear)
                .frame(width: 80, height: 94)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 1)
                }
                .colorScheme(.light)
        )
        .frame(width: 80, height: 94)
    }
}

struct TakenSeat: View {
    @ObservedObject var seat: StageSeat
    @ObservedObject var user: User

    var body: some View {
        ZStack {
            ZStack {
                AvatarView(avatar: user.avatar,
                           withBorder: true,
                           borderColor: user.isSpeaking ? Color("Orange") : .white,
                           size: 60)

                if user.audioMuted {
                    ZStack {
                        Circle()
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image("microphone-slash")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(Color("Red"))
                                    .frame(width: 15, height: 15)
                            }
                    }
                    .offset(x: 15, y: 15)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color.clear)
                .frame(width: 80, height: 94)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 1)
                }
                .colorScheme(.light)
        )
        .frame(width: 80, height: 94)
    }
}
