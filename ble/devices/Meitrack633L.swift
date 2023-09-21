//
//  Meitrack633L.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation
import CoreBluetooth

class Meitrack633L : SJBleDevice {
    private enum Chars: String {
        case notify = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
        case command = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
    }
    
    override var advService: CBUUID {
        return CBUUID(string: "00001812-0000-1000-8000-00805f9b34fb")
    }
    
    override func prepareWrite(write: SJBleWrite) -> Data {
        return Data(write.data.utf8)
    }
    
    override init(bleName: String) {
        super.init(bleName: bleName)
    }
    
    override func needSubscribe(_ characteristic: CBCharacteristic) -> Bool {
        return CBUUID(string: Chars.notify.rawValue) == characteristic.uuid
    }
    
    override func commandUUID() -> CBUUID {
        return CBUUID(string: Chars.command.rawValue)
    }

}
