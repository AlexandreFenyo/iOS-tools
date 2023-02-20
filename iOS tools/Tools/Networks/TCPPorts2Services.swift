//
//  TCPPorts2Services.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 01/10/2022.
//  Copyright © 2022 Alexandre Fenyo. All rights reserved.
//

import Foundation

// pour produire le fichier de conf :
// cat /etc/services | grep /tcp | grep -v /udp | egrep -v '^(#| )' | sed 's,/tcp.*,,' | awk '{ print $2" "$1; }' | sort -u -nk 1

public var TCPPort2Service: [UInt16 : String] = [:]
public var TCPPort2Description: [UInt16 : String] = [:]
public var StandardTCPPorts = Set<UInt16>(1...1023) // environ 5200 ports
public var ReducedStandardTCPPorts: Set<UInt16> = Set([4, 9, 19, 20, 21, 22, 23, 25, 53, 80, 81, 82, 110, 143, 443, 445, 465, 513, 514, 587, 993, 995, 3020, 8080, 8081, 8082]) // environ 30 ports

public func InitTCPPort2Service() {
    if let filepath = Bundle.main.path(forResource: "tcpports", ofType: "txt") {
        do {
            let contents = try String(contentsOfFile: filepath)
            for line in contents.split(separator: "\n") {
                let fields = line.split(separator: ";")
                if fields.count >= 2 {
                    if let port = UInt16(fields[0]) {
                        TCPPort2Service[port] = String(fields[1])
                        StandardTCPPorts.insert(port)
                    }
                }
                if fields.count >= 3 {
                    if let port = UInt16(fields[0]) {
                        TCPPort2Description[port] = String(fields[2])
                        StandardTCPPorts.insert(port)
                    }
                }
            }
        } catch {
            fatalError("no tcpports.txt bundled file")
        }
    }
}
