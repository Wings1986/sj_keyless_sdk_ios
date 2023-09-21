//
//  SJCommandType.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

public enum SJCommandType: String, Codable {
    case doorUnlock = "door_unlock"
    case doorLock = "door_lock"
    case engineUnlock = "engine_unlock"
    case engineLock = "engine_lock"
    case hornSignal = "horn_signal"
    case blinkerSignal = "blinker_signal"
    
    static func fromValue(_ value: String) -> SJCommandType {
        guard let commandType = SJCommandType(rawValue: value) else {
            fatalError("Unknown command type \(value)")
        }
        return commandType
    }
}
