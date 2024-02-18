//
//  Ports2BonjourServices.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 18/02/2024.
//  Copyright © 2024 Alexandre Fenyo. All rights reserved.
//

import Foundation
import iOSToolsMacros

//  We do not need a static table for this dictionary, it is populated dynamically each time a service is advertised. Note that for each port, only the latest service name is saved. Previous service names are erased.
let ports_to_bonjour_services = Ports2BonjourServices()

actor Ports2BonjourServices {
    private var port_to_bonjour_service: [Port : BonjourServiceName] = [:]

    func add(_ port: Port, _ val: BonjourServiceName) {
        port_to_bonjour_service[port] = val
    }

    func get(_ port: Port) -> BonjourServiceName? {
        return port_to_bonjour_service[port]
    }
}
