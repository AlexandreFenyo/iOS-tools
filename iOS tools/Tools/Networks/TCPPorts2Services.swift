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

public var TCPPort2Service: [ UInt16: String ] = [:]

public func InitTCPPort2Service() {
    if let filepath = Bundle.main.path(forResource: "tcpports", ofType: "txt") {
        do {
            let contents = try String(contentsOfFile: filepath)
            for line in contents.split(separator: "\n") {
                let fields = line.split(separator: " ")
                if fields.count == 2 {
                    if let port = UInt16(fields[0]) {
                        TCPPort2Service[port] = String(fields[1])
                    }
                }
            }
        } catch {
            fatalError("no tcpports.txt bundled file")
        }
    }
}