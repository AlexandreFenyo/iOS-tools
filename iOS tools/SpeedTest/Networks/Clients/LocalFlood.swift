//
//  LocalFlood.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 22/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class LocalFloodClient : Thread {
    private let address : IPAddress
    private var last_nwrite : Int?
    private var last_date : Date?
    
    // Dedicated background Thread
    override internal func main() {
        print("CLIENT ENTREE THREAD", address)
        
        if let saddr = address.toSockAddress()?.saddrdata {
            saddr.withUnsafeBytes {
                (ump: UnsafeRawBufferPointer) in
                let retval = localFloodClientLoop(OpaquePointer(ump.bindMemory(to: sockaddr_storage.self).baseAddress!))
                print("retval:", retval)
            }
        }
        
        print("CLIENT SORTIE THREAD")
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
            fatalError()
        }
        self.address = address
    }
    
    // Main thread
    public func close() {
        let ret = localFloodClientClose()
        if ret != 0 {
            fatalError()
        }
    }
    
    // Main thread
    public func stop() {
        let ret = localFloodClientStop()
        if ret != 0 {
            fatalError()
        }
    }
    
    // Main thread
    public func getNWrite() -> Int {
        let ret = localFloodClientGetNWrite()
        if ret < 0 { fatalError() }
        return ret
    }
    
    // Main thread
    public func getThroughput() -> Double {
        let ret = localFloodClientGetNWrite()
        if ret < 0 { fatalError() }
        let now = Date()
        let retval = 8 * Double.init(ret - last_nwrite!) / now.timeIntervalSince(last_date!)
        last_nwrite = ret
        last_date = now
        return retval
    }
}
