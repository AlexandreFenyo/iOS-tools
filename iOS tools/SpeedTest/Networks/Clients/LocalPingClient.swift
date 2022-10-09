
//
//  LocalPingClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

actor LocalPingSync {
    private let local_ping_client: LocalPingClient
    
    public func close() {
        local_ping_client.close()
    }
    
    public func stop() {
        local_ping_client.stop()
    }
    
    init(_ local_ping_client: LocalPingClient) {
        self.local_ping_client = local_ping_client
    }
}

class LocalPingClient : Thread {
    private let address : IPAddress
    private var last_nread : Int?
    private var last_date : Date?
    private let count : Int32
    
    // Dedicated background Thread
    override internal func main() {
        if let saddr = address.toSockAddress()?.getData() {
            _ = saddr.withUnsafeBytes {
                localPingClientLoop(OpaquePointer($0.bindMemory(to: sockaddr_storage.self).baseAddress!), count)
            }
        }
    }
    
    override public func start() {
        last_nread = 0
        last_date = Date()
        super.start()
    }
    
    // Main thread ou user initiated thread
    public init(address: IPAddress, count: Int32) {
        let ret = localPingClientOpen()
        if ret != 0 {
            fatalError()
        }
        self.address = address
        self.count = count
    }
    
    // Main thread ou user initiated thread
    public func close() {
        let ret = localPingClientClose()
        if ret != 0 {
            fatalError()
        }
    }
    
    // Main thread ou user initiated thread
    fileprivate func stop() {
        let ret = localPingClientStop()
        if ret != 0 {
            fatalError()
        }
    }
    
    // Main thread ou user initiated thread
    func getRTT() -> Int {
        let ret = localPingClientGetRTT()
        if ret < 0 { fatalError() }
        return ret
    }
}
