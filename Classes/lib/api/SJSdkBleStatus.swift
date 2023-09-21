//
//  SJSdkBleStatus.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

public enum SJSdkBleStatus {
    case notAuthorized
    case permissionsNotGranted
    case bluetoothOff
    case ready
}
