//
//  ChannelData.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 15/06/2021.
//

import AgoraRtmKit

struct ChannelData: Codable {
    // Name of the channel
    var channelName: String
    // Channel ID used for Audio and RTM channel connections
    var channelID: String
    // Position to be placed around the globe
    var position: SIMD3<Float>
    // Image showing the type of room (forest, desert)
    var systemImage: String?
    // Type of channel (forest, desert)
    var channelType: String?
    /// Is a special type of room or not
    var isSpecial: Bool = false
}

extension ChannelData {
    func encodedRawRTM() -> AgoraRtmRawMessage {
        let jsonData = try! JSONEncoder().encode(self)
        return AgoraRtmRawMessage(
            rawData: jsonData, description: RawRTMMessageDataType.channelAvailable.rawValue
        )
    }
}
