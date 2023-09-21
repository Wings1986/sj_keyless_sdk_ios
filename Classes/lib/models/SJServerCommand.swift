//
//  SJServerCommand.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

class SJServerCommand: SJCommand {
    let code: String
     
    private enum CodingKeys: String, CodingKey {
            case code
            case type
            case channel
        }
    
    init(type: SJCommandType, channel: SJCommandChannel, code: String){
        self.code = code
        super.init(type: type, channel: channel)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        try super.init(from: decoder)
    }
       
    override func encode(to encoder: Encoder) throws {
           var container = encoder.container(keyedBy: CodingKeys.self)
           try container.encode(code, forKey: .code)
           try container.encode(type, forKey: .type)
           try container.encode(channel, forKey: .channel)
    }
    
    static func fromJsonData(data: Any) throws -> SJServerCommand {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(SJServerCommand.self, from: jsonData)
    }
    
}
