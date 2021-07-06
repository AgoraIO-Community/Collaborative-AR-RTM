//
//  CustomARView.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 01/06/2021.
//

import Foundation
#if canImport(ARKit)
import ARKit
#endif
import RealityKit

class CustomARView: ARView {
    #if os(iOS) && !targetEnvironment(simulator)
    override init(frame frameRect: CGRect, cameraMode: ARView.CameraMode, automaticallyConfigureSession: Bool) {
        super.init(frame: frameRect, cameraMode: cameraMode, automaticallyConfigureSession: automaticallyConfigureSession)
        let arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.horizontal]
        self.debugOptions.insert(.showPhysics)
        self.session.run(arConfig)
    }
    #endif

    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc required dynamic init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        #if !os(iOS) || targetEnvironment(simulator)
        let cam = PerspectiveCamera()
        cam.look(at: .zero, from: [0, 1, 1], relativeTo: nil)
        let camAnchor = AnchorEntity(world: .zero)
        camAnchor.name = "camAnchor"
        camAnchor.addChild(cam)
        self.scene.addAnchor(camAnchor)
        #endif
    }


    func positionEntities() {
//        let cube = try! Entity.load(named: "globe")
//        let cube = ModelEntity(mesh: .generateBox(size: 0.5))
//        let anchCube = AnchorEntity(world: .zero)
//        anchCube.addChild(cube)
//        self.scene.addAnchor(anchCube)
//        cube.ruiSpin(by: [0, -1, 0], period: 12)
        HitPointComponent.registerComponent()
        CollaborationExpEntity.shared.setScene(to: self.scene)
        CollaborationExpEntity.shared.setupGlobeModel()
    }
}
