//
//  GlobeEntity.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 01/06/2021.
//

import Foundation
import RealityKit
import Combine
import RealityUI

class GlobeEntity: Entity, HasAnchoring, HasClick {
    var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = { clicked, pos in
        guard let globeEnt = clicked as? GlobeEntity, let clickedPos = pos else { return }
        var globeRadius: Float = 0.5// globeEnt.globeModel.visualBounds(relativeTo: globeEnt).boundingRadius
        let collabPosition = globeEnt.globeModel.convert(position: clickedPos, from: nil).setLength(to: globeRadius * 1.02)
        globeEnt.tempClickedEntity.position = collabPosition
        CollaborationExpEntity.shared.clickedChannelData = ChannelData(
            channelName: "testName", channelID: "new", position: collabPosition
        )
        globeEnt.globeModel.addChild(globeEnt.tempClickedEntity)
    }

    lazy var tempClickedEntity: ModelEntity = {
        return ModelEntity(
            mesh: .generateSphere(radius: 0.04),
            materials: [SimpleMaterial(color: .green, isMetallic: false)]

        )
    }()

    var globeModel = ModelEntity()
    required init() {
        super.init()
        self.name = "globe"
        self.setGlobeModel()
    }
    func setGlobeModel() {
        self.addChild(self.globeModel)
        self.globeModel.scale = .zero

        var cancellable: Cancellable?
        cancellable = Entity.loadModelAsync(named: "globe").sink(receiveCompletion: { compl in
            switch compl {
            case .finished: break
            case .failure(_):
                cancellable?.cancel()
            }
        }, receiveValue: { loadedModel in
            self.globeModel.model = loadedModel.model
        })

    }
    func spawnEarth() {
        var cancellable: Cancellable?
        var earthTransform = self.globeModel.transform
        let globeRadius: Float = 0.5
        #if os(iOS) && !targetEnvironment(simulator)
        earthTransform.translation.y = 1 / 2
        #endif
        earthTransform.rotation = simd_quatf(angle: .pi / 3, axis: [0, -1, 0])
        earthTransform.scale = .one / 1.5
        cancellable = self.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: self.globeModel, { animEvent in
            DispatchQueue.main.async {
                cancellable?.cancel()
                self.globeModel.ruiSpin(by: [0, -1, 0], period: 24)
                self.collision = CollisionComponent(
                    shapes: [.generateSphere(radius: earthTransform.scale[0] * globeRadius).offsetBy(
                              translation: self.globeModel.position
                    )]
                )
            }
        })
        self.globeModel.move(to: earthTransform, relativeTo: self, duration: 1, timingFunction: .linear)
//        for _ in 0...6 {
//            var collabLoc = SIMD3<Float>.random(in: -1...1).setLength(to: 1.02)
//            self.spawnHitpoint(channelData: ChannelData(channelName: "test", channelID: "uid3", position: collabLoc))
//        }
    }

    func spawnHitpoint(channelData: ChannelData) {
        let hp = TapSpot { hitEntity, hitPos in
            self.tempClickedEntity.removeFromParent()
            CollaborationExpEntity.shared.showCardFor(channelData: channelData)
        }
        hp.scale = .init(repeating: 0.3)
//        hp.look(at: position * 2, from: position, relativeTo: nil)
        hp.look(at: .zero, from: channelData.position, relativeTo: nil)
        self.globeModel.addChild(hp)
    }
}

