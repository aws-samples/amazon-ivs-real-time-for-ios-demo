//
//  SettingsView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 19/09/2023.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @Binding var isPresent: Bool
    @State var bitrate: Float = 0

    var body: some View {
        BottomSheetConfirmationView(
            isPresent: $isPresent,
            title: "Settings",
            contentHeight: 400,
            dismissTitle: "Dismiss",
            contentView:
                VStack {
                    HStack {
                        Text("Simulcast")
                            .font(Constants.fRobotoMonoMedium18)
                            .foregroundColor(Color("debugViewKeys"))
                        Spacer()
                        Toggle(isOn: $appModel.isSimulcastOn) {}
                            .tint(Color("Orange"))
                    }
                    .padding(.bottom, 16)

                    HStack {
                        Text("Show video stats")
                            .font(Constants.fRobotoMonoMedium18)
                            .foregroundColor(Color("debugViewKeys"))
                        Spacer()
                        Toggle(isOn: $appModel.isStatsOn) {}
                            .tint(Color("Orange"))
                    }
                    .padding(.bottom, 16)

                    HStack {
                        Text("Maximum bitrate")
                            .font(Constants.fRobotoMonoMedium18)
                            .foregroundColor(Color("debugViewKeys"))
                        Spacer()
                        Text("\(Int(bitrate))k")
                            .font(Constants.fRobotoMonoBold18)
                            .foregroundColor(appModel.isSimulcastOn ? .gray : .black)
                    }
                    UISliderView(value: $bitrate, minValue: 100, maxValue: 900) {
                        UserDefaults.standard.setValue(Int(bitrate), forKey: Constants.kMaxBitrate)
                        appModel.updateVideoConfiguration()
                    }
                    .disabled(appModel.isSimulcastOn)

                    Rectangle()
                        .fill(Color("BackgroundGray"))
                        .frame(height: 1)
                        .padding(.top, 20)
                        .padding(.bottom, 30)

                    Button(action: {
                        withAnimation {
                            isPresent.toggle()
                        }
                        appModel.disconnect()
                    }) {
                        Text("Sign out")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .modifier(PrimaryButton(color: Color("Red"), textColor: Color.white))
                }
        )
        .onAppear {
            bitrate = Float(appModel.maxBitrate)
        }
    }
}
