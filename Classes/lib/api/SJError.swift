//
//  SJError.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

public enum SJError: Error {
    case bleNotEnabled
    case blePermissionsNotGranted
    case bleNotSupported
    case bleScanFailed
    case bleDeviceNotFound
    case bleDeviceDisconnected
    case bleProtocolError
    case bleNotConnected
    case locationPermissionsNotGranted
    case noInternetConnection
    case noStoredSession
    case noCommand
    case busyWithPreviousCommand
    case notInitialized
    case sjServerException
    case sjException
    
    var code: Int {
        switch self {
        case .bleNotEnabled:
            return 400
        case .blePermissionsNotGranted:
            return 401
        case .bleNotSupported:
            return 402
        case .bleScanFailed:
            return 403
        case .bleDeviceNotFound:
            return 404
        case .bleDeviceDisconnected:
            return 405
        case .bleProtocolError:
            return 406
        case .bleNotConnected:
            return 407
        case .locationPermissionsNotGranted:
            return 510
        case .noInternetConnection:
            return 520
        case .noStoredSession:
            return 521
        case .noCommand:
            return 522
        case .notInitialized:
            return 523
        case .sjServerException:
            return 524
        case .sjException:
            return 500
        case .busyWithPreviousCommand:
            return 408
        }
    }
    
    var message: String {
        switch self {
        case .bleNotEnabled:
            return "Bluetooth not enabled"
        case .blePermissionsNotGranted:
            return "Bluetooth permissions not granted"
        case .bleNotSupported:
            return "Bluetooth not supported or failed"
        case .bleScanFailed:
            return "Bluetooth scan failed"
        case .bleDeviceNotFound:
            return "Device not found"
        case .bleDeviceDisconnected:
            return "Device disconnected"
        case .bleProtocolError:
            return "Bluetooth protocol error"
        case .bleNotConnected:
            return "Device not connected"
        case .locationPermissionsNotGranted:
            return "Location permissions not granted"
        case .noInternetConnection:
            return "No Internet connected"
        case .noStoredSession:
            return "No stored session for vehicle"
        case .noCommand:
            return "Command not found"
        case .notInitialized:
            return "SDK not initialized. perform init() before calling"
        case .sjServerException:
            return "Server return error"
        case .sjException:
            return "Exception occur"
        case .busyWithPreviousCommand:
            return "Busy with previous command"
        }
    }
}
