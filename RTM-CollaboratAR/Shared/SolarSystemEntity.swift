//
//  SolarSystemEntity.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 27/10/2021.
//

import Foundation
import RealityKit
import RealityUI
import Combine

class SolarSystem: Entity {
    struct PlanetDetails {
        var texture: String
        var radius: Float
        var distance: Float
        var orbitPeriod: Float
    }
    let allPlanets: [PlanetDetails] = [
        PlanetDetails(texture: "2k_mercury", radius: 0.2, distance: 1.5, orbitPeriod: 2.0),
        PlanetDetails(texture: "2k_venus_surface", radius: 0.45, distance: 2.3, orbitPeriod: 3.5),
        PlanetDetails(texture: "2k_earth", radius: 0.5, distance: 3.5, orbitPeriod: 4.0),
        PlanetDetails(texture: "2k_mars", radius: 0.35, distance: 4.5, orbitPeriod: 5.0),
        PlanetDetails(texture: "2k_jupiter", radius: 0.8, distance: 6, orbitPeriod: 9.0),
        PlanetDetails(texture: "2k_saturn", radius: 0.65, distance: 7.75, orbitPeriod: 12.0),
        PlanetDetails(texture: "2k_uranus", radius: 0.55, distance: 9.25, orbitPeriod: 14.0),
        PlanetDetails(texture: "2k_neptune", radius: 0.50, distance: 10.5, orbitPeriod: 17.0),
        PlanetDetails(texture: "2k_sun", radius: 1, distance: 0, orbitPeriod: 0.0),
    ]
    required init() {
        super.init()
        self.scale = .one / 1000
    }
    func generateAllPlanets() {
        let timenow = Date().timeIntervalSinceReferenceDate
        print("start looping: \(Date().timeIntervalSinceReferenceDate)")
        for planet in allPlanets {
            print("looping: \(Date().timeIntervalSinceReferenceDate)")
            var planetMat = SimpleMaterial()
            let planetRoot = Entity()
            planetRoot.name = String(planet.texture.split(separator: "_")[1])
            self.addChild(planetRoot)
            if let texParam = try? TextureResource.load(named: planet.texture) {
                if #available(iOS 15.0, macOS 12.0, *) {
                    planetMat.color = .init(tint: .white, texture: .init(texParam))
                } else {
                    planetMat.baseColor = .texture(texParam)
                }
            }
            let newModel = ModelEntity(
                mesh: .generateSphere(radius: planet.radius),
                materials: [planetMat]
            )
            newModel.position.x = planet.distance
            planetRoot.addChild(newModel)
            if planet.orbitPeriod != 0 {
                print(newModel.isAnchored)
                let orbitPos = Int(timenow) % Int(planet.orbitPeriod)
                let orbitPercent = Float(orbitPos) / planet.orbitPeriod
                planetRoot.orientation = simd_quatf(angle: orbitPercent * (2 * .pi), axis: [0, 1, 0])
                planetRoot.ruiSpin(by: [0, 1, 0], period: TimeInterval(planet.orbitPeriod))
//                newModel.ruiSpin(by: [0, -1, 0], period: TimeInterval(-planet.orbitPeriod / 2))
            }
        }
    }
}
