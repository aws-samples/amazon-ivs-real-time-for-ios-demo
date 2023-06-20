//
//  DebugView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 12/05/2023.
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var appModel: AppModel
    @Binding var isPresent: Bool
    @ObservedObject var stageModel: StageModel
    @State private var YOffset: CGFloat = 200
    @State private var backOpacity: CGFloat = 0.8

    func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            YOffset = 200
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            backOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresent.toggle()
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(backOpacity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }

            ZStack(alignment: .top) {
                Color("BackgroundWhite")
                    .cornerRadius(30)
                    .edgesIgnoringSafeArea(.bottom)

                VStack {
                    VStack(spacing: 12) {
                        Text("Local debug data")
                            .font(Constants.fInterExtraBold22)
                            .foregroundColor(.black)

                        Text("Copy to clipboard for all available debug data")
                            .font(Constants.fInterRegular14)
                            .foregroundColor(Color("BackgroundDark"))
                    }
                    .padding(.bottom, 10)

                    DebugDataView(user: appModel.user, debugData: stageModel.debugData)

                    Button(action: {
                        var clipboardString = ""
                        for stats in stageModel.debugData.participantStats {
                            clipboardString += stats.value.clipboardString
                        }
                        UIPasteboard.general.setValue(clipboardString,
                                                      forPasteboardType: "public.plain-text")
                    }, label: {
                        Text("Copy to clipboard")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    })
                    .modifier(PrimaryButton(color: Color("BackgroundGray")))
                    .padding(.top, 4)

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Dismiss")
                            .frame(height: 50)
                    }
                    .modifier(PrimaryButton(color: .clear))
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
            .frame(maxHeight: 700)
            .offset(y: YOffset)
            .fixedSize(horizontal: false, vertical: true)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                YOffset = 0
            }
        }
    }
}
