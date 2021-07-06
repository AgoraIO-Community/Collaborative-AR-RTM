//
//  CollaborationExpEntity.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 17/05/2021.
//

import CoreGraphics
import RealityKit
import AgoraRtmKit
import AgoraRtcKit

import RealityUI
import Combine

class CollaborationExpEntity: ObservableObject {
    var globe: GlobeEntity?
    var collab: CollabSceneEntity?
    var arView: ARView?
    @Published var selectedBox: HasCollabModel?
    @Published var showUSDZTray: Bool = false
    @Published var selectedUSDZ: Int = 0
    @Published var usdzOptions: [String] = [
        "forest_tree3", "forest_tree1", "forest_tree2",
        "forest_shrub", "forest_rock"
    ]
    var roomStyles: [(displayname: String, systemName: String)] = [
        ("Forest", "leaf"),
        ("Desert", "sun.max")
    ]
    @Published var roomStyle = 0
    var updatePositionsTimer: Timer?
    var rtmID: String = UUID().uuidString
    var assignedColor: [CGFloat] = [
        .random(in: 0...1), .random(in: 0...1), .random(in: 0...1), 0.4
    ]
    var rtcID: UInt?
    var rtcToRtm: [UInt: String] = [:]
    var rtmKit: AgoraRtmKit!
    var channels: (lobby: AgoraRtmChannel?, collab: AgoraRtmChannel?) = (nil, nil)
    var rtcKit: AgoraRtcEngineKit!
    static var shared = CollaborationExpEntity()


    @Published var clickedChannelData: ChannelData? {
        didSet {
            DispatchQueue.main.async {
                self.showDrawer = !(self.clickedChannelData == nil)
                self.isNewChannel = (self.clickedChannelData?.channelID ?? "") == "new"
                print("self.isNewChannel: \(self.isNewChannel)")
                print(self.clickedChannelData?.channelID ?? "")
                if self.clickedChannelData == nil {
                    self.globe?.tempClickedEntity.removeFromParent()
                }
            }
        }
    }
    @Published var showDrawer: Bool = false
    @Published var isNewChannel: Bool = false
    @Published var showConfirm: Bool = false
    enum CollaborationState {
        case globe
        case collab(data: ChannelData)
    }
    @Published var collabState: CollaborationState = .globe
    func setState(to collabState: CollaborationState) {
        self.collabState = collabState
        switch collabState {
        case .globe:
            self.tearDownCollab()
            self.setupGlobeModel()
        case .collab(let collabData):
            /// - TODO: Fetch core channel data (without joining)
            self.tearDownGlobe()
            self.launchCollabScene()
            self.rtcKit.enableLocalAudio(true)
            self.rtcKit.joinChannel(
                byToken: AppKeys.appToken, channelId: collabData.channelID, info: nil, uid: self.rtcID ?? 0
            ) { chname, uid, _ in
                print("joining channel!")
                self.rtcID = uid
                self.updatePositions()
            }
            self.channels.collab = self.rtmKit.createChannel(withId: collabData.channelID, delegate: CollaboratARDelegateEntity.shared)
            self.channels.collab?.join(completion: { joinResponse in
                if joinResponse != .channelErrorOk {
                    print("could not join collabs channel: \(joinResponse.rawValue)")
                }
                CollaboratARDelegateEntity.shared.joinedCollabChannel(self.channels.collab!)
            })
        }
    }

    func createChannel() {
        guard var channelData = self
                .clickedChannelData else {
            return
        }

        if channelData.channelID == "new" {
            channelData.channelID = UUID().uuidString
            channelData.systemImage = self.roomStyles[self.roomStyle].systemName
            self.sendCollabChannel(
                channelData, to: self.channels.lobby!
            )
        }
        self.showDrawer = false
        self.clickedChannelData = nil
        self.setState(to: .collab(data: channelData))

    }

    func fetchCollabData(for collabEnt: CollabSceneEntity) {
        // - TODO: Join Channel, fetch data and position everything
//        collabEnt.update(with: [
//            ModelData(
//                id: UUID().uuidString, usdz: "tree1",
//                transform: Transform(scale: .one, rotation: simd_quatf(angle: 0, axis: [0, 1, 0]), translation: [0, 0, 0])
//            ), ModelData(
//                id: UUID().uuidString, usdz: "tree1",
//                transform: Transform(scale: .one, rotation: simd_quatf(angle: 0, axis: [0, 1, 0]), translation: [0.2, 0, 0])
//            ), ModelData(
//                id: UUID().uuidString, usdz: "tree1",
//                transform: Transform(scale: .one, rotation: simd_quatf(angle: 45, axis: [0, 1, 0]), translation: [0, 0, 0.2])
//            )
//        ])
    }


