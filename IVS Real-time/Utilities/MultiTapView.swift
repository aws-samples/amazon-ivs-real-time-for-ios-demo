//
//  MultiTapView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 13/04/2023.
//

import SwiftUI

struct MultiTapView: UIViewRepresentable {
    var tappedCallback: (() -> Void)

    func makeUIView(context: UIViewRepresentableContext<MultiTapView>) -> MultiTapView.UIViewType {
        let view = UIView(frame: .zero)
        let gesture = FingerGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        view.addGestureRecognizer(gesture)
        return view
    }

    class Coordinator: NSObject {
        var tappedCallback: (() -> Void)

        init(tappedCallback: @escaping (() -> Void)) {
            self.tappedCallback = tappedCallback
        }

        @objc func tapped(gesture: FingerGestureRecognizer) {
            self.tappedCallback()
        }
    }

    func makeCoordinator() -> MultiTapView.Coordinator {
        return Coordinator(tappedCallback: self.tappedCallback)
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<MultiTapView>) {}
}

class FingerGestureRecognizer: UIGestureRecognizer {
    var startTime: Date?
    var timer: Timer?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        startTime = Date()
        if numberOfTouches == 2 {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
                self.state = .ended
            })
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        timer?.invalidate()
    }
}
