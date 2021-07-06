//
//  PeerEntity.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 15/06/2021.
//

import CoreGraphics
import RealityKit

struct PeerData: Codable {
    var rtmID: String
    var rtcID: UInt?
    var usdz: String?
    var scale: SIMD3<Float>
    var rotation: simd_float4
    var translation: SIMD3<Float>
    var colorVector: [CGFloat]
    var color: Material.Color {
        Material.Color(red: self.colorVector[0], green: self.colorVector[1], blue: self.colorVector[2], alpha: self.colorVector[3])
    }
    var transform: Transform { Transform(scale: scale, rotation: simd_quatf(vector: rotation), translation: translation)}
    var peerDataComponent: PeerDataComponent {
        PeerDataComponent(rtmID: rtmID, rtcID: rtcID, usdz: usdz)
    }
}

struct PeerDataComponent: Component, Codable {
    var rtmID: String
    var rtcID: UInt?
    var usdz: String?
}

protocol HasPeer: Entity, HasModel {
    var peer: PeerDataComponent {get set}
}

extension HasPeer {
    var peer: PeerDataComponent {
        get { self.components[PeerDataComponent.self] as! PeerDataComponent }
        set { self.components[PeerDataComponent.self] = newValue }
    }
    func update(with peerData: PeerData) {
        self.stopAllAnimations()
        if (peerData.translation - self.position).mag > 1e-5 ||
           (peerData.scale - self.scale).mag > 1e-5 ||
           (peerData.transform.rotation.vector - self.orientation.vector).mag > 1e-5 {
            self.move(to: peerData.transform, relativeTo: self.parent, duration: 0.4)
        }
        self.peer = peerData.peerDataComponent
    }
}

class PeerEntity: Entity, HasPeer {
    init(with peerData: PeerData) {
        super.init()
        self.peer = peerData.peerDataComponent
        self.name = self.peer.rtmID
        self.transform = peerData.transform
        self.model = ModelComponent(
            mesh: .generateSphere(radius: 0.15),
            materials: [SimpleMaterial(color: peerData.color, isMetallic: false)]
        )
    }

    var audioEnabled: Bool = false {
        didSet {
            if let micEnt = self.findEntity(named: "mic") {
                micEnt.isEnabled = audioEnabled
                return
            }
            if audioEnabled {
                let micEntity = AdvancedModelEntity()
                micEntity.fetchUSDZ(named: "mic") {
                    guard let micRadius = micEntity.model?.mesh.bounds.boundingRadius else {
                        fatalError("Could not get mic")
                    }
                    micEntity.scale = .init(repeating: 0.1 / micRadius)
                }
                micEntity.name = "mic"
                self.addChild(micEntity)
            }
        }
    }

    required init() {}
}
