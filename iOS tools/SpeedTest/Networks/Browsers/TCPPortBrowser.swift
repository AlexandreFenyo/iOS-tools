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
        
        let dispatchGroup = DispatchGroup()

        device_manager.setInformation("browsing TCP ports")

        for addr in self.ip_to_tcp_port.keys {
            let s = socket(addr.getFamily(), SOCK_STREAM, getprotobyname("tcp").pointee.p_proto)
            if s < 0 {
                GenericTools.perror("socket")
                fatalError("browse: socket")
            }
            
            var tv = timeval(tv_sec: 1, tv_usec: 0)
            var ret = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
            if ret < 0 {
                GenericTools.perror("setsockopt")
                close(s)
                fatalError("browse: setsockopt")
            }
        
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                print("TCP browse ADDRESSE :", addr.toNumericString())
                for port in self.ip_to_tcp_port[addr]! {
                    print(addr.toNumericString(), ":", port)

                    addr.toSockAddress()
                    
                    let ret = addr.toSockAddress()!.sockaddr.withUnsafeBytes { (sockaddr : UnsafePointer<sockaddr>) in
                        connect(s, sockaddr, addr.getFamily() == AF_INET ? UInt32(MemoryLayout<sockaddr_in>.size) : UInt32(MemoryLayout<sockaddr_in6>.size))
                    }
                    
                    print("ret=", ret)
                    perror("connect")
                    
                }

                

                close(s)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()
        print("TCP browse ADDRESSE: FIN")
        
        device_manager.setInformation("")
    }

    // Browse a set of networks
    // Main thread
    public init(device_manager: DeviceManager) {
        self.device_manager = device_manager
    }
}
