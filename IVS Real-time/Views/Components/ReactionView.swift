//
//  ReactionView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 11/04/2023.
//

import SwiftUI

struct ReactionView: View, Equatable, Identifiable {
    @EnvironmentObject var appModel: AppModel

    var reaction: String

    @State private var isHidden: Bool = false
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGSize = CGSize(width: 0, height: 0)

    var id: String
    var color: Color
    var offsetX: CGFloat

    init(reaction: String) {
        self.reaction = reaction
        self.id = UUID().uuidString
        self.color = Color("\([1, 2, 3, 4, 5, 6, 7, 8, 9, 10].randomElement() ?? 1)")
        self.offsetX = CGFloat.random(in: -60...(-20))
    }

    static func == (lhs: ReactionView, rhs: ReactionView) -> Bool {
        return lhs.id == rhs.id
    }

    private var animationHeight: CGFloat {
        if appModel.user.isHost {
            return appModel.activeStage?.type == .video ? 250 : 150
        }
        if appModel.user.isOnStage {
            return appModel.activeStage?.type == .video ? 300 : 200
        }
        return 100
    }

    var body: some View {
        Image(reaction)
            .resizable()
            .frame(width: 40, height: 40)
            .scaleEffect(scale)
            .opacity(opacity)
            .transition(.opacity)
            .offset(x: offsetX, y: -offsetY)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.5)) {
                    offsetY = animationHeight
                }

                withAnimation(Animation.easeInOut(duration: 0.1)) {
                    scale = CGSize(width: 1, height: 1)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(Animation.easeOut(duration: 0.4)) {
                        opacity = 0
                        offsetY = animationHeight + 30
                    }
                }
            }
    }
}
