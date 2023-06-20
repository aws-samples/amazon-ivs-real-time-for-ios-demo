//
//  ErrorView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 03/04/2023.
//

import SwiftUI

struct ErrorView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        if !appModel.errorMessages.isEmpty {
            VStack {
                ForEach(appModel.errorMessages, id: \.self) { message in
                    Text(message)
                        .padding(15)
                        .font(Constants.fInterBold15)
                        .foregroundColor(.white)
                        .frame(minHeight: 60)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("Red"))
                        .cornerRadius(20)
                        .padding(.top, 10)
                        .padding(.horizontal, 8)
                        .shadow(color: Color("Red"), radius: 16)
                        .onTapGesture {
                            appModel.removeErrorMessage(message)
                        }
                }
            }
        }
    }
}
