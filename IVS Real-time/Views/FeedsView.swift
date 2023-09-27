//
//  FeedsView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct FeedsView: View {
    @EnvironmentObject var appModel: AppModel
    @ObservedObject var stagesModel: StagesModel
    @ObservedObject var stageModel: StageModel

    @State private var isStagesListEmpty: Bool = false
    @State private var temporaryYOffset: CGFloat = 0
    @State private var isDebugViewVisible: Bool = false
    @State var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea(.all)

            VStack {
                if stagesModel.stages.isEmpty && !appModel.user.isHost {
                    ZStack(alignment: .top) {
                        VStack {
                            Image("feed-spinner")
                                .resizable()
                                .frame(width: 42, height: 42)
                                .rotationEffect(Angle.degrees(isStagesListEmpty ? 360 : 0))
                                .animation(.linear(duration: 4).repeatForever(autoreverses: false),
                                           value: isStagesListEmpty)
                        }
                        .frame(width: UIScreen.main.bounds.width,
                               height: UIScreen.main.bounds.height - appModel.activeStageBottomSpace)
                        .background(
                            Color("BackgroundDark")
                        )
                        .cornerRadius(30)
                        .padding(.bottom, appModel.activeStageBottomSpace)

                        OverlayHeaderView()
                    }
                    .task {
                        isStagesListEmpty = stagesModel.stages.isEmpty
                    }
                } else {
                    ScrollViewReader { proxy in
                        ScrollView([]) {
                            LazyVStack {
                                ForEach(appModel.stagesModel.stages, id: \.id) { stage in
                                    switch stage.type {
                                        case .audio:
                                            AudioStageView(stage: stage)
                                                .offset(y: temporaryYOffset)
                                        case .video:
                                            VideoStageView(stage: stage)
                                                .offset(y: temporaryYOffset)
                                    }
                                }
                            }
                        }
                        .animation(.linear, value: appModel.stagesModel.activeStage)
                        .onAppear {
                            proxy.scrollTo(appModel.stagesModel.activeStage, anchor: .center)
                        }
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if abs(value.translation.height) > 130 && !appModel.user.isHost && !appModel.user.isOnStage {
                                        appModel.stagesModel.detectScrolling(value.translation)
                                    }
                                    withAnimation {
                                        temporaryYOffset = 0
                                    }
                                }
                                .onChanged({ value in
                                    if appModel.user.isHost || appModel.user.isOnStage { return }
                                    withAnimation {
                                        temporaryYOffset = value.translation.height
                                    }
                                })
                        )
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.vertical)
            .frame(width: UIScreen.main.bounds.width,
                   height: UIScreen.main.bounds.height - appModel.activeStageBottomSpace)
            .onChange(of: stagesModel.stages) { _ in
                isStagesListEmpty = stagesModel.stages.isEmpty
            }

            if appModel.userWantsToJoinVideoStage {
                BottomSheetConfirmationView(
                    isPresent: $appModel.userWantsToJoinVideoStage,
                    title: "Join stage as",
                    contentHeight: 250,
                    contentView:
                        VStack {
                            Button(action: {
                                appModel.publishToVideoStage(.spot)
                                appModel.userWantsToJoinVideoStage = false
                            }, label: {
                                Text("Guest spot")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            })
                            .modifier(PrimaryButton(color: Color("BackgroundGray")))

                            Button(action: {
                                appModel.publishToVideoStage(.pk)
                                appModel.userWantsToJoinVideoStage = false
                            }, label: {
                                Text("PK/VS mode")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            })
                            .modifier(PrimaryButton(color: Color("BackgroundGray")))
                        }
                )
            }

            if appModel.userWantsToLeaveStage {
                if appModel.user.isHost {
                    BottomSheetConfirmationView(
                        isPresent: $appModel.userWantsToLeaveStage,
                        title: "End stage",
                        contentView:
                            Button(action: {
                                appModel.leaveActiveStage {
                                    DispatchQueue.main.async {
                                        self.appModel.userWantsToLeaveStage = false
                                    }
                                }
                            }, label: {
                                Text("End stage for everyone")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            })
                            .modifier(PrimaryButton(color: Color("Red"), textColor: Color.white))
                    )
                } else if !appModel.isLoading {
                    BottomSheetConfirmationView(
                        isPresent: $appModel.userWantsToLeaveStage,
                        title: "Leave current \(appModel.activeStage?.type == .audio ? "room" : "stage")",
                        contentView:
                            Button(action: {
                                appModel.endPublishingToStage {}
                                appModel.userWantsToLeaveStage = false
                            }, label: {
                                Text("Leave \(appModel.activeStage?.type == .audio ? "room" : "stage")")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            })
                            .modifier(PrimaryButton(color: Color("Red"), textColor: Color.white))
                    )
                }
            }

            if appModel.hostWantsToRemoveParticipant {
                BottomSheetConfirmationView(
                    isPresent: $appModel.hostWantsToRemoveParticipant,
                    title: "Remove participant",
                    contentView:
                        Button(action: {
                            appModel.kickSecondParticipant()
                            appModel.hostWantsToRemoveParticipant = false
                        }, label: {
                            Text("Remove")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        })
                        .modifier(PrimaryButton(color: Color("Red"), textColor: Color.white))
                )
            }

            if appModel.isLoading {
                LoadingView()
            }

            ErrorView()
                .padding(.top, 20)
        }
        .onAppear {
            appModel.shouldJoinActiveStage = true

            if !appModel.user.isHost {
                appModel.getStages(completion: { _ in
                    DispatchQueue.main.async {
                        appModel.stagesModel.setActiveStage()
                        _ = timer.upstream.autoconnect()
                    }
                })
            }
        }
        .onDisappear {
            appModel.shouldJoinActiveStage = false
            timer.upstream.connect().cancel()
            appModel.cleanUp()
        }
        .onReceive(timer, perform: { _ in
            appModel.getStages { _ in }
        })
        .environmentObject(appModel)
        .navigationBarHidden(true)
        .onShake {
            if appModel.activeStage != nil {
                isDebugViewVisible.toggle()
            } else {
                print("ℹ no active stage - will not show debug stats")
            }
        }
        .overlay {
            if isDebugViewVisible {
                DebugView(isPresent: $isDebugViewVisible, stageModel: stageModel)
                .onAppear {
                    stageModel.startRTCStats()
                }
            }
        }
    }
}
