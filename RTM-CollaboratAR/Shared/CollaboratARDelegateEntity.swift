//
//  CollaboratARDelegateEntity.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 15/06/2021.
//

import AgoraRtmKit
import AgoraRtcKit

class CollaboratARDelegateEntity: NSObject, AgoraRtmDelegate, AgoraRtmChannelDelegate {
    static var shared = CollaboratARDelegateEntity()
    var moreSeniorMembers: Set<String> = []
    fileprivate func handleIncomingMessage(
        _ message: AgoraRtmMessage,
        channel: AgoraRtmChannel? = nil,
        from member: AgoraRtmMember? = nil
    ) {
        switch message.type {
        case .raw:
            guard let rawMessage = message as? AgoraRtmRawMessage else {
                fatalError("Could not decode message")
            }
            switch RawRTMMessageDataType(rawValue: message.text) {
            case .getSessionData:
                guard let channel = channel, let member = member else { return }
                self.channel(channel, memberJoined: member)
            case .multiCollabModels:
                let modelDatas = try! JSONDecoder().decode([ModelData].self, from: rawMessage.rawData)
                CollaborationExpEntity.shared.collab?.update(with: modelDatas)
            case .singleCollabModel, .removeCollabModel:
                let modelData = try! JSONDecoder().decode(ModelData.self, from: rawMessage.rawData)
                if message.text == RawRTMMessageDataType.removeCollabModel.rawValue {
                    if (CollaborationExpEntity.shared.selectedBox?.name ?? "") == modelData.id {
                        CollaborationExpEntity.shared.selectedBox?.showBoundingBox = false
                        CollaborationExpEntity.shared.selectedBox?.removeFromParent()
                        CollaborationExpEntity.shared.selectedBox = nil
                    } else if let foundBox = CollaborationExpEntity.shared.collab?.findEntity(named: modelData.id) {
                        foundBox.removeFromParent()
                    }
                    return
                }
                CollaborationExpEntity.shared.collab?.update(with: [modelData])
            case .peerUpdate:
                // USDZ tray is only shown when the world has been set
                if CollaborationExpEntity.shared.showUSDZTray {
                    let peerData = try! JSONDecoder().decode(PeerData.self, from: rawMessage.rawData)
                    CollaborationExpEntity.shared.collab?.update(with: peerData)
                }
            case .channelAvailable:
                switch CollaborationExpEntity.shared.collabState {
                case .globe:
                    let channelData = try! JSONDecoder().decode(ChannelData.self, from: rawMessage.rawData)
                    CollaborationExpEntity.shared.globe?.spawnHitpoint(channelData: channelData)
                default: break
                }
            default: break
            }
        default:
            print("unkown type")
        }
    }

    func channel(
        _ channel: AgoraRtmChannel,
        messageReceived message: AgoraRtmMessage,
        from member: AgoraRtmMember
    ) {
        handleIncomingMessage(message, channel: channel, from: member)
    }

    func rtmKit(_ kit: AgoraRtmKit, messageReceived message: AgoraRtmMessage, fromPeer peerId: String) {
        handleIncomingMessage(message)
    }

    func joinedCollabChannel(_ channel: AgoraRtmChannel) {
        channel.getMembersWithCompletion { channelMembers, error in
            if error != .ok {
                print("could not get members")
                return
            }
            channelMembers?.forEach {
                if $0.userId != CollaborationExpEntity.shared.rtmID {
                    self.moreSeniorMembers.insert($0.userId)
                }
            }
        }
//        for i in 0...2 {
//            let angle = Float.random(in: 0...(2 * .pi))
//            CollaborationExpEntity.shared.collab?.createPeerEntity(
//                with: PeerData(
//                    rtmID: UUID().uuidString, rtcID: .random(in: 0...999), usdz: nil,
//                    scale: .one, rotation: .zero,
//                    translation: [sin(angle) * 0.7, 0.3, cos(angle) * 0.7], colorVector: [.random(in: 0...1), .random(in: 0...1), .random(in: 0...1), 0.4]
//                )
//            )
//        }
    }
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        if member.channelId == "lobby" {
            switch CollaborationExpEntity.shared.collabState {
            case .collab(let data):
                CollaborationExpEntity.shared.sendCollabChannel(data, to: member.userId)
            case .globe: break
            }
        } else if self.moreSeniorMembers.isEmpty {
            CollaborationExpEntity.shared.sendAllCollabData(to: member)
        }
    }
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        if member.channelId == "lobby" {
            print("\(member.userId) left the lobby")
            return
        }
        switch CollaborationExpEntity.shared.collabState {
        case .collab(let collabData):
            if collabData.channelID == member.channelId {
                if self.moreSeniorMembers.contains(member.userId) {
                    self.moreSeniorMembers.remove(member.userId)
                }
                CollaborationExpEntity.shared.collab?.peerBase.findEntity(
                    named: member.userId
                )?.removeFromParent()
            }
        default: break
        }
    }
}

extension CollaboratARDelegateEntity: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, activeSpeaker speakerUid: UInt) {}
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStateChangedOfUid uid: UInt, state: AgoraAudioRemoteState, reason: AgoraAudioRemoteStateReason, elapsed: Int) {
        if state == .stopped || state == .starting || state == .decoding {
            let isEnabled = state == .starting || state == .decoding
            CollaborationExpEntity.shared.micEnabled[uid] = isEnabled
            CollaborationExpEntity.shared.findPeerEntity(for: uid)?.audioEnabled = isEnabled
        }
    }
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("channel joined!")
    }
}

extension CollaborationExpEntity {
    func findPeerEntity(for uid: UInt) -> PeerEntity? {
        guard let rtmID = self.rtcToRtm[uid] else { return nil }
        return self.collab?.collabBase.findEntity(named: rtmID) as? PeerEntity
    }
}
