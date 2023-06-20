//
//  IVSImagePreviewViewWrapper.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 31/03/2023.
//

import SwiftUI
import AmazonIVSBroadcast

struct IVSImagePreviewViewWrapper: UIViewRepresentable {
    let previewView: IVSImagePreviewView?

    func makeUIView(context: Context) -> IVSImagePreviewView {
        guard let view = previewView else {
            fatalError("No actual IVSImagePreviewView passed to wrapper")
        }
        return view
    }

    func updateUIView(_ uiView: IVSImagePreviewView, context: Context) {}
}
