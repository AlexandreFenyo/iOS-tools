//
//  LocalDiscardClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

actor LocalDiscardSync {
    private let local_discard_client: LocalDiscardClient
    
    public func close() {
        local_discard_client.close()
    }
    
    public func stop() {
        local_discard_client.stop()
    }
    
    init(_ local_discard_client: LocalDiscardClient) {
        self.local_discard_client = local_discard_client
    }
}

class LocalDiscardClient : Thread {
    private let address : IPAddress
    private var last_nwrite : Int?
    private var last_date : Date?
    
    // Dedicated background Thread
    override internal func main() {
        if let saddr = address.toSockAddress()?.getData() {
            _ = saddr.withUnsafeBytes {
                localDiscardClientLoop(OpaquePointer($0.bindMemory(to: sockaddr_storage.self).baseAddress!))
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
        let ret = localDiscardClientOpen()
        if ret != 0 {
            fatalError()
        }
        self.address = address
    }
    
    // Main thread
    public func close() {
        let ret = localDiscardClientClose()
        if ret != 0 {
            fatalError()
        }
    }
    
    // Main thread
    public func stop() {
        let ret = localDiscardClientStop()
        if ret != 0 {
            fatalError()
        }
    }
    
    // Main thread
    public func getNWrite() -> Int {
        let ret = localDiscardClientGetNWrite()
        if ret < 0 { fatalError() }
        return ret
    }

    // Main thread
    public func getLastErrno() -> Int32 {
        let ret = localChargenClientGetLastErrorNo()
        if ret < 0 { fatalError() }
        return ret
    }

    // Main thread
    public func getThroughput() -> Double {
        let ret = localDiscardClientGetNWrite()
        if ret < 0 {
            return Double(ret)
        }
        let now = Date()
        let retval = 8 * Double.init(ret - last_nwrite!) / now.timeIntervalSince(last_date!)
        last_nwrite = ret
        last_date = now
        return retval
    }
}
