//
//  TapSpot.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 20/05/2021.
//

import RealityKit
import RealityUI


protocol HasHitpoint: HasClick {
    //    var circles: (outer: Entity, inner: Entity) {get set}
}
struct HitPointComponent: Component {
    var outerCircle: Entity?
    var innerCircle: Entity?
    var circleParent: Entity?
}
extension HasHitpoint {
    var hitPoint: HitPointComponent? {
        get { self.components[HitPointComponent.self] }
        set { self.components[HitPointComponent.self] = newValue }
    }
    func setupCircles() {
        guard self.hitPoint?.innerCircle == nil else {
            return
        }
        let outerCircle = ModelEntity(mesh: .generatePlane(width: 0.5, height: 0.5, cornerRadius: 0.25), materials: [UnlitMaterial(color: .red)])
        let innerCircle = ModelEntity(mesh: .generatePlane(width: 0.2, height: 0.2, cornerRadius: 0.1), materials: [UnlitMaterial(color: .orange)])
        innerCircle.position.z = 0.02
        self.addChild(outerCircle)
        self.addChild(innerCircle)

        self.hitPoint?.innerCircle = innerCircle
        self.hitPoint?.outerCircle = outerCircle
        self.collision = CollisionComponent(shapes: [.generateSphere(radius: 1)])
    }
}

class TapSpot: Entity, HasHitpoint {
    var tapAction: ((HasClick, SIMD3<Float>?) -> Void)?

    init(tapAction: @escaping ((HasClick, SIMD3<Float>?) -> Void)) {
        self.tapAction = tapAction
        super.init()
        self.hitPoint = HitPointComponent()
        self.setupCircles()
    }

    required init() {
        super.init()
    }
}
