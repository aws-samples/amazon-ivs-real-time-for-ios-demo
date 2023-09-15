//
//  IVSRealTimeApp.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

@main
struct IVSRealTimeApp: App {
    @ObservedObject var appModel: AppModel = AppModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ZStack(alignment: .top) {
                    if !appModel.isConnected {
                        WelcomeView()
                            .transition(.move(edge: .leading))
                            .preferredColorScheme(.light)
                    }

                    if appModel.isConnected && !appModel.isSetupCompleted {
                        SetupView()
                            .transition(!appModel.isSetupCompleted ? .opacity : .move(edge: .trailing))
                            .preferredColorScheme(.light)
                    }

                    NavigationLink(
                        destination: FeedsView(stagesModel: appModel.stagesModel,
                                               stageModel: appModel.stageModel)
                            .environmentObject(appModel)
                            .preferredColorScheme(.dark),
                        isActive: $appModel.isSetupCompleted
                    ) { EmptyView() }

                    if appModel.isLoading {
                        LoadingView()
                    }

                    ErrorView()
                }
                .environmentObject(appModel)
                .onFirstAppear {
                    checkAVPermissions { granted in
                        if !granted {
                            appModel.appendErrorMessage("No camera/microphone permission granted")
                        }

                        if UserDefaults.standard.string(forKey: Constants.kCustomerCode) != nil {
                            appModel.verify(silent: true) { _ in }
                        }
                    }
                }
                .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
        }
    }
}
