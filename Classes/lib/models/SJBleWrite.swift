//
//  SJBleWrite.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation
struct SJBleWrite: Codable {
    let serviceId: String
    let char: String
    let data: String
}