    func tearDownGlobe() {
        if let globe = self.globe {
            globe.removeFromParent()
            self.globe = nil
        }
    }
    func launchCollabScene() {
        let collabEnt = CollabSceneEntity(collabExpEntity: self)
        #if !os(iOS) || targetEnvironment(simulator)
        collabEnt.anchoring = AnchoringComponent(.world(transform: .init(diagonal: .one)))
        #else
        collabEnt.anchoring = AnchoringComponent(.plane(.horizontal, classification: .any, minimumBounds: [1,1]))
        #endif
        var cancellable: Cancellable!
        cancellable = self.scene.subscribe(to: SceneEvents.AnchoredStateChanged.self, on: collabEnt, { event in
            if event.isAnchored {
                DispatchQueue.main.async {
                    cancellable?.cancel()
                    collabEnt.entityAnchored()
                    #if os(iOS) && !targetEnvironment(simulator)
                    self.showConfirm = true
                    #else
                    collabEnt.positionSet()
                    #endif
                }
            }
        })
        self.scene.addAnchor(collabEnt)
        collabEnt.setOrientation(simd_quatf(angle: 0, axis: [0, 1, 0]), relativeTo: nil)
        self.collab = collabEnt
    }
    func tearDownCollab() {
        self.selectedBox = nil
        self.showUSDZTray = false
        self.showConfirm = false
        self.selectedUSDZ = 0
        self.collab?.removeFromParent()
        self.collab = nil
        self.channels.collab?.leave(completion: { leaveCompletion in
            if leaveCompletion != .ok {
                print("could not leave channel")
            }
            self.channels.collab = nil
        })
        self.rtcKit.leaveChannel()
    }
    func removeCollabModel(_ model: HasCollabModel, sendUpdate: Bool = false) {
        if let selectedBox = self.selectedBox, selectedBox.name == model.name {
            selectedBox.showBoundingBox = false
            self.selectedBox = nil
        }
        model.removeFromParent()
        if sendUpdate {
            let jsonData = try! JSONEncoder().encode(model.modelData)
            let rawMessge = AgoraRtmRawMessage(
                rawData: jsonData,
                description: RawRTMMessageDataType.removeCollabModel.rawValue
            )
            self.channels.collab?.send(rawMessge, completion: { sendResponse in
                if sendResponse != .errorOk {
                    print("COULD NOT SEND DELETE COMMAND")
                }
            })
        }
    }
    func setScene(to scene: Scene) {
        self.scene = scene
    }
    var reuseCancellable: Cancellable?
    var scene: Scene!

    func setupGlobeModel() {
        let globeModel = GlobeEntity()
        self.globe = globeModel
        self.scene.addAnchor(globeModel)
        #if !os(iOS) || targetEnvironment(simulator)
        self.globe?.anchoring = AnchoringComponent(.world(transform: .init(diagonal: .one)))
        #else
        self.globe?.anchoring = AnchoringComponent(.plane(.horizontal, classification: [.floor], minimumBounds: [1,1]))
        #endif
        if globeModel.isAnchored {
            self.globe!.spawnEarth()
        } else {
            reuseCancellable = scene.subscribe(to: SceneEvents.AnchoredStateChanged.self, on: self.globe!, { anchorEvent in
                if anchorEvent.isAnchored {
                    print("globe anchored")
                    DispatchQueue.main.async {
                        self.reuseCancellable?.cancel()
                        self.globe!.spawnEarth()
                    }
                }
            })
        }
        self.fetchSessionData()
    }

    required init() {
        self.initialiseRTM()
        self.initialiseRTC()
    }
    func initialiseRTC() {
        self.rtcKit = AgoraRtcEngineKit.sharedEngine(withAppId: AppKeys.appID, delegate: CollaboratARDelegateEntity.shared)
        self.rtcKit.enableAudio()
    }
    func initialiseRTM() {
        self.rtmKit = AgoraRtmKit(appId: AppKeys.appID, delegate: CollaboratARDelegateEntity.shared)
        rtmKit.login(byToken: AppKeys.appToken, user: self.rtmID) { loginResponse in
            if loginResponse != .ok {
                print("RTM LOGIN FAILED: \(loginResponse.rawValue)")
            } else {
                self.channels.lobby = self.rtmKit.createChannel(
                    withId: "lobby", delegate: CollaboratARDelegateEntity.shared
                )
                if self.channels.lobby == nil {
                    fatalError("Could not create lobby")
                }
                self.channels.lobby?.join(completion: { joinResponse in
                    if joinResponse != .channelErrorOk {
                        print("RTM JOIN CHANNEL FAILED: \(joinResponse.rawValue)")
                    }
                })
            }
        }
    }
    func showCardFor(channelData: ChannelData) {
        self.clickedChannelData = channelData
    }
}


