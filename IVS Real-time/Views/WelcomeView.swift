//
//  WelcomeView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appModel: AppModel
    @State var isCodeInputPresent = false
    @State var customerCodeInput: String = ""

    private func setCustomerCodeAndApiKey() {
        print("ℹ scanned qr '\(customerCodeInput)'")
        let codeParts = customerCodeInput.split(separator: "-")
        var customerCode: String?
        var apiKey: String?
        if codeParts.count == 2 {
            customerCode = codeParts.first.map { String($0) }
            apiKey = codeParts.last.map { String($0) }
        } else {
            appModel.appendErrorMessage("Invalid code")
            return
        }

        guard let customerCode = customerCode, let apiKey = apiKey else { return }
        print("ℹ Entered customer code: '\(customerCode)', api key: '\(apiKey)'")

        UserDefaults.standard.set(customerCode.lowercased(), forKey: Constants.kCustomerCode)
        UserDefaults.standard.set(apiKey, forKey: Constants.kApiKey)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Image(decorative: "APP_BG")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                Text("Welcome to")
                    .font(Constants.fInterBlack42)
                    .foregroundColor(.black)
                Text("IVS Real-time")
                    .font(Constants.fInterBlack42)
                    .foregroundColor(.black)
                    .padding(.bottom, 60)

                Button(action: {
                    withAnimation {
                        isCodeInputPresent = true
                    }
                }) {
                    Text("Get started")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .modifier(PrimaryButton(color: .white, font: Constants.fInterExtraBold18))
            }
            .padding(.horizontal, 16)

            if isCodeInputPresent {
                CustomerCodeInputView(
                    isPresent: $isCodeInputPresent,
                    inputText: $customerCodeInput,
                    submitAction: {
                        if customerCodeInput.isEmpty {
                            appModel.appendErrorMessage("Invalid code")
                            return
                        }

                        setCustomerCodeAndApiKey()

                        appModel.verify { _ in }
                    }
                )
                .onTapGesture {
                    withAnimation {
                        isCodeInputPresent.toggle()
                    }
                }
            }
        }
        .onAppear {
            if let customerCode = UserDefaults.standard.string(forKey: Constants.kCustomerCode),
               let apiKey = UserDefaults.standard.string(forKey: Constants.kApiKey) {
                customerCodeInput = customerCode + "-" + apiKey
            }

            withAnimation(.easeOut.delay(0.3)) {
                isCodeInputPresent = appModel.wasConnected
            }
        }
    }
}
