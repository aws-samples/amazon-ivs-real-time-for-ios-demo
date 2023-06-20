//
//  LoadingView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 30/03/2023.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black
                .opacity(0.8)
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .controlSize(.regular)
                .tint(.white)
        }
        .transition(.opacity)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
