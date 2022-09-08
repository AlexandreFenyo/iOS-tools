//
//  Defaults.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 30/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// Default values
struct NetworkDefaults {
    public static let speed_test_chargen_port: UInt16 = 19
    public static let speed_test_discard_port: UInt16 = 9
    public static let buffer_size = 3000
    public static let local_domain_for_browsing = "local."
    public static let speed_test_chargen_service_type = "_speedtestchargen._tcp."
    public static let speed_test_discard_service_type = "_speedtestdiscard._tcp."
    public static let n_icmp_echo_reply = 3
}
