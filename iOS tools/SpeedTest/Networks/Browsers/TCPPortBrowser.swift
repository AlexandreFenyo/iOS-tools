//
//  TCPPortBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 03/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class TCPPortBrowser {
    private static let ports_set : Set<UInt16> = Set(1..<1023).union(Set([8080, 3389, 5900, 6000]))
    private let device_manager : DeviceManager
    private var finished : Bool = false // Main thread
    private var ip_to_tcp_port : [IPAddress: Set<UInt16>] = [:]

    // Main thread
    public func stop() {
        finished = true
    }

    // Main thread
    public func browse() {
        // Initialize port lists to connect to
        for node in DBMaster.shared.nodes {
            if let addr = node.v4_addresses.first {
                ip_to_tcp_port[addr] = TCPPortBrowser.ports_set.subtracting(node.tcp_ports)
            } else if let addr = node.v6_addresses.first {
                ip_to_tcp_port[addr] = TCPPortBrowser.ports_set.subtracting(node.tcp_ports)
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let dispatchGroup = DispatchGroup()

            for addr in self.ip_to_tcp_port.keys {
                dispatchGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    print("TCP browse ADDRESSE :", addr.toNumericString())
                    dispatchGroup.leave()
                }
            }
                
            dispatchGroup.wait()
            print("TCP browse ADDRESSE: FIN")

            DispatchQueue.main.sync { self.device_manager.setInformation("") }
        }
    }

    // Browse a set of networks
    // Main thread
    public init(device_manager: DeviceManager) {
        self.device_manager = device_manager
    }
}
