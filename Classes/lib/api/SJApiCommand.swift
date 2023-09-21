//
//  SJApiCommand.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

public struct SJApiCommand: Hashable {
    public let type: SJCommandType
    public let channel: SJCommandChannel
    
    public init(type: SJCommandType, channel: SJCommandChannel) {
            self.type = type
            self.channel = channel
        }
}
