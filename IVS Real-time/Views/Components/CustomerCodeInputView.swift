//
//  CustomerCodeInputView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI
import CodeScanner

struct CustomerCodeInputView: View {
    @EnvironmentObject var appModel: AppModel

    @Binding var isPresent: Bool
    @Binding var inputText: String

    var submitAction: () -> Void

    @State private var isQRScannerPresent: Bool = false
    @State private var inputBorderColor: Color = Color("BackgroundGray")
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

    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(backOpacity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }

            VStack {
                ZStack(alignment: .top) {
                    Color("BackgroundWhite")
                        .cornerRadius(30)
                        .edgesIgnoringSafeArea(.bottom)
                        .allowsHitTesting(false)

                    VStack {
                        Text("Authentication code")
                            .font(Constants.fInterExtraBold22)
                            .foregroundColor(.black)
                            .padding(.top, 30)
                            .padding(.bottom, 20)

                        HStack {
                            CustomTextField(text: $inputText,
                                            background: .white) {
                                submitAction()
                            }
                                            .placeholder(when: inputText.isEmpty) {
                                                Text("Paste your code here...")
                                                    .foregroundColor(.gray)
                                            }
                                            .cornerRadius(100)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 100)
                                                    .stroke(inputBorderColor, lineWidth: 2)
                                            )
                                            .padding(.vertical, 20)

                            Button(action: {
                                dismissKeyboard()
                                withAnimation {
                                    isQRScannerPresent.toggle()
                                }
                            }) {
                                Image("qr")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                            }
                            .frame(width: 56, height: 46)
                            .background {
                                Rectangle()
                                    .fill(Color("BackgroundGray"))
                                    .cornerRadius(40)
                            }
                        }

                        Button(action: {
                            dismissKeyboard()
                            submitAction()
                        }) {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .modifier(PrimaryButton())
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 200)
            }
            .offset(y: YOffset)

            if isQRScannerPresent {
                ScannerView(isPresent: $isQRScannerPresent, inputText: $inputText, successfulScanAction: {
                    submitAction()
                })
            }
        }
        .transition(.opacity)
        .onAppear {
            isQRScannerPresent = false
            withAnimation(.easeOut(duration: 0.3)) {
                YOffset = 0
            }
        }
        .onDisappear {
            dismissKeyboard()
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .onChange(of: appModel.errorMessages) { _ in
            inputBorderColor = appModel.errorMessages.isEmpty ? Color("BackgroundGray") : Color("Red")
        }
    }
}

struct ScannerView: View {
    @Binding var isPresent: Bool
    @Binding var inputText: String
    var successfulScanAction: () -> Void

    private func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
            case .success(let result):
                guard result.string.split(separator: "-").count >= 2 else {
                    return
                }
                inputText = result.string
                successfulScanAction()
            case .failure(let error):
                print("ℹ ❌ QR code scanning failed: \(error)")
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .edgesIgnoringSafeArea(.all)

            CodeScannerView(codeTypes: [.qr], scanMode: .oncePerCode, completion: handleScan)
                .edgesIgnoringSafeArea(.all)
                .overlay {
                    ZStack(alignment: .top) {
                        Color.black
                            .opacity(0.4)
                            .reverseMask({
                                Rectangle()
                                    .frame(width: 275, height: 275)
                            })
                            .overlay {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(width: 275, height: 275)
                                    .overlay {
                                        Rectangle()
                                            .stroke(Color("Green"),
                                                    style: StrokeStyle(lineWidth: 3.0,
                                                                       lineCap: .round,
                                                                       lineJoin: .bevel,
                                                                       dash: [60, 215],
                                                                       dashPhase: 29)
                                            )
                                    }
                            }

                        HStack {
                            Button(action: {
                                withAnimation {
                                    isPresent.toggle()
                                }
                            }) {
                                Image("arrow-small-left")
                                    .padding(.all, 16)
                            }
                            .padding(.trailing, 8)

                            Spacer()

                            Text("Log in with QR code")
                                .font(Constants.fInterBold22)
                                .foregroundColor(.white)

                            Spacer()
                            Spacer()
                        }
                        .padding(.top, 44)
                        .padding(.bottom, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .edgesIgnoringSafeArea(.all)
                }
        }
        .transition(.opacity)
    }
}
