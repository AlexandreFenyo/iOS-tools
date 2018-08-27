//
//  GenericNetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 19/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class SockAddr : Equatable, NSCopying {
    // struct sockaddr
    public let sockaddr : Data

    public init?(_ sockaddr: Data) {
        self.sockaddr = sockaddr
    }

    public func getIPAddress() -> IPAddress? {
        return nil
    }
    
    private func getNameInfo(_ flags: Int32) -> String? {
        return sockaddr.withUnsafeBytes {
            (bytes : UnsafePointer<sockaddr>) -> String? in
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let ret = getnameinfo(bytes, UInt32(MemoryLayout<sockaddr>.size), &buffer, UInt32(NI_MAXHOST), nil, 0, flags)
            return ret != 0 ? String(cString: buffer) : nil
        }
    }

    public func resolveHostName() -> String? {
        return getNameInfo(NI_NAMEREQD)
    }

    public func getNumericAddress() -> String? {
        return getNameInfo(NI_NUMERICHOST)
    }
    
    public func getFamily() -> Int32 {
        fatalError("getFamily() on SockAddr")
    }

    static func == (lhs: SockAddr, rhs: SockAddr) -> Bool {
        return lhs.sockaddr == rhs.sockaddr
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return SockAddr(sockaddr)!
    }
}

class SockAddr4 : SockAddr {
    public override init?(_ sockaddr: Data) {
        let family = sockaddr.withUnsafeBytes {
            (bytes : UnsafePointer<sockaddr_in>) -> UInt8 in
            return bytes.pointee.sin_family
        }
        if family != AF_INET { return nil }
        super.init(sockaddr)
    }
    
    public override func getIPAddress() -> IPAddress {
        return sockaddr.withUnsafeBytes {
            (bytes : UnsafePointer<sockaddr_in>) -> IPAddress in
            var in_addr = bytes.pointee.sin_addr
            return IPv4Address(NSData(bytes: &in_addr, length: Int(bytes.pointee.sin_len)) as Data)
        }
    }
    
    public override func getFamily() -> Int32 {
        return AF_INET
    }
}

class SockAddr6 : SockAddr {
    public override init?(_ sockaddr: Data) {
        let family = sockaddr.withUnsafeBytes {
            (bytes : UnsafePointer<sockaddr_in6>) -> UInt8 in
            return bytes.pointee.sin6_family
        }
        if family != AF_INET6 { return nil }
        super.init(sockaddr)
    }
    
    public override func getIPAddress() -> IPAddress {
        return sockaddr.withUnsafeBytes {
            (bytes : UnsafePointer<sockaddr_in6>) -> IPAddress in
            var in6_addr = bytes.pointee.sin6_addr
            return IPv6Address(NSData(bytes: &in6_addr, length: Int(bytes.pointee.sin6_len)) as Data)
        }
    }
    
    public override func getFamily() -> Int32 {
        return AF_INET6
    }
}

class IPAddress : Equatable, NSCopying {
    // struct in_addr
    public let inaddr : Data

    public init(_ inaddr: Data) {
        self.inaddr = inaddr
    }
    
    public func getFamily() -> Int32 {
        fatalError("getFamily() on IPAddress")
    }

    public func toSockAddress() -> SockAddr? {
        fatalError("toSockAddress() on IPAddress")
    }

    public func resolveHostName() -> String {
        return toSockAddress()!.resolveHostName()!
    }
    
    public func getNumericAddress() -> String {
        return toSockAddress()!.getNumericAddress()!
    }

    static func == (lhs: IPAddress, rhs: IPAddress) -> Bool {
        return lhs.inaddr == rhs.inaddr
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return IPAddress(inaddr)
    }
}

class IPv4Address : IPAddress {
    public convenience init?(_ address: String) {
        var data = Data(count: MemoryLayout<in_addr>.size)
        let ret = data.withUnsafeMutableBytes {
            (bytes : UnsafeMutablePointer<in_addr>) -> Int32 in
            return address.withCString {
                (ptr) -> Int32 in
                return inet_aton(ptr, &bytes.pointee)
            }
        }
        if ret != 1 { return nil }
        self.init(data)
    }

    public override func getFamily() -> Int32 {
        return AF_INET
    }

    public override func toSockAddress() -> SockAddr? {
        let in_addr = inaddr.withUnsafeBytes {
            (bytes : UnsafePointer<in_addr>) -> in_addr in
            return bytes.pointee
        }
        
        var data = Data(count: MemoryLayout<sockaddr_in>.size)
        data.withUnsafeMutableBytes {
            (bytes : UnsafeMutablePointer<sockaddr_in>) in
            bytes.pointee.sin_addr = in_addr
            bytes.pointee.sin_len = UInt8(MemoryLayout<in_addr>.size)
            bytes.pointee.sin_family = UInt8(AF_INET)
        }

        return SockAddr(data)
    }
}

class IPv6Address : IPAddress {
    public override func getFamily() -> Int32 {
        return AF_INET6
    }

    public override func toSockAddress() -> SockAddr? {
        let in6_addr = inaddr.withUnsafeBytes {
            (bytes : UnsafePointer<in6_addr>) -> in6_addr in
            return bytes.pointee
        }
        
        var data = Data(count: MemoryLayout<sockaddr_in6>.size)
        data.withUnsafeMutableBytes {
            (bytes : UnsafeMutablePointer<sockaddr_in6>) in
            bytes.pointee.sin6_addr = in6_addr
            bytes.pointee.sin6_len = UInt8(MemoryLayout<in6_addr>.size)
            bytes.pointee.sin6_family = UInt8(AF_INET6)
        }
        
        return SockAddr(data)
    }
}

class GenericNetTools {
//    // Data must be a sockaddr, sockaddr_in or sockaddr_in6 structure
//    public static func getHostNameFromSockAddr(_ addr: Data) -> String {
//        return addr.withUnsafeBytes {
//            (saddr : UnsafePointer<sockaddr>) -> String in
//            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
//            getnameinfo(saddr, UInt32(NSData(data: addr).length), &buffer, UInt32(NI_MAXHOST), nil, 0, NI_NAMEREQD)
//            return String(cString: buffer)
//        }
//    }
//
//    // Data must be a sockaddr, sockaddr_in or sockaddr_in6 structure
//    public static func getAddrFromSockAddr(_ addr: Data) -> String {
//        return addr.withUnsafeBytes {
//            (saddr : UnsafePointer<sockaddr>) -> String in
//            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
//            getnameinfo(saddr, UInt32(NSData(data: addr).length), &buffer, UInt32(NI_MAXHOST), nil, 0, NI_NUMERICHOST)
//            return String(cString: buffer)
//        }
//    }
//
//    // Result may be compared to AF_INET, AF_INET6, etc.
//    public static func getAddrFamilyFromSockAddr(_ addr: Data) -> Int32 {
//        var saddr = sockaddr_storage()
//        NSData(data: addr).getBytes(&saddr, length: MemoryLayout<sockaddr>.size)
//        return Int32(saddr.ss_family)
//    }
}
