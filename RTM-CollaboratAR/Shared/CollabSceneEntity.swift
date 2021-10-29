//
//  CollabEntity.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 01/06/2021.
//

import SwiftUI
import RealityKit
import Combine

import RealityUI

struct ModelData: Codable {
    /// Unique ID for this model
    var id: String
    /// Name of the USDZ file to use
    var usdz: String
    /// Scale of the entity
    var scale: SIMD3<Float>
    /// Orientation of the entity
    var rotation: simd_float4
    /// Position of the entity
    var translation: SIMD3<Float>
    /// Full Transform of the entity based on the scale, rotation and translation
    var transform: Transform { Transform(scale: scale, rotation: simd_quatf(vector: rotation), translation: translation)}
    /// Set to false when current user is dragging/scaling etc
    var isFree: Bool = true
    /// Last user to move this entity
    var owner: String
    init(id: String, usdz: String, transform: Transform, owner: String? = nil) {
        self.id = id
        self.usdz = usdz
        self.scale = transform.scale
        self.rotation = transform.rotation.vector
        self.translation = transform.translation
        self.owner = owner ?? CollaborationExpEntity.shared.rtmID
    }
}

class CollabSceneEntity: Entity, HasAnchoring, HasClick {
    @ObservedObject var collabExpEntity: CollaborationExpEntity
    static var defaultFloor = ModelComponent(
        mesh: .generatePlane(width: 1, depth: 1),
        materials: [UnlitMaterial(color: Material.Color.cyan.withAlphaComponent(0.3))]
    )
    var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = { clickedScene, clickLoc in
        // Add an entity to the scene
        guard let clickLoc = clickLoc, let sceneEntity = clickedScene as? CollabSceneEntity else { return }
        let collabExp = sceneEntity.collabExpEntity
        let localLoc = sceneEntity.collabBase.convert(position: clickLoc, from: nil)
        if collabExp.selectedUSDZ >= (collabExp.usdzForRoom ?? []).count {
            return
        }
        guard let usdzToAdd = collabExp.usdzForRoom?[collabExp.selectedUSDZ] else {
            fatalError("Invalid room joining: \(collabExp.roomStyles[collabExp.roomStyle].displayname)")
        }
        let newCollabModel = CollabModel(
            with: ModelData(
                id: UUID().uuidString, usdz: usdzToAdd,
                transform: Transform(
                    scale: .one, rotation: simd_quatf(angle: 0, axis: [0, 1, 0]),
                    translation: localLoc),
                owner: sceneEntity.collabExpEntity.rtmID)
        )
        // When adding a new box, un-select last selected
        collabExp.unselectSelected()
        sceneEntity.collabBase.addChild(newCollabModel)
        sceneEntity.collabExpEntity.sendCollabData(for: newCollabModel)
    }


