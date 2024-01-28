
//
//  LocalPingClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import iOSToolsMacros

class LocalPingClient : Thread {
    private let address: IPAddress
    private var last_nread: Int?
    private var last_date: Date?
    private let count: Int32
    private let initial_delay: useconds_t
    
    // Dedicated background Thread
    override internal func main() {
        if let saddr = address.toSockAddress()?.getData() {
            _ = saddr.withUnsafeBytes {
                localPingClientLoop(OpaquePointer($0.bindMemory(to: sockaddr_storage.self).baseAddress!), count, initial_delay)
            }
        }
    }
    
    override func start() {
        last_nread = 0
        last_date = Date()
        super.start()
    }
    
    // Main thread ou user initiated thread
    init(address: IPAddress, count: Int32, initial_delay: useconds_t) {
        let ret = localPingClientOpen()
        if ret != 0 {
            #fatalError("init")
        }
        self.address = address
        self.count = count
        self.initial_delay = initial_delay
    }
    
    // Main thread ou user initiated thread
    func close() {
        let ret = localPingClientClose()
        if ret != 0 {
            #fatalError("close")
        }
    }
    
    // Main thread ou user initiated thread
    func stop() {
        let ret = localPingClientStop()
        if ret != 0 {
            #fatalError("stop")
        }
    }
    
    // Main thread ou user initiated thread
    func getRTT() -> Int {
        let ret = localPingClientGetRTT()
        if ret < 0 {
            print("Warning: rtt < 0, this may occur because of a change of the delay between two probes")
            return 0
        }
        return ret
    }

    // Main thread ou user initiated thread
    func isInsideLoop() -> Int {
        let ret = localPingClientIsInsideLoop()
        if ret < 0 {
            print("Warning: isInsideLoop < 0, this may occur because of a problem with a mutex")
            return 0
        }
        return ret
    }

    func setDelay(delay: useconds_t) {
        let ret = localPingClientSetDelay(delay);
        if ret != 0 {
            #fatalError("setDelay")
        }
    }
}
