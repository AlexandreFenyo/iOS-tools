//
//  LocalChargenClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class LocalChargenClient : Thread {
    let address : IPAddress

    override public func main() {
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

    public init(address: IPAddress) {
        localChargenClientInit()
        self.address = address
    }

    public func close() {
        localChargenClientClose()
    }
}
