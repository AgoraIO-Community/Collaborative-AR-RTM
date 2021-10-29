//
//  SatelliteEntity.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 26/10/2021.
//

import Foundation
import RealityKit
import RealityUI
import Combine

class SatelliteEntity: Entity, HasClick {
    var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = { clicked, pos in
        guard let globeEnt = clicked as? SatelliteEntity else { return }
        CollaborationExpEntity.shared.clickedChannelData = ChannelData(
            channelName: "AWE Special Room", channelID: "awe-special",
            position: .zero, systemImage: "star.circle", channelType: "AWE",
            isSpecial: true
        )
    }
    var satelliteModel = SatelliteModel()
    required init() {
        super.init()
        self.name = "satellite"
        self.setSatelliteModel()
    }
    func setSatelliteModel() {
        self.addChild(self.satelliteModel)
        self.satelliteModel.scale = .one

        var cancellable: Cancellable?
        cancellable = Entity.loadModelAsync(named: "Satellite_low_poly").sink(receiveCompletion: { compl in
            switch compl {
            case .finished: break
            case .failure(_):
                cancellable?.cancel()
            }
        }, receiveValue: { loadedModel in
            self.satelliteModel.model = loadedModel.model
            if let bounds = loadedModel.model?.mesh.bounds {
                let endScale = 0.25 / bounds.boundingRadius
                self.scale = .init(repeating: endScale)
                print("endscale = \(self.scale)")
                self.satelliteModel.position = [1 / endScale, -bounds.center.y * endScale, 0]
                var cancScale: Cancellable?
                self.satelliteModel.scale = .zero
                self.satelliteModel.move(
                    to: Transform(
                        scale: .one, rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                        translation: [1 / endScale, -bounds.center.y * endScale, 0]),
                    relativeTo: self, duration: 1
                )
                cancScale = self.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: self.satelliteModel, { _ in
                    self.satelliteModel.ruiSpin(by: [0, 1, 0], period: 15)
//                    print(self.satelliteModel.visualBounds(relativeTo: nil))
//                    print(self.satelliteModel.position)
                    cancScale?.cancel()
                })
                self.ruiSpin(by: [0, -1, 0], period: 12)
//                self.satelliteModel.model = ModelComponent(mesh: .generateSphere(radius: 1 / endScale), materials: [])
                self.satelliteModel.collision = CollisionComponent(shapes: [
                    .generateSphere(radius: 0.3 / endScale)
                ])
            }
        })

    }
}

class SatelliteModel: Entity, HasClick, HasModel {
    var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = { clicked, pos in
        guard let parentSatellite = clicked.parent as? SatelliteEntity else { return }
        parentSatellite.tapAction?(parentSatellite, pos)
    }

}
