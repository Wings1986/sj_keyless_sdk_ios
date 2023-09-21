//
//  SJAppState.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation

class SJAppState {
    static let shared = SJAppState()
    private let storage = UserDefaults(suiteName: "sjKeylessSdk") ?? UserDefaults.standard
    
    var apiKey: String? {
        get {
            return storage.string(forKey: "apiKey")
        }
        set(newValue) {
            storage.setValue(newValue, forKey: "apiKey")
            storage.synchronize()
        }
    }
    
    var baseUrl: String {
        get {
            return storage.string(forKey: "baseUrl") ?? "https://cloud.sciencejet.net"
        }
        set {
            storage.set(newValue, forKey: "SJbaseUrl")
        }
    }
    
    var vehicleSession: SJVehicleSession?  {
        get {
            NSLog("vehicleSession get")
            if let dataString = storage.string(forKey: "vehicleSession"){
                return try? SJVehicleSession.fromJson(dataString)
            } else {
                return nil
            }
        }
        set {
            NSLog("vehicleSession set \(newValue)")
            let dataString = try? newValue?.toJson()
            NSLog("vehicleSession set  json: \(dataString)")
            storage.set(dataString ?? nil, forKey: "vehicleSession")
        }
    }
    
    func clean() {
        self.apiKey = nil
        self.vehicleSession = nil
    }
}
