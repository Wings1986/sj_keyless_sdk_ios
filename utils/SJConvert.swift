//
//  SJConvert.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation
import Foundation

class SJConvert{
    
    static func roundToDecimal(_ value: Double, _ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(value * multiplier) / multiplier
    }
    
    static func dataToHexString(_ data: Data) -> String {
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
    static func hexStringToData(_ raw: String) -> Data {
        var data = Data()
        var value = raw
        
        while value.count > 0 {
          let subIndex = value.index(value.startIndex, offsetBy: 2)
          let c = String(value[..<subIndex])
            value = String(value[subIndex...])

          var char: UInt8
          if #available(iOS 13.0, *) {
            guard let int = Scanner(string: c).scanInt32(representation: .hexadecimal) else { return data }
            char = UInt8(int)
          } else {
            var int: UInt32 = 0
            Scanner(string: c).scanHexInt32(&int)
            char = UInt8(int)
          }

          data.append(&char, count: 1)
        }

        return data
    }
    
    static func UUIDasUInt8Array(_ uuid: UUID) -> [UInt8]{
            let (u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16) = uuid.uuid
            return [u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16]
        }
    static func UUIDasData(_ uuid: UUID) -> Data{
            return Data(UUIDasUInt8Array(uuid))
        }
    
    
}
