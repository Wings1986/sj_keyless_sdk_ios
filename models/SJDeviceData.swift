//
//  SJDeviceData.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

struct SJDeviceData: Codable {
    let type: String
    let bleNameId: String
    let bleServiceUid: String
}
