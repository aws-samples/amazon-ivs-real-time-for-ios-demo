//
//  VoteBarView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 25/04/2023.
//

import SwiftUI

struct VoteBarView: View {
    @EnvironmentObject var appModel: AppModel

    @State private var voteBarOpacity: Double = 0.1
    @State private var voteOffset: CGFloat = 0
    @State private var hostFlareHidden = false
    @State private var participantFlareHidden = false

    private let leftColor = Color("ProgressBarRed")
    private let rightColor = Color("ProgressBarBlue")

    private var votesDiff: CGFloat {
        return CGFloat(appModel.votesCountHost - appModel.votesCountParticipant) * 8
    }

    var body: some View {
        ZStack {
            ZStack(alignment: .center) {
                HStack(spacing: 0) {
                    leftColor
                        .onChange(of: appModel.votesCountHost) { _ in
                            withAnimation {
                                hostFlareHidden = appModel.votesCountHost < appModel.votesCountParticipant
                                participantFlareHidden = appModel.votesCountHost > appModel.votesCountParticipant
                            }
                        }
                    rightColor
                        .onChange(of: appModel.votesCountParticipant) { _ in
                            withAnimation {
                                hostFlareHidden = appModel.votesCountHost < appModel.votesCountParticipant
                                participantFlareHidden = appModel.votesCountHost > appModel.votesCountParticipant
                            }
                        }
                }

                SparksView(voteOffset: $voteOffset)
                    .position(x: UIScreen.main.bounds.width * 0.75, y: 20)
                    .overlay {
                        HStack(spacing: 0) {
                            Image("radial_l")
                                .resizable()
                                .frame(height: 20)
                                .overlay {
                                    Rectangle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [.clear, .white]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                }
                                .opacity(hostFlareHidden ? 0 : 1)
                            Image("radial_r")
                                .resizable()
                                .frame(height: 20)
                                .overlay {
                                    Rectangle()
                                        .fill(LinearGradient(
                                                gradient: Gradient(colors: [.white, .clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                        ))
                                }
                                .opacity(participantFlareHidden ? 0 : 1)
                        }
                        .opacity(voteBarOpacity)
                        .onAppear {
                            voteBarOpacity = 0.4
                        }
                    }
            }
            .overlay {
                JitterView(count: 12, width: 10)
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: 20)
        .offset(x: voteOffset)
        .animation(.linear, value: voteOffset)
        .onChange(of: appModel.votesCountHost) { _ in
            withAnimation {
                voteOffset = min(UIScreen.main.bounds.width / 2, votesDiff)
            }
        }
        .onChange(of: appModel.votesCountParticipant) { _ in
            withAnimation {
                voteOffset = max(-UIScreen.main.bounds.width / 2, votesDiff)
            }
        }
        .background(
            HStack(spacing: 0) {
                leftColor
                rightColor
            }
        )
        .onAppear {
            voteOffset = min(UIScreen.main.bounds.width / 2, votesDiff)
            hostFlareHidden = appModel.votesCountHost < appModel.votesCountParticipant
            participantFlareHidden = appModel.votesCountHost > appModel.votesCountParticipant
        }
    }
}

struct SparksView: View {
    @State private var offset: CGFloat = 0
    @State private var particleSystem = ParticleSystem()
    @State private var id: Int = 0
    @Binding var voteOffset: CGFloat

    let sparkImageCount = 5
    let animationTime = 0.3
    let width: CGFloat = 100
    let height: CGFloat = 12

    private var isLowerThanIphone12: Bool {
        let modelCode = getDeviceCode()?
            .filter({ "0123456789.,".contains($0) })
            .replacingOccurrences(of: ",", with: ".") ?? ""
        if let code = Double(modelCode) {
            return code < 13
        }
        return false
    }

    private func getDeviceCode() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { pointer in
                String.init(validatingUTF8: pointer)
            }
        }
        return modelCode
    }

    var body: some View {
        if isLowerThanIphone12 {
            HStack(spacing: 0) {
                ZStack {
                    ForEach(0...sparkImageCount, id: \.self) { index in
                        Image("sparks_tile_l")
                            .resizable()
                            .frame(width: width, height: height)
                            .position(x: (width / 2) - offset)
                            .opacity(offset)
                            .animation(.easeInOut(duration: animationTime)
                                .delay(animationTime / Double(index))
                                .repeatForever(autoreverses: false), value: offset)
                    }
                }

                ZStack {
                    ForEach(0...sparkImageCount, id: \.self) { index in
                        Image("sparks_tile_r")
                            .resizable()
                            .frame(width: width, height: height)
                            .position(x: (-width / 2) + offset)
                            .opacity(offset)
                            .animation(.easeInOut(duration: animationTime)
                                .delay(animationTime / Double(index))
                                .repeatForever(autoreverses: false), value: offset)
                    }
                }
            }
            .task {
                withAnimation {
                    offset = 59
                }
            }
            .onChange(of: voteOffset) { _ in
                withAnimation {
                    offset = 0
                    id += 1
                }
            }
            .id(id)
            .transition(.opacity)
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    particleSystem.update(to: timeline.date)
                    context.blendMode = .xor
                    context.opacity = 0.0

                    let randomSize = CGFloat.random(in: 3...7)
                    let shape = Capsule().size(
                        CGSize(width: randomSize, height: 2)
                    )

                    for particle in particleSystem.particles {
                        let age = timeline.date.distance(to: particle.removalDate)
                        var rect = CGRect.zero
                        if particle.direction == .left {
                            rect = CGRect(
                                x: (size.width * age * particle.speed),
                                y: particle.y * size.height,
                                width: size.width,
                                height: 5)
                        } else {
                            rect = CGRect(
                                x: size.width - (size.width * age * particle.speed),
                                y: particle.y * size.height,
                                width: size.width,
                                height: 5)
                        }
                        context.opacity = age - 0.2
                        context.fill(shape.path(in: rect), with: .color(Color.white))
                    }
                }
                .frame(height: 20)
                .position(x: UIScreen.main.bounds.width / 4, y: 0)
            }
        }
    }
}

class ParticleSystem {
    var particles = Set<Particle>()
    var lastDirection: Particle.Direction = .left

    func update(to date: Date) {
        particles = particles.filter { $0.removalDate > date }
        particles.insert(Particle(y: Double.random(in: 0.1...0.6),
                                  removalDate: date + 0.6,
                                  speed: 0.8,
                                  direction: lastDirection == .left ? .right : .left))
        lastDirection = lastDirection == .left ? .right : .left
    }
}

struct Particle: Hashable {
    enum Direction {
        case left, right
    }
    var y: Double
    var removalDate: Date
    var speed: Double
    var direction: Direction
}
