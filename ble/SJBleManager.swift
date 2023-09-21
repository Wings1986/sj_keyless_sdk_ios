//
//  SJBleManager.swift
//  Alamofire
//
//  Created by Ivan Astafiev on 08.06.2023.
//

import Foundation
import CoreBluetooth


class SJBleManager: NSObject {
    let device: SJBleDevice
    var ble: CBPeripheral?
    var pendingCommand: PendingCommand? = nil
    private var blueToothState = CBManagerState.unknown
    
    private var serviceList: [CBUUID: CBService] = [:]
    private var charsList: [CBUUID: CBCharacteristic] = [:]
    
    lazy var manager: CBCentralManager = {
        let options = [CBPeripheralManagerOptionRestoreIdentifierKey: "SJBleDeviceScanner"]
        let _manager = CBCentralManager(delegate: self, queue: nil, options: options)
        return _manager
    }()
    
    init(_ device: SJBleDevice) {
        self.device = device
        super.init()
    }
    
    class PendingCommand {
        let command: SJBleCommand
        let onCompleted: (SJResult) -> Void
        var completed = false
      
        init(command: SJBleCommand,onCompleted: @escaping (SJResult) -> Void) {
            self.command = command
            self.onCompleted = onCompleted
        }
        
        func failed(_ error: SJError){
            onCompleted(SJResult(error: error))
            completed = true
        }
        
        func success(){
            onCompleted(SJResult(isSuccess: true))
            completed = true
        }
    }
    
    var isConnected: Bool {
        get { ble?.state == CBPeripheralState.connected }
    }
    
    func deliverCommand(command: SJBleCommand, onResult: @escaping (SJResult) -> Void) {
        NSLog("deliverCommand \(command)")
        if (pendingCommand != nil){
            onResult(SJResult(error:SJError.busyWithPreviousCommand))
            return
        }
        self.pendingCommand = PendingCommand(command: command, onCompleted: onResult)
        continueDelivery()
    }
    
    func continueDelivery() {
        guard let command = pendingCommand else {
            NSLog("SJBleManager continueDelivery but no command waiting")
            return
        }
        
        NSLog("continueDelivery. discovered [\(ble)] \(ble?.state)")

        if blueToothState == .unknown {
            //Need to wait BluetoothManager to became effective
            NSLog("SJBleManager Need to wait BluetoothManager to became effective. fake connect")
            blueToothState = manager.state
            return
        }
        
        if blueToothState != .poweredOn {
            //Need to wait BluetoothManager to became effective
            NSLog("SJBleManager in wrong state \(blueToothState)")
            completeDelivery(result: SJResult(error: SJError.bleProtocolError))
            return
        }
        

        //No Scanned for ble
        if (self.ble == nil){
            NSLog("continueDelivery. request to scan")
            do {
                try performScan()
            } catch let error {
                completeDelivery(result: SJResult(error: SJError.sjException, data: error))
            }
            return
        }
        
        //Not connected
        if (isConnected == false){
            NSLog("SJBleManager trying to connect")
            manager.connect(ble!)
            return
        }
    

       sendCommand()
    }
    
    
    func onDestroy(){
        if isConnected {
            NSLog("SJBleManager Forse disconnection")
            manager.cancelPeripheralConnection(ble!)
        }
    }

    private func completeDelivery(result: SJResult) {
        NSLog("completeDelivery \(result)")
        guard let command = pendingCommand else {
            NSLog("completeDelivery but no waiting command")
            return
        }
        
        command.onCompleted(result)
        pendingCommand = nil
    }
    
    private func performScan() throws {
        //List of connected peripherals
        //Check id ble already in connected state
        let currentlyConnected = manager.retrieveConnectedPeripherals(withServices: [device.advService])
        for peripheral in currentlyConnected {
            if peripheral.name == device.bleName {
                NSLog("Restoring already connected peripheral.No Scann neeed")
                //Device is found and already connected. No Scann neeed
                restoreConnectedPeripheral(peripheral)
                return
            }
        }
//        
//        manager.retrieveConnectedPeripherals(withServices: [device.advService])
//        NSLog(" manager.retrieveConnectedPeripherals \(manager.retrieveConnectedPeripherals(withServices: [device.advService]).count)")
        
        manager.scanForPeripherals(withServices: [device.advService], options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5)
        { [weak self] in
            self?.manager.stopScan()
            if (self?.ble == nil){
                self?.completeDelivery(result: SJResult(error: SJError.bleDeviceNotFound))
            }
        }
    }
    
    
    
    private func stopScanAndConnnect(_ peripheral: CBPeripheral){
        manager.stopScan()
        ble = peripheral
        ble?.delegate  = self
        manager.connect(peripheral)
    }
    
    private func addCharacteristic(_ characteristic: CBCharacteristic){
        NSLog("SJBleManager addCharacteristic \(characteristic.uuid.uuidString)")
        
        //Add char for list and future use
        charsList[characteristic.uuid] = characteristic
        
        //Check subscribe if need to subscribe
        if device.needSubscribe(characteristic){
            NSLog("SJBleManager addCharacteristic subscribing")
            ble?.setNotifyValue(true, for: characteristic)
        }
            
        //Ask device if ready to command
        if device.commandUUID() == characteristic.uuid {
            NSLog("SJBleManager addCharacteristic continueDelivery")
            continueDelivery()
        }
    }
    
