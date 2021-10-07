
//
//  LocalPingClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class LocalPingClient : Thread {
    private let address : IPAddress
    private var last_nread : Int?
    private var last_date : Date?
    
    // Dedicated background Thread
    override internal func main() {
        print("CLIENT ENTREE THREAD PING", address)
        
        if let saddr = address.toSockAddress()?.getData() {
            let retval = saddr.withUnsafeBytes {
                localPingClientLoop(OpaquePointer($0.bindMemory(to: sockaddr_storage.self).baseAddress!))
            }
            print("localPingClientLoop() returned:", retval)
        }
        print("CLIENT SORTIE THREAD PING")
    }
    
    override public func start() {
        last_nread = 0
        last_date = Date()
        super.start()
    }
    
    // Main thread
    public init(address: IPAddress) {
        let ret = localPingClientOpen()
        if ret != 0 {
            fatalError()
        }
        self.address = address
    }
    
    // Main thread
    public func close() {
        let ret = localPingClientClose()
        if ret != 0 {
            fatalError()
        }
    }
    
    // Main thread
    public func stop() {
        let ret = localPingClientStop()
        if ret != 0 {
            fatalError()
        }
    }
    
    // Main thread
    public func getRTT() -> Int {
        let ret = localPingClientGetRTT()
        if ret < 0 { fatalError() }
        return ret
    }
    }
