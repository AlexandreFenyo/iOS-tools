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
        print("CLIENT ENTREE")
        //        for i in 1...100000 {
        //            print(i)
        //        }
        print("CLIENT SORTIE")
    }

    init(address: IPAddress) {
        self.address = address
    }
}