    #if os(iOS) && !targetEnvironment(simulator)
    var gestures: [EntityGestureRecognizer] = []
    #endif
    var collabBase: HasModel & HasCollision
    var peerBase = Entity()
    init(collabExpEntity: CollaborationExpEntity) {
        self.collabExpEntity = collabExpEntity
        if let usdzFloor = collabExpEntity.floorForRoom {
            self.collabBase = AdvancedModelEntity(
                usdz: usdzFloor,
                defaultModel: CollabSceneEntity.defaultFloor
            )
            if usdzFloor == "awe_ground" {
                var nightSkyMat = SimpleMaterial()
                if let tex = try? TextureResource.load(named: "2k_stars_milky_way") {
                    if #available(iOS 15.0, macOS 12.0, *) {
                        nightSkyMat.color.texture = .init(tex)
                        let mtlLibrary = MTLCreateSystemDefaultDevice()!
                          .makeDefaultLibrary()!
                        // Fetch the "fadeCircle" surface shader
                        let surfaceShader = CustomMaterial.SurfaceShader(
                           named: "fadeCircle", in: mtlLibrary
                        )
                        if var shaderMat = try? CustomMaterial(from: nightSkyMat, surfaceShader: surfaceShader) {
                            shaderMat.baseColor.texture = .init(tex)
                            shaderMat.blending = CustomMaterial.Blending.transparent(opacity: 1.0)
                            self.collabBase = ModelEntity(mesh: .generatePlane(width: 3, depth: 3), materials: [shaderMat])
                        } else {
                            self.collabBase = ModelEntity(mesh: .generatePlane(width: 3, depth: 3, cornerRadius: 1.5), materials: [nightSkyMat])
                        }
                    } else {
                        nightSkyMat.baseColor = .texture(tex)
                        self.collabBase = ModelEntity(mesh: .generatePlane(width: 3, depth: 3, cornerRadius: 1.5), materials: [nightSkyMat])
                    }
                }
            }
        } else {
            self.collabBase = ModelEntity()
            self.collabBase.model = CollabSceneEntity.defaultFloor
        }
        super.init()
        collabBase.position.y = 0.05
        self.addChild(collabBase)
        self.collabBase.addChild(peerBase)
    }
    required convenience init() {
        self.init(collabExpEntity: CollaborationExpEntity.shared)
    }
    func entityAnchored() {
        #if os(iOS) && !targetEnvironment(simulator)
        collabBase.generateCollisionShapes(recursive: false)
        self.gestures = self.collabExpEntity.arView!.installGestures(for: collabBase)
        #endif
    }

    func update(with peerData: PeerData) {
        if let rtcID = peerData.rtcID, rtcID != 0 {
            self.collabExpEntity.rtmToRtc[peerData.rtmID] = rtcID
            self.collabExpEntity.rtcToRtm[rtcID] = peerData.rtmID
        }
        if let child = self.peerBase.findEntity(named: peerData.rtmID) as? PeerEntity {
            child.update(with: peerData)
        } else {
            self.createPeerEntity(with: peerData)
        }
    }
    func update(with models: [ModelData]) {
        for modelData in models {
            if let child = self.findEntity(named: modelData.id) as? CollabModel {
                child.update(with: modelData)
            } else {
                self.createModelEntity(with: modelData)
            }
        }
    }
    func createPeerEntity(with peerData: PeerData) {
        let modelEnt = PeerEntity(with: peerData)
        if let rtcID = peerData.rtcID {
            modelEnt.audioEnabled = self.collabExpEntity.micEnabled[rtcID] ?? false
        }
        DispatchQueue.main.async {
            self.peerBase.addChild(modelEnt)
        }
    }
    func createModelEntity(with modelData: ModelData) {
        let collabMod = CollabModel(with: modelData)
        DispatchQueue.main.async {
            self.collabBase.addChild(collabMod)
        }
    }
    func positionSet() {
        #if os(iOS) && !targetEnvironment(simulator)
        self.gestures.forEach { self.collabExpEntity.arView?.removeGestureRecognizer($0) }
        self.gestures.removeAll()
        #endif
        self.collabExpEntity.updatePositionsTimer = .scheduledTimer(
            timeInterval: 0.3, target: self.collabExpEntity,
            selector: #selector(self.collabExpEntity.updatePositions),
            userInfo: nil, repeats: true
        )
        self.collabBase.collision = nil
        self.collision = CollisionComponent(
            shapes: [.generateBox(size: [2, 0.1, 2] * self.collabBase.scale)
                      .offsetBy(rotation: self.collabBase.orientation, translation: self.collabBase.position)
            ]
        )
        self.collabExpEntity.showUSDZTray = true
        self.collabExpEntity.fetchCollabData(for: self)
        switch self.collabExpEntity.collabState {
        case .collab(data: let data):
            if data.isSpecial, let collabBase = self.collabExpEntity.collab?.collabBase {
                // TODO: ADD SPECIAL
                let newSolar = SolarSystem()
                collabBase.addChild(newSolar)
                newSolar.generateAllPlanets()
                newSolar.move(
                    to: Transform(scale: .one / 10, rotation: simd_quatf(angle: 0, axis: [0, 1, 0]), translation: [0, 0.4, 0]),
                    relativeTo: collabBase, duration: 1
                )
            }
        default: break
        }
    }
}
