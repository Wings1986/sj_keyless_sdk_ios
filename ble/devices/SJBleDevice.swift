//
//  SJBleDevice.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation
import CoreBluetooth

class SJBleDevice {
    var bleName: String
    
    init(bleName: String) {
        self.bleName = bleName
    }
    
    class func detect(deviceData: SJDeviceData) -> SJBleDevice? {
        switch deviceData.type {
            case "Meitrack.633L":
                return Meitrack633L(bleName: deviceData.bleNameId)
            case "Teltonika.FMC130":
                return Fmc130Ble(bleName: deviceData.bleNameId)
            default:
                return nil
        }
    }
    
    var advService: CBUUID {
        fatalError("Must be implemented by subclasses")
    }
    
    func prepareWrite(write: SJBleWrite) -> Data {
        fatalError("Must be implemented by subclasses")
    }
    
    func needSubscribe(_ characteristic: CBCharacteristic) -> Bool {
        fatalError("Must be implemented by if ready for command")
    }
    
    func commandUUID() -> CBUUID {
        fatalError("Must be implemented by if ready for command")
    }
    
    
}
