//
//  LocalChargenClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// Usage:

class LocalChargenClient : Thread {
    private let address : IPAddress
    private var last_nread : Int?
    private var last_date : Date?

    // Dedicated background Thread
    override internal func main() {
        print("CLIENT ENTREE THREAD", address)

        if let saddr = address.saddr {
            saddr.withUnsafeBytes {
                (ump: UnsafePointer<sockaddr>) in
                let retval = localChargenClientLoop(OpaquePointer(ump))
                print("retval:", retval)
            }
        }

        print("CLIENT SORTIE THREAD")
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
            fatalError()
        }
        self.address = address
    }

    // Main thread
    public func close() {
        let ret = localChargenClientClose()
        if ret != 0 {
            fatalError()
        }
    }

    // Main thread
    public func stop() {
        let ret = localChargenClientStop()
        if ret != 0 {
            fatalError()
        }
    }

    // Main thread
    public func getNRead() -> Int {
        let ret = localChargenClientGetNRead()
        if ret < 0 { fatalError() }
        return ret
    }

    // Main thread
    public func getThroughput() -> Double {
        let ret = localChargenClientGetNRead()
        if ret < 0 { fatalError() }
        let now = Date()
        let retval = 8 * Double.init(ret - last_nread!) / now.timeIntervalSince(last_date!)
        last_nread = ret
        last_date = now
        return retval
    }
}
