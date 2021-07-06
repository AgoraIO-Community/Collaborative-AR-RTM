//
//  ChannelData.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 15/06/2021.
//

import AgoraRtmKit

struct ChannelData: Codable {
    var channelName: String
    var channelID: String
    var position: SIMD3<Float>
    var systemImage: String?
}

extension ChannelData {
    func encodedRawRTM() -> AgoraRtmRawMessage {
        let jsonData = try! JSONEncoder().encode(self)
        return AgoraRtmRawMessage(
            rawData: jsonData, description: RawRTMMessageDataType.channelAvailable.rawValue
        )
    }
}
