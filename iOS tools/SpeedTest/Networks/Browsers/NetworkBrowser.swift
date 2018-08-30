//
//  NetworkBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 27/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class NetworkBrowser {
    private let network : IPv4Address
    private let netmask : IPv4Address

    public init?(network: IPv4Address?, netmask: IPv4Address?) {
        if network == nil || netmask == nil { return nil }
        self.network = network!
        self.netmask = netmask!
    }
    
    public func browse() {
        // DispatchQueue
        
        let last = network.or(netmask.xor(IPv4Address("255.255.255.255")!))
        var current = network.and(netmask).next()
        repeat {
            print(current.getNumericAddress())
            
            current = current.next()
        } while current != last
    }
        
        
}
