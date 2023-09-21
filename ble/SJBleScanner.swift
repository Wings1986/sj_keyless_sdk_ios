//
//  SJBleScanner.swift
//  sj_keyless_sdk_ios
//
//  Created by Ivan Astafiev on 08.06.2023.
//

import Foundation
import CoreBluetooth


@available(iOS 10.0, *)
class SJBleScanner: NSObject {
    static let shared = SJBleScanner()
    
    private var peripherals = [CBPeripheral]()
    private var blueToothState = CBManagerState.unknown
    private var isScanning: Bool { return manager.isScanning }
    private var scanJob: PendingScan? = nil
    var isBleReady: Bool { return blueToothState == .poweredOn}
    
    class PendingScan {
        let device: SJBleDevice
        let duration: Double
        let onDiscovered: (CBPeripheral) -> Void
        let onFail: (SJResult) -> Void
        var completed: Bool = false
        
        init(device: SJBleDevice,duration: Double, onDiscovered: @escaping (CBPeripheral) -> Void, onFail: @escaping (SJResult) -> Void) {
            self.duration = duration
            self.device = device
            self.onDiscovered = onDiscovered
            self.onFail = onFail
        }
        
        func failed(_ error: SJError){
            onFail(SJResult(error: error))
            completed = true
        }
        
        func discovered(ble: CBPeripheral){
            onDiscovered(ble)
            completed = true
        }
    }
    
    lazy var manager: CBCentralManager = {
        let options = [CBPeripheralManagerOptionRestoreIdentifierKey: "SJBleDeviceScanner"]
        let _manager = CBCentralManager(delegate: self, queue: nil, options: options)
        return _manager
    }()
    
    
    func startScan(device: SJBleDevice, duration: Double = 5, onDiscovered: @escaping (CBPeripheral) -> Void, onFail:  @escaping (SJResult) -> Void) {
        NSLog("Scanning SJBleDevice [\(device.bleName)]")
        
        if isScanning {
            //onFail(SJResult(error: SJError.bleScanFailed))
            return
        }
        
        scanJob = PendingScan(device: device, duration: duration, onDiscovered: onDiscovered, onFail: onFail)
        
        if blueToothState == .unknown {
            NSLog("Scanning blueToothState [unknown] = \(blueToothState)")
            //startScan will be called from changes BLE state
            return
        } else if !isBleReady {
            NSLog("Scanning blueToothState [\(blueToothState)]")
            scanJob?.failed(SJError.bleNotEnabled)
            clearResults()
            return
        }
        
        clearResults()
        do {
            try performScan()
        } catch let error {
            onFail(SJResult(error: SJError.sjException, data: error))
        }
        
    }
    
    private func performScan() throws {
        let job = scanJob!
        manager.scanForPeripherals(withServices: [job.device.advService], options: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + job.duration)
        { [weak self] in
            self?.stopScanForBLEDevices()
        }
    }
    
    
    func stopScanForBLEDevices(_ discovered: CBPeripheral? = nil) {
        NSLog("STOP Scanning BLE Devices", "peripherals: \(peripherals.count)")
        manager.stopScan()
        if let job = scanJob, job.completed == false {
            if discovered != nil {
                job.discovered(ble: discovered!)
            } else {
                job.failed(SJError.bleDeviceNotFound)
            }
        }
        clearResults()
    }
    
    func clearResults() {
        scanJob = nil
        peripherals = []
    }
}


@available(iOS 10.0, *)
extension SJBleScanner: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let job = scanJob else { return }
        
        if(!peripherals.contains(peripheral)) {
            //NSLog("Discoivered Peripheral", peripheral.name ?? "Unknown",advertisementData,RSSI,advertisementData["kCBAdvDataServiceUUIDs"])
            NSLog("SCANNER Discoivered UNKNOWN Device \(peripheral.name) | \(advertisementData)| \(RSSI)")
            if peripheral.name == job.device.bleName {
                stopScanForBLEDevices(peripheral)
            }
            peripherals.append(peripheral)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        blueToothState = central.state
        print("SCANNER centralManagerDidUpdateState called [\(central.state.rawValue)]")
        guard let job = scanJob else { return }
        
        switch central.state {
        case .unknown:
            job.failed(SJError.bleProtocolError)
        case .unsupported:
            job.failed(SJError.bleNotSupported)
        case .unauthorized:
            job.failed(SJError.blePermissionsNotGranted)
        case .poweredOff:
            job.failed(SJError.bleNotEnabled)
        default:
            NSLog("SCANNER try performScan from central.state")
            try? performScan()
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        NSLog("SCANNER centralManager willRestoreState", dict)
    }
}