extension CollaborationExpEntity {
    func showBox(around entity: HasCollabModel) {
        let bbox = entity.visualBounds(relativeTo: entity)
        var bbentity: BBEntity! = self.selectedBox?.findEntity(named: BBEntity.bbName) as? BBEntity
        if self.selectedBox != nil {
            self.selectedBox!.showBoundingBox = false
            self.sendCollabData(for: self.selectedBox!)
            #if os(iOS) && !targetEnvironment(simulator)
            self.collab?.gestures.forEach { self.arView?.removeGestureRecognizer($0) }
            self.collab?.gestures.removeAll()
            #endif
            if self.selectedBox?.name == entity.name {
                self.selectedBox = nil
                return
            }
        }
        if bbentity == nil {
            bbentity = BBEntity(with: bbox)
        } else {
            bbentity.box = BoundingBoxComponent(bbox: bbox)
        }
        self.selectedBox = entity
        #if os(iOS) && !targetEnvironment(simulator)
        if let newGestures = self.arView?.installGestures(for: entity) {
            self.collab?.gestures += newGestures
        }
        #endif
        entity.addChild(bbentity)
    }
    @objc func updatePositions() {
        if let camTransform = self.arView?.cameraTransform,
           let localisedCam = self.collab?.collabBase.convert(
            transform: camTransform, from: nil
        ) {
            #if os(iOS) && !targetEnvironment(simulator)
            if self.arView?.cameraMode == .ar {
                let peerData = PeerData(
                    rtmID: self.rtmID, rtcID: self.rtcID, usdz: nil,
                    scale: .one,
                    rotation: localisedCam.rotation.vector,
                    translation: localisedCam.translation,
                    colorVector: self.assignedColor
                )
                let jsonData = try! JSONEncoder().encode(peerData)
                let rawMessage = AgoraRtmRawMessage(rawData: jsonData, description: RawRTMMessageDataType.peerUpdate.rawValue)
                self.channels.collab?.send(rawMessage, completion: { collabSentErr in
                    if collabSentErr != .errorOk {
                        print("COLLAB DATA SEND FAILED: \(collabSentErr.rawValue)")
                    }
                })
            }
            #endif
        }
        if let selectedBox = self.selectedBox {
            self.sendCollabData(for: selectedBox)
        }
    }
}

struct BoundingBoxComponent: Component {
    var bbox: BoundingBox
    static var bbGeometry: MeshResource = .generateSphere(radius: 0.025)
}

protocol HasBoundingBox: Entity {
    var box: BoundingBoxComponent? { get set }
}

extension HasBoundingBox {
    var box: BoundingBoxComponent? {
        get { self.components[BoundingBoxComponent.self] }
        set {
            self.components[BoundingBoxComponent.self] = newValue
            self.boxUpdated()
        }
    }
    var cornerTransforms: [Transform] {
        guard let bbox = self.box?.bbox else {
            return []
        }
        return [
            [1, 1, 1], [1, 1, -1], [-1, 1, -1], [-1, 1, 1], // top 4
            [1, -1, 1], [1, -1, -1], [-1, -1, -1], [-1, -1, 1] // bottom 4
        ].map { $0 * bbox.extents / 2 }
        .map { Transform(scale: .one, rotation: .init(), translation: $0) }
    }
    func boxUpdated() {
        let cTransforms = self.cornerTransforms
        guard let bbox = self.box?.bbox, !cTransforms.isEmpty else {
            self.children.removeAll()
            return
        }
        self.position = bbox.center
        for (index, transform) in cTransforms.enumerated() {
            if index < self.children.count {
                self.children[index].transform = transform
            } else {
                let newChild = ModelEntity(
                    mesh: BoundingBoxComponent.bbGeometry,
                    materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
                )
                newChild.transform = transform
                print(newChild.transform)
                self.addChild(newChild)
                print(newChild.position(relativeTo: nil))
            }
        }
    }
}

class BBEntity: Entity, HasBoundingBox {
    static var bbName = "boundingbox"
    init(with bbox: BoundingBox) {
        super.init()
        self.name = BBEntity.bbName
        self.box = BoundingBoxComponent(bbox: bbox)
    }

    required init() {
        super.init()
    }
}

extension SIMD3 where SIMD3.Scalar == Float {
    func setLength(to length: Float) -> SIMD3<Float> {
        return self * length / self.mag
    }
    var mag: Float {
        sqrt(self.indices.reduce(Float(0)) { sum, ind in
            return sum + self[ind] * self[ind]
        })
    }
}

extension simd_float4 {
    var mag: Float {
        sqrt(self.indices.reduce(Float(0)) { sum, ind in
            return sum + self[ind] * self[ind]
        })
    }
}

