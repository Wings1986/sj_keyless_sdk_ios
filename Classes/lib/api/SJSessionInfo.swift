//
//  SJSessionInfo.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

public struct SJSessionInfo {
    public let vehicleID: Int
    public let vehiclePlate: String
    public let commandsAvailable: [SJApiCommand]
}
