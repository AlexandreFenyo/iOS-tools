//
//  LocalFlood.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 22/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import iOSToolsMacros

actor LocalFloodSync {
    private let local_flood_client: LocalFloodClient
    
    public func close() {
        local_flood_client.close()
    }
    
    public func stop() {
        local_flood_client.stop()
    }
    
    init(_ local_flood_client: LocalFloodClient) {
        self.local_flood_client = local_flood_client
    }
}

class LocalFloodClient : Thread {
    private let address : IPAddress
    private var last_nwrite : Int?
    private var last_date : Date?
    
    // Dedicated background Thread
    override internal func main() {
        if let saddr = address.toSockAddress()?.getData() {
            _ = saddr.withUnsafeBytes {
                localFloodClientLoop(OpaquePointer($0.bindMemory(to: sockaddr_storage.self).baseAddress!))
            }
        }
    }
    
    override public func start() {
        last_nwrite = 0
        last_date = Date()
        super.start()
    }
    
    // Main thread
    public init(address: IPAddress) {
        let ret = localFloodClientOpen()
        if ret != 0 {
            #fatalError("init")
        }
        self.address = address
    }
    
    // Main thread
    fileprivate func close() {
        let ret = localFloodClientClose()
        if ret != 0 {
            #fatalError("close")
        }
    }
    
    // Main thread
    fileprivate func stop() {
        let ret = localFloodClientStop()
        if ret != 0 {
            #fatalError("stop")
        }
    }
    
    // Main thread
    public func getNWrite() -> Int {
        let ret = localFloodClientGetNWrite()
        if ret < 0 { #fatalError("getNWrite") }
        return ret
    }
    
    // Main thread
    public func getThroughput() -> Double {
        let ret = localFloodClientGetNWrite()
        if ret < 0 { #fatalError("getThroughput") }
        let now = Date()
        let retval = 8 * Double.init(ret - last_nwrite!) / now.timeIntervalSince(last_date!)
        last_nwrite = ret
        last_date = now
        return retval
    }
}
