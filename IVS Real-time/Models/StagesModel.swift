//
//  StagesModel.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 29/03/2023.
//

import SwiftUI

enum Direction {
    case up, down
}

protocol StagesModelDelegate: AnyObject {
    func activeStageChanged(to stage: Stage?)
}

class StagesModel: ObservableObject {
    var delegate: StagesModelDelegate?

    @Published private(set) var stages: [Stage] = []
    @Published private(set) var activeStage: Stage?

    private var canScrollAgain: Bool = true

    // Scrollable feed

    func detectScrolling(_ translation: CGSize) {
        guard canScrollAgain else { return }

        let translationThreshold: Double = 50

        switch (translation.width, translation.height) {
            case let (_, height) where height > translationThreshold:
                scroll(.down)

            case let (_, height) where height < -translationThreshold:
                scroll(.up)

            default:
                break
        }
    }

    func scroll(_ direction: Direction) {
        if stages.count < 2 { return }

        canScrollAgain = false

        switch direction {
            case .up:
                let element = stages.removeFirst()
                stages.append(element)
            case .down:
                let element = stages.removeLast()
                stages.insert(element, at: 0)
        }

        setActiveStage()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.canScrollAgain = true
        }
    }

    func setActiveStage() {
        self.activeStage = self.stages.first
        delegate?.activeStageChanged(to: self.activeStage)
    }

    func clearStages() {
        stages = []
    }

    func scrollTo(_ stage: Stage) {
        if stages.count < 2 { return }

        let currentIndex = stages.firstIndex(of: stage) ?? 0
        if currentIndex != 0 {
            stages.remove(at: currentIndex)
            stages.insert(stage, at: 0)
            setActiveStage()
        }
    }

    func setNewStages(_ stageDetails: [StageDetails]) {
        if stageDetails.isEmpty {
            stages = []
            return
        }

        let details = stageDetails.sorted { (lhs: StageDetails, rhs: StageDetails) -> Bool in
            return lhs.createdAt.localizedStandardCompare(rhs.createdAt) == .orderedAscending
        }

        // Update existing stages with new details
        for detail in details {
            let stage = Stage(id: detail.createdAt,
                              stageArn: detail.stageArn,
                              hostId: detail.hostId,
                              type: detail.type,
                              mode: detail.mode,
                              status: detail.status,
                              seats: detail.seats,
                              createdAt: detail.createdAt)

            let matchingStage = stages.first(where: { $0.hostId == stage.hostId })
            if let matchingStage = matchingStage {
                matchingStage.type = stage.type
                matchingStage.mode = stage.mode
                matchingStage.status = stage.status
                matchingStage.audioSeats = stage.audioSeats
            } else {
                stages.append(stage)
            }
        }

        // Remove inactive stages
        var inactiveStageIds: [String] = []
        let updatedStageIds = stageDetails.map { $0.hostId }
        stages.forEach { stage in
            if !updatedStageIds.contains(stage.hostId) {
                inactiveStageIds.append(stage.hostId)
            }
        }
        inactiveStageIds.forEach { id in
            if let index = stages.firstIndex(where: { $0.hostId == id }) {
                stages.remove(at: index)
            }
        }

        // In case of only 2 stages - for the scrolling animation to work, we need to populate stages with copies
        if stages.count == 2, let first = stages.first, let second = stages.last {
            let firstCopy = first.copy()
            let secondCopy = second.copy()
            stages.append(firstCopy)
            stages.append(secondCopy)
        }

        setActiveStage()
    }
}
