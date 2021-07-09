//
//  CollabModel.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 04/06/2021.
//

import Foundation
import RealityKit
import Combine
import RealityUI

struct CollabComponent: Component {
    var isFree: Bool
    var usdz: String
    var owner: String?
    var showBoundingBox: Bool = false
}

protocol HasAdvancedModel: HasModel, HasCollision {}
extension HasAdvancedModel {
    func fetchUSDZ(named: String, completion: (() -> Void)? = nil) {
        ModelLoader.checkStatus(of: named) { modelComponent in
            self.model = modelComponent
            completion?()
        }
    }
}

protocol HasCollabModel: HasAdvancedModel, HasClick {
    var collab: CollabComponent { get set }
}
class ModelLoader {
    private static var shared = ModelLoader()
    enum LoadingState {
        case loading
        case loaded(ModelComponent)
    }
    var modelStates: [String: LoadingState] = [:]
    var modelLoadedApplier: [String: [(ModelComponent) -> Void]] = [:]
    static func checkStatus(of modelName: String, completion: @escaping (ModelComponent) -> Void) {
        let currModelState = self.shared.modelStates[modelName]
        switch currModelState {
        case .loaded(let modelComponent):
            completion(modelComponent)
        case .none:
            self.shared.modelLoadedApplier[modelName] = [completion]
            self.shared.modelStates[modelName] = .loading
            self.shared.fetchUSDZ(modelName: modelName)
        case .loading:
            self.shared.modelLoadedApplier[modelName]?.append(completion)
        }
    }
    func fetchUSDZ(modelName: String) {
        var cancellable: Cancellable?
        cancellable = Entity.loadModelAsync(named: modelName).sink(receiveCompletion: { compl in
            switch compl {
            case .finished:
                print("\(modelName) model found")
            case .failure(let err):
                cancellable?.cancel()
                print("could not load model: \(err.localizedDescription)")
            }
        }, receiveValue: { loadedModel in
            guard let modelComp = loadedModel.model else {
                return
            }
            self.modelStates[modelName] = .loaded(modelComp)
            self.modelLoadedApplier[modelName]?.forEach { $0(modelComp) }
            self.modelLoadedApplier.removeValue(forKey: modelName)
        })
    }
}
extension HasCollabModel {
    var collab: CollabComponent {
        get { self.components[CollabComponent.self] as! CollabComponent }
        set { self.components[CollabComponent.self] = newValue }
    }
    var showBoundingBox: Bool {
        get { self.collab.showBoundingBox }
        set {
            self.collab.showBoundingBox = newValue
            if newValue {
                CollaborationExpEntity.shared.showBox(around: self)
            } else {
                self.findEntity(named: BBEntity.bbName)?.removeFromParent()
            }
        }
    }
    var id: String { self.name }

    func setCollision() {
        guard let bounds = self.model?.mesh.bounds else {
            return
        }
        self.collision = CollisionComponent(shapes: [
            .generateBox(size: bounds.extents).offsetBy(translation: bounds.center)
        ])
    }
    var modelData: ModelData {
        ModelData(id: self.name, usdz: self.collab.usdz, transform: self.transform, owner: self.collab.owner)
    }
}
class AdvancedModelEntity: Entity, HasAdvancedModel {
    init(usdz: String, defaultModel: ModelComponent) {
        super.init()
        self.model = defaultModel
        self.fetchUSDZ(named: usdz)
    }

    required init() {
        super.init()
    }
}
class CollabModel: Entity, HasCollabModel {
    var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = { clickedEnt, _ in
        guard let collabEnt = clickedEnt as? CollabModel,
              !CollaborationExpEntity.shared.showConfirm
        else { return }
        CollaborationExpEntity.shared.requestOwnership(of: collabEnt) { success in
            if success {
                collabEnt.showBoundingBox = true
            }
        }
    }
    init(with modelData: ModelData) {
        super.init()
        self.collab = CollabComponent(isFree: modelData.isFree, usdz: modelData.usdz, owner: modelData.owner)
        self.transform = modelData.transform
        self.name = modelData.id
        self.model = ModelComponent(mesh: .generateSphere(radius: 0.05), materials: [])
        self.fetchUSDZ(named: self.collab.usdz) {
            self.setCollision()
        }
    }
    func update(with modelData: ModelData) {
        self.stopAllAnimations()
        if (modelData.translation - self.position).mag > 1e-5 ||
           (modelData.scale - self.scale).mag > 1e-5 ||
           (modelData.transform.rotation.vector - self.orientation.vector).mag > 1e-5 {
            self.move(to: modelData.transform, relativeTo: self.parent, duration: 0.4)
        }
        self.collab.owner = modelData.owner
    }
    required init() {
        super.init()
    }
}

