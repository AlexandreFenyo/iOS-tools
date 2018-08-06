//
//  GenericNetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 19/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

struct IPAddress : Equatable {
    public enum IPAddressType : Int {
        case IPv4 = 0, IPv6
    }

    public let address : String
    public let type : IPAddressType
//    public let saddr : UnsafePointer<sockaddr>
    public let saddr : Data?

    public init(type: IPAddressType, address: String, saddr: Data?) {
        self.type = type
        self.address = address
        self.saddr = saddr
    }
}

class GenericNetTools {
    // Data must be a sockaddr, sockaddr_in or sockaddr_in6 structure
    public static func getHostNameFromSockAddr(_ addr: Data) -> String {
        return addr.withUnsafeBytes {
            (saddr : UnsafePointer<sockaddr>) -> String in
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(saddr, UInt32(NSData(data: addr).length), &buffer, UInt32(NI_MAXHOST), nil, 0, NI_NAMEREQD)
            return String(cString: buffer)
        }
    }

    // Data must be a sockaddr, sockaddr_in or sockaddr_in6 structure
    public static func getAddrFromSockAddr(_ addr: Data) -> String {
        return addr.withUnsafeBytes {
            (saddr : UnsafePointer<sockaddr>) -> String in
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(saddr, UInt32(NSData(data: addr).length), &buffer, UInt32(NI_MAXHOST), nil, 0, NI_NUMERICHOST)
            return String(cString: buffer)
        }
    }

    // Result may be compared to AF_INET, AF_INET6, etc.
    public static func getAddrFamilyFromSockAddr(_ addr: Data) -> Int32 {
        var saddr = sockaddr_storage()
        NSData(data: addr).getBytes(&saddr, length: MemoryLayout<sockaddr>.size)
        return Int32(saddr.ss_family)
    }
}
