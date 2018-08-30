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
// faire un tableau accessible en parallèle pour déterminer les tâches et positionner les résultats ? ou async sur main thread pour les résultats
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.concurrentPerform(iterations: NetworkDefaults.n_parallel_tasks) {
                idx in
                print("ITERATION \(idx) : début")
                sleep(5)
                print("ITERATION \(idx) : fin")
            }
        }

        print("après itérations")
        return
        
        let last = network.or(netmask.xor(IPv4Address("255.255.255.255")!))
        var current = network.and(netmask).next()
        repeat {
            print(current.getNumericAddress())

            
            current = current.next()
        } while current != last
    }
}
