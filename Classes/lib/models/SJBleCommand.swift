//
//  SJBleCommand.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation
class SJBleCommand: SJCommand {
    let delay: Int?
    let sequence: [SJBleWrite]
    
    private enum CodingKeys: String, CodingKey {
            case type
            case channel
            case delay
            case sequence
        }
    
    init(type: SJCommandType, channel: SJCommandChannel, delay: Int?, sequence: [SJBleWrite]){
        self.delay = delay
        self.sequence = sequence
        super.init(type: type, channel: channel)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.delay = try container.decode(Int.self, forKey: .delay)
        self.sequence = try container.decode([SJBleWrite].self, forKey: .sequence)
        try super.init(from: decoder)
    }
       
    override func encode(to encoder: Encoder) throws {
           var container = encoder.container(keyedBy: CodingKeys.self)
           try container.encode(delay, forKey: .delay)
           try container.encode(sequence, forKey: .sequence)
           try container.encode(type, forKey: .type)
           try container.encode(channel, forKey: .channel)
    }
    
    static func fromJsonData(data: Any) throws -> SJBleCommand {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(SJBleCommand.self, from: jsonData)
    }
}
