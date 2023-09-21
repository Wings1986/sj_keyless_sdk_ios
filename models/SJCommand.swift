//
//  SJCommand.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

class SJCommand: Codable {
    var channel: SJCommandChannel
    var type: SJCommandType

    init (type: SJCommandType, channel: SJCommandChannel) {
        self.channel = channel
        self.type = type
    }
    
    static func decodeCommand(from decoder: Decoder) throws -> SJCommand {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let channel = try container.decode(SJCommandChannel.self, forKey: .channel)
        switch channel {
        case .ble:
            return try SJBleCommand(from: decoder)
        case .server:
            return try SJServerCommand(from: decoder)
        }
    }

    private enum CodingKeys: String, CodingKey {
            case type
            case channel
        }
    
    func toApi() -> SJApiCommand {
        return SJApiCommand(type: type, channel: channel)
    }
}
