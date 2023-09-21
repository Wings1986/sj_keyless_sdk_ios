//
//  SJVehicleSession.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

struct SJVehicleSession: Codable {
    let vehicleData: SJVehicleData
    let deviceData: SJDeviceData
    let commands: [SJCommand]
    
    private enum CodingKeys: String, CodingKey {
            case vehicleData, deviceData, commands
        }
    
    //This looks ugly.. But required to simplyfy Codable. As command types are dynamic and command have flat json object.
    private struct RawCommand: Codable {
        var channel: SJCommandChannel
        var type: SJCommandType
        var delay: Int?
        var code: String?
        var sequence: [SJBleWrite]?
    }
    
    private enum ComandCodingKeys: String, CodingKey {
            case channel, type, delay,code,sequence
        }

    static func fromJson(_ jsonString: String) throws -> SJVehicleSession {
        let decoder = JSONDecoder()
        return try decoder.decode(SJVehicleSession.self, from: Data(jsonString.utf8))
    }
    
    static func fromJsonData(data: Any) throws -> SJVehicleSession {
        NSLog("SJVehicleSession fromJsonData [\(data)]")
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(SJVehicleSession.self, from: jsonData)
    }
    
   
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.vehicleData = try container.decode(SJVehicleData.self, forKey: .vehicleData)
        self.deviceData = try container.decode(SJDeviceData.self, forKey: .deviceData)
        let rawCommands = try container.decode([RawCommand].self, forKey: .commands)
    
        self.commands = rawCommands.map({raw in
            switch raw.channel{
            case .ble:
                return SJBleCommand(type: raw.type, channel: raw.channel, delay: raw.delay, sequence: raw.sequence!)
            case .server:
                return SJServerCommand(type: raw.type, channel: raw.channel,  code: raw.code!)
            }
        })
    }
    
    func toApi() -> SJSessionInfo {
        return SJSessionInfo(vehicleID: vehicleData.vehicleId, vehiclePlate: vehicleData.vehiclePlate, commandsAvailable: commands.map{ $0.toApi() })
    }

    func toJson() throws -> String {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }
}
