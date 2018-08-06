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
                LocalChargenClientLoop(OpaquePointer(ump))
            }
        }

        print("CLIENT SORTIE THREAD")
    }

    init(address: IPAddress) {
        self.address = address
    }
}
