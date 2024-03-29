//
//  LocalChargenClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import iOSToolsMacros

actor LocalChargenSync {
    private let local_chargen_client: LocalChargenClient
    
    public func close() {
        local_chargen_client.close()
    }
    
    public func stop() {
        local_chargen_client.stop()
    }
    
    init(_ local_chargen_client: LocalChargenClient) {
        self.local_chargen_client = local_chargen_client
    }
}

class LocalChargenClient : Thread {
    private let address : IPAddress
    private var last_nread : Int?
    private var last_date : Date?

    // Dedicated background Thread
    override internal func main() {
        if let saddr = address.toSockAddress()?.getData() {
            _ = saddr.withUnsafeBytes {
                localChargenClientLoop(OpaquePointer($0.bindMemory(to: sockaddr_storage.self).baseAddress!))
            }
        }
    }
    
    override public func start() {
        last_nread = 0
        last_date = Date()
        super.start()
    }

    // Main thread
    public init(address: IPAddress) {
        let ret = localChargenClientOpen()
        if ret != 0 {
            #fatalError("init")
        }
        self.address = address
    }

    // Main thread
    public func close() {
        let ret = localChargenClientClose()
        if ret != 0 {
            // Ca arrive quand j'utiliser simulateur iPadPro 12.9Po et que je fais une heat map
            _ = #saveTrace("fatalError 1")
//            fatalError()
        }
    }

    // Main thread
    public func stop() {
        let ret = localChargenClientStop()
        if ret != 0 {
            _ = #saveTrace("fatalError 2")
//            fatalError()
        }
    }

    // Main thread
    public func getNRead() -> Int {
        let ret = localChargenClientGetNRead()
        if ret < 0 { #fatalError("getNRead") }
        return ret
    }
    
    // Main thread
    public func getLastErrno() -> Int32 {
        let ret = localChargenClientGetLastErrorNo()
        if ret < 0 { #fatalError("getLastErrno") }
        return ret
    }

    // Main thread
    public func getThroughput() -> Double {
        let ret = localChargenClientGetNRead()
        if ret < 0 {
            return Double(ret)
        }
        let now = Date()
        let retval = 8 * Double.init(ret - last_nread!) / now.timeIntervalSince(last_date!)
        last_nread = ret
        last_date = now
        return retval
    }
}