    private func sendCommand(){
        guard let command = pendingCommand else {
            NSLog("SJBleManager continueDelivery but no command waiting")
            return
        }
        
        guard let commandChar = charsList[device.commandUUID()] else {
            NSLog("SJBleManager command characteristic is absent on command")
            return
        }
        
        guard let peripheral = ble else {
            NSLog("SJBleManager peripheral is absent on command")
            return
        }
        
        
        //Command Sequence send Plan
        var x: Int = 0
        for write in command.command.sequence {
            let nextRun = x * (command.command.delay ?? 0)
            Timer.scheduledTimer(withTimeInterval: Double(nextRun), repeats: false) { timer in
                //Command Send Code Your code
                NSLog("SJBleManager ble write \(write)")
                peripheral.writeValue(self.device.prepareWrite(write: write), for: commandChar, type: .withoutResponse)
                //Finish on last command write
                NSLog("SJBleManager finishing? \(x) == \(command.command.sequence.count)")
                if x == command.command.sequence.count {
                    NSLog("SJBleManager finishing")
                    self.completeDelivery(result: SJResult(isSuccess: true))
                }
            }
            x += 1
        }
    }
    
    // Called when BLE State become Power ON or on startup
    private func restorePeripherals(central: CBCentralManager){
        NSLog("restorePeripherals called")
        let peripherals  = central.retrieveConnectedPeripherals(withServices: [device.advService])
        NSLog("restorePeripherals restoring \(peripherals.count) ")
        for peripheral in peripherals {
            restoreConnectedPeripheral(peripheral)
        }
    }
    
    private func restoreConnectedPeripheral(_ peripheral: CBPeripheral){
        NSLog("restoreConnectedPeripheral \(peripheral.name)")
        ble = peripheral
        peripheral.delegate = self
        if peripheral.services == nil {
            peripheral.discoverServices(nil)
            return
        } else {
            self.servicesDiscovered(peripheral, services: peripheral.services!)
            return
        }
    }
    
    private func servicesDiscovered(_ peripheral: CBPeripheral, services: [CBService]){
        for service in services {
            NSLog("Service found with UUID: \(service.uuid.uuidString) chars: [\(service.characteristics?.count)]")
            serviceList[service.uuid] = service
            if (service.characteristics == nil){
                peripheral.discoverCharacteristics(nil, for: service)
            } else {
                for char in service.characteristics! {
                    addCharacteristic(char)
                }
            }
        }
    }
}


@available(iOS 10.0, *)
extension SJBleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        blueToothState = central.state
        NSLog("centralManagerDidUpdateState called \(central.state.rawValue)")
        
        guard let command = pendingCommand else {
            NSLog("centralManagerDidUpdateState called but no command is waiting")
            return
        }
        
        switch central.state {
        case .unknown:
            completeDelivery(result: SJResult(error: SJError.bleProtocolError))
        case .unsupported:
            completeDelivery(result: SJResult(error: SJError.bleNotSupported))
        case .unauthorized:
            completeDelivery(result: SJResult(error: SJError.blePermissionsNotGranted))
        case .poweredOff:
            completeDelivery(result: SJResult(error: SJError.bleNotEnabled))
        default:
            continueDelivery()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("centralManager didConnect \(peripheral)")
        if (peripheral == ble){
            peripheral.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("centralManager didFailToConnect \(peripheral)")
        completeDelivery(result: SJResult(error: SJError.bleDeviceNotFound, data: error))
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        NSLog("centralManager willRestoreState \(dict)")
        restorePeripherals(central: central)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        NSLog("SCANNER Discoivered UNKNOWN Device \(peripheral.name) | \(advertisementData)| \(RSSI)")
        if peripheral.name == device.bleName {
            stopScanAndConnnect(peripheral)
        }
    }
}

extension SJBleManager: CBPeripheralDelegate{
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        if error != nil {
            NSLog("SJBleManager didDiscoverServices failed with \(error)")
            completeDelivery(result: SJResult(error: SJError.bleProtocolError, data: error))
            return
        }
        
        NSLog("Services Discovered \(peripheral.name)")
        self.servicesDiscovered(peripheral, services: peripheral.services!)

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        if error != nil {
            NSLog("SJBleManager didDiscoverCharacteristicsFor failed with \(error!)")
            completeDelivery(result: SJResult(error: SJError.bleProtocolError, data: error))
            return
        }
        for characteristic in service.characteristics! {
            NSLog("BLE CHAR DISCOVERED: " + characteristic.uuid.uuidString)
            addCharacteristic(characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if error != nil {NSLog("BLE didUpdateValueFor failed \(error!)"); return}
        NSLog("BLE didUpdateValueFor \(characteristic.uuid.uuidString) => \(SJConvert.dataToHexString(characteristic.value ?? Data()))")
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        if error != nil {NSLog("BLE didWriteValueFor failed \(error!)"); return}
        NSLog("BLE didWriteValueFor \(characteristic.uuid.uuidString) => \(SJConvert.dataToHexString(characteristic.value ?? Data()))")
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        if error != nil {NSLog("BLE didUpdateNotificationStateFor failed \(error!)"); return}
        NSLog("BLE didUpdateNotificationStateFor \(characteristic.uuid.uuidString) => \(characteristic.isNotifying)")
    }
}
