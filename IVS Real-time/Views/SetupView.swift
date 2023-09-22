//
//  SetupView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appModel: AppModel
    @State var isSettingsPresent: Bool = false
    @State var isStageSelectionPresent: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color("BackgroundWhite")
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                HStack {
                    Button(action: {
                        appModel.generateRandomUsername()
                    }) {
                        Image("arrow-path")
                            .padding(.all, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(30)
                    }
                    .padding(.trailing, 8)

                    Text(appModel.username)
                        .font(Constants.fRobotoMonoBold)
                        .foregroundColor(.black)

                    Spacer()

                    Button {
                        withAnimation {
                            isSettingsPresent.toggle()
                        }
                    } label: {
                        Image("cog-6-tooth")
                            .renderingMode(.template)
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 8)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("IVS")
                        .font(Constants.fInterBlack36)
                        .foregroundColor(.black)
                    Text("Real-time")
                        .foregroundColor(Color("Orange"))
                        .font(Constants.fInterBlack36)
                }
                .padding(.bottom, 40)

                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation {
                            isStageSelectionPresent.toggle()
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text("")
                                .frame(maxWidth: .infinity)
                            Text("Create new stage")
                                .foregroundColor(.black)
                                .font(Constants.fInterExtraBold22)
                                .padding(.top, 50)
                                .padding(.bottom, 1)
                                .frame(alignment: .leading)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 30)
                        .background(
                            Color("Orange")
                        )
                        .cornerRadius(20)
                    }

                    Button {
                        withAnimation {
                            appModel.isSetupCompleted.toggle()
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text("")
                                .frame(maxWidth: .infinity)
                            Text("Join stage (feed view)")
                                .font(Constants.fInterExtraBold22)
                                .foregroundColor(.black)
                                .padding(.top, 50)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 30)
                        .background(
                            LinearGradient(colors: [Color("Gradient1"), Color("Gradient2")],
                                           startPoint: .top,
                                           endPoint: .bottom)
                        )
                        .cornerRadius(20)
                    }
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)

            if isSettingsPresent {
                SettingsView(isPresent: $isSettingsPresent)
            }

            if isStageSelectionPresent {
                BottomSheetConfirmationView(
                    isPresent: $isStageSelectionPresent,
                    title: "Select experience",
                    contentHeight: 250,
                    contentView:
                        VStack {
                            Button(action: {
                                withAnimation {
                                    isStageSelectionPresent.toggle()
                                }
                                appModel.createStage(.video)
                            }) {
                                Text("Video stage")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .modifier(PrimaryButton(color: Color("BackgroundGray")))

                            Button(action: {
                                withAnimation {
                                    isStageSelectionPresent.toggle()
                                }
                                appModel.createStage(.audio)
                            }) {
                                Text("Audio room")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .modifier(PrimaryButton(color: Color("BackgroundGray")))
                        }
                )
            }
        }
    }
}
