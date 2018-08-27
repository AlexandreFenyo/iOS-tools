//
//  NetworkBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 27/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class NetworkBrowser {
    private let network : IPv4SAddress
    private let netmask : IPv4SAddress

    public init?(network: IPv4SAddress?, netmask: IPv4SAddress?) {
        if network == nil || netmask == nil { return nil }
        self.network = network!
        self.netmask = netmask!
    }
    
    public func browse() {
        // DispatchQueue

        // network.next()
    }
        
        
}
