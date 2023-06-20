//
//  PKView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import SwiftUI

struct PKView: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var stage: Stage

    @State private var timeRemaining: Int = 0
    @State private var timerIsRunning = false
    @State private var timer: Timer?

    private let votingSessionDuration: Double = 30

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                VStack(alignment: .leading, spacing: 2) {

                    ZStack(alignment: .bottom) {
                        HStack(spacing: 2) {
                            ZStack {
                                if let participant = appModel.activeStageHostParticipant {
                                    participant.previewView
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width/2)
                            .frame(maxHeight: .infinity)
                            .background(
                                Color("BackgroundDark")
                                    .overlay {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                    }
                            )

                            ZStack {
                                if let participant2 = appModel.activeStageSecondParticipant {
                                    participant2.previewView
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width/2)
                            .frame(maxHeight: .infinity)
                            .background(
                                Color("BackgroundDark")
                                    .overlay {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                    }
                            )
                        }
                        .frame(height: 294)
                        .overlay {
                            JitterView(count: 10)
                        }

                        if appModel.votingSessionIsActive {
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 54, height: 22)
                                .opacity(0.89)
                                .overlay(
                                    Text("00:\(timeRemaining < 10 ? "0" : "")\(timeRemaining)")
                                        .font(Constants.fInterMedium14)
                                        .foregroundColor(.white)
                                )
                                .padding(2)
                                .transition(.opacity)
                        }
                    }

                    VoteBarView()
                        .padding(.bottom, 20)
                }

                Image("PK")
                    .resizable()
                    .frame(width: 84, height: 84)
            }
            .offset(y: -120)
        }
        .background(
            Image("PK_BG")
                .resizable()
                .frame(width: UIScreen.main.bounds.width,
                       height: UIScreen.main.bounds.height - appModel.activeStageBottomSpace)
        )
        .task {
            DispatchQueue.main.async {
                checkActiveVotingSession()
                startTimer()
            }
        }
        .onChange(of: appModel.votingSessionStartedAt) { _ in
            checkActiveVotingSession()
        }
        .onDisappear {
            stopTimer()
            appModel.pkVotingWinVisualsActive = false
        }
    }

    private func checkScores() {
        withAnimation {
            appModel.votingSessionIsActive = false
            if appModel.votesCountHost != appModel.votesCountParticipant {
                appModel.pkVotingWinVisualsActive = true
            }
        }
        stopTimer()
    }

    private func checkActiveVotingSession() {
        if let startedAt = appModel.votingSessionStartedAt {
            print("ℹ voting did start")
            let elapsedTime = startedAt.timeIntervalSinceNow
            appModel.votingSessionIsActive = votingSessionDuration + elapsedTime <= votingSessionDuration
            timeRemaining = Int((votingSessionDuration - elapsedTime).rounded(.down))
            if !timerIsRunning {
                startTimer()
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            if timeRemaining < 1 {
                checkScores()
            } else if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
        timerIsRunning = true
    }

    private func stopTimer() {
        timer?.invalidate()
        timerIsRunning = false
    }
}

struct PKView_Previews: PreviewProvider {
    static let appModel = AppModel()

    static var previews: some View {
        PKView(
            stage: Stage(id: "123",
                         stageArn: "testArn",
                         hostId: "Test",
                         type: .video,
                         mode: .pk,
                         status: "ACTIVE",
                         seats: nil)
        )
        .environmentObject(appModel)
    }
}
