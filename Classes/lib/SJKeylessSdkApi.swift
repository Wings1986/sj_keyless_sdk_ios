//
//  SJKeylessSdkApi.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 07.06.2023.
//

import Foundation
final public class SJKeylessSdkApi {
    static var bleManager: SJBleManager?
    
    static public func authorize(vehiclePlate: String, apiKey: String, onCompletion: @escaping (SJSessionInfo) -> Void, onFail: @escaping (Error) -> Void) {
        SJAppState.shared.apiKey = apiKey
        SJCloudServer.requestForVehicle(vehiclePlate: vehiclePlate, onSuccess: { vehicleSession in
            SJAppState.shared.vehicleSession = vehicleSession
            onCompletion(vehicleSession.toApi())
        }, onFail: { error in
            NSLog("SDK authorize failed clean")
            SJAppState.shared.clean()
            onFail(error)
        })
    }
    
    static public func sessionInfo() -> SJSessionInfo? {
        return SJAppState.shared.vehicleSession?.toApi()
    }
    
    static public func clear() -> SJResult {
        SJAppState.shared.clean()
        return SJResult(isSuccess: true)
    }
    
    static public func sendCommand(command: SJApiCommand, onResult: @escaping (SJResult) -> Void){
        guard let session = SJAppState.shared.vehicleSession else {
            onResult(SJResult(error: SJError.noStoredSession))
            return
        }
        guard  let internalCommand = session.commands.first(where: { c in
            c.channel == command.channel && c.type == command.type
        }) else {
            onResult(SJResult(error: SJError.noCommand))
            return
        }
        
        switch (internalCommand){
        case is SJBleCommand:
            sendViaBle(session: session, internalCommand: internalCommand as! SJBleCommand ,onResult: onResult)
        case is SJServerCommand:
            sendViaServer(session: session,internalCommand: internalCommand as! SJServerCommand,onResult: onResult)
        default:
            onResult(SJResult(error: SJError.sjException))
        }
    }
    
    static func sendViaBle(session: SJVehicleSession, internalCommand: SJBleCommand, onResult: @escaping (SJResult) -> Void){
        guard let bleDevice = SJBleDevice.detect(deviceData: session.deviceData) else {
            onResult(SJResult(error: SJError.sjException, data: "SJBleDevice unknown"))
            return
        }
        
        if (bleManager == nil) {
            bleManager = SJBleManager(bleDevice)
        }

        bleManager!.deliverCommand(command: internalCommand,onResult: onResult)
    }
    
    static func sendViaServer(session: SJVehicleSession, internalCommand: SJServerCommand, onResult: @escaping (SJResult) -> Void){
        SJCloudServer.deviceCommand(vehicleId: session.vehicleData.vehicleId, code: internalCommand.code, onComplete: onResult)
    }
}
    

