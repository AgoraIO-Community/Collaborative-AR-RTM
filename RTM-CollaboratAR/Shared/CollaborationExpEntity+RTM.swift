//
//  CollaborationExpEntity+RTM.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 11/06/2021.
//

import Foundation
import AgoraRtmKit

enum RawRTMMessageDataType: String {

    // MARK: Globe Scene

    /// A session is available to display on the globe
    case channelAvailable
    /// Request all available sessions
    case getSessionData

    // MARK: Collaborative Session

    /// A model has been created or transform modified
    case singleCollabModel
    /// Multiple models are available to display in the scene
    case multiCollabModels
    /// A model has been deleted
    case removeCollabModel
    /// Transform update for a remote user
    case peerUpdate
}

extension CollaborationExpEntity {

    func fetchSessionData() {
        let rawMessage = AgoraRtmRawMessage(rawData: Data(), description: RawRTMMessageDataType.getSessionData.rawValue)
        self.channels.lobby?.send(rawMessage, completion: { sendMessageErr in
            if sendMessageErr != .errorOk {
                print("could not send session request")
            }
        })
    }
    func sendCollabChannel(_ channel: ChannelData, to rtmChannel: AgoraRtmChannel) {
        rtmChannel.send(channel.encodedRawRTM()) { messageSentCompl in
            if messageSentCompl != .errorOk {
                print("RTM SEND CHANNEL FAILED \(messageSentCompl.rawValue)")
            }
        }
    }

    func sendCollabChannel(_ channel: ChannelData, to member: String) {
        self.rtmKit.send(
            channel.encodedRawRTM(), toPeer: member
        ) { messageSentCompl in
            if messageSentCompl != .ok {
                print("RTM SEND CHANNEL FAILED \(messageSentCompl.rawValue)")
            }
        }

    }


    func sendAllCollabData(to member: AgoraRtmMember) {
        let collabChildren = self.collab?.collabBase.children.compactMap
        { $0 as? HasCollabModel } ?? [HasCollabModel]()
        if collabChildren.isEmpty {
            print("no collab children in this scene")
            return
        }
        let allModelData = collabChildren.map { $0.modelData }
        let jsonData = try! JSONEncoder().encode(allModelData)
//        let jsonString = String(data: jsonData, encoding: .utf8)!
        // - TODO: Send jsonString of encoded [ModelData]
        let rawMessge = AgoraRtmRawMessage(rawData: jsonData, description: RawRTMMessageDataType.multiCollabModels.rawValue)
        self.rtmKit.send(rawMessge, toPeer: member.userId) { messageSentCompl in
            if messageSentCompl != .ok {
                print("RTM SEND COLLAB FAILED \(messageSentCompl.rawValue)")
            }
        }
    }

    func sendCollabData(for collabEnt: HasCollabModel) {
        let jsonData = try! JSONEncoder().encode(collabEnt.modelData)
        let rawMessge = AgoraRtmRawMessage(
            rawData: jsonData,
            description: RawRTMMessageDataType.singleCollabModel.rawValue
        )
        
        self.channels.collab?.send(rawMessge, completion: { messageSentCompl in
            if messageSentCompl != .errorOk {
                print("RTM SEND COLLAB FAILED \(messageSentCompl.rawValue)")
            }
        })
    }

    func requestOwnership(of collabModel: CollabModel, completion: (Bool) -> Void) {
        if collabModel.collab.owner == CollaborationExpEntity.shared.rtmID {
            completion(true)
            return
        }
        /// - TODO: Send RTM request to `collabModel.collab.owner`
        print("requesting ownership")
        completion(true)
    }
}
