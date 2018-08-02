//
//  LocalChargenClient.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class LocalChargenClientThread : Thread {
    override public func main() {
        print("CLIENT ENTREE")
        print("CLIENT SORTIE")
    }
}

class LocalChargenClient {
    let thread : LocalChargenClientThread?

    init() {
        thread = LocalChargenClientThread()
        thread!.start()
    }
}
