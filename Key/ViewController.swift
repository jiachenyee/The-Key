//
//  ViewController.swift
//  Key
//
//  Created by JiaChen(: on 1/4/21.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController {
    
    var centralManager: CBCentralManager!
    var microBit: CBPeripheral?
    
    // Micro:bit's read and write UUIDs
    let readUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    let writeUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Just find the nearest micro:bit
        guard let name = peripheral.name,
              let regex = try? NSRegularExpression(pattern: "BBC micro:bit \\[[z|v|g|p|t][u|o|i|e|a][z|v|g|p|t][u|o|i|e|a][z|v|g|p|t]\\]",
                                                   options: []),
              regex.matches(in: name, options: [], range: NSRange(location: 0, length: name.count)).count == 1 else { return }
        
        microBit = peripheral
        
        // This is a micro:bit
        centralManager.connect(microBit!, options: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [],
                                              options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to", peripheral.name ?? "unnamed")
        
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected from", peripheral.name ?? "unnamed")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first else { return }
        
        peripheral.discoverCharacteristics([readUUID, writeUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == writeUUID {
            } else if characteristic.uuid == readUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let sourceRef = CGEventSource(stateID: .combinedSessionState)!
        
        guard let value = characteristic.value,
              let stringValue = String(data: value,
                                       encoding: .utf8) else { return }
        
        var keyCode: UInt16!
        
        var keyDownEvent: CGEvent?
        
        switch stringValue {
        case "R":
            keyCode = 15
            
            keyDownEvent = CGEvent(keyboardEventSource: sourceRef,
                                   virtualKey: keyCode,
                                   keyDown: true)
            
            keyDownEvent?.flags = [.maskCommand, .maskControl, .maskShift]
            
        case "C":
            keyCode = 8
            
            keyDownEvent = CGEvent(keyboardEventSource: sourceRef,
                                   virtualKey: keyCode,
                                   keyDown: true)
            
            keyDownEvent?.flags = .maskCommand
        case "V":
            keyCode = 9
            
            keyDownEvent?.flags = .maskCommand
            
            keyDownEvent = CGEvent(keyboardEventSource: sourceRef,
                                   virtualKey: keyCode,
                                   keyDown: true)
        case "Z":
            keyCode = 6
            
            keyDownEvent?.flags = .maskCommand
            
            keyDownEvent = CGEvent(keyboardEventSource: sourceRef,
                                   virtualKey: keyCode,
                                   keyDown: true)
        case "Z2":
            keyCode = 6
            
            keyDownEvent?.flags = [.maskCommand, .maskShift]
            
            keyDownEvent = CGEvent(keyboardEventSource: sourceRef,
                                   virtualKey: keyCode,
                                   keyDown: true)
            
            
        default: break
        }
        
        let keyUpEvent = CGEvent(keyboardEventSource: sourceRef,
                                 virtualKey: keyCode,
                                 keyDown: false)

        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
    }
}
