//
//  GenericNetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 19/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class SockAddr : Equatable, NSCopying {
    public let sockaddr : Data

    public init?(_ sockaddr: Data) {
        self.sockaddr = sockaddr
    }

    public static func getSockAddr(_ sockaddr: Data) -> SockAddr {
        let family = sockaddr.withUnsafeBytes { (bytes : UnsafePointer<sockaddr>) -> UInt8 in bytes.pointee.sa_family }
        switch Int32(family) {
        case AF_INET:
                return SockAddr4(sockaddr)!
            
        case AF_INET6:
            return SockAddr6(sockaddr)!

        default:
            fatalError("bad address family")
        }
    }
    
    public func getIPAddress() -> IPAddress? {
        return nil
    }
    
    // Warning: an address like fe81:abcd:: may throw an error because 'cd' contains the scope, and it must be the index of an existing interface
    private func getNameInfo(_ flags: Int32) -> String? {
        return sockaddr.withUnsafeBytes {
            (bytes : UnsafePointer<sockaddr>) -> String? in
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let ret = getnameinfo(bytes, UInt32(MemoryLayout<sockaddr>.size), &buffer, UInt32(NI_MAXHOST), nil, 0, flags)
            if ret != 0 {
                print("getNameInfo error:")
                puts(gai_strerror(ret))
            }
            return ret == 0 ? String(cString: buffer) : nil
        }
    }

    public func resolveHostName() -> String? {
        return getNameInfo(NI_NAMEREQD)
    }

    public func toNumericString() -> String? {
        return getNameInfo(NI_NUMERICHOST)
    }
    
    public func getFamily() -> Int32 {
        return Int32(sockaddr.withUnsafeBytes { (bytes : UnsafePointer<sockaddr>) -> UInt8 in bytes.pointee.sa_family })
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
        let family = sockaddr.withUnsafeBytes { (bytes : UnsafePointer<sockaddr_in>) -> UInt8 in bytes.pointee.sin_family }
        if family != AF_INET { return nil }
        super.init(sockaddr)
    }
    
    public override func getIPAddress() -> IPAddress {
        return sockaddr.withUnsafeBytes { (bytes : UnsafePointer<sockaddr_in>) -> IPAddress in
            var in_addr = bytes.pointee.sin_addr
            return IPv4Address(NSData(bytes: &in_addr, length: MemoryLayout<in_addr>.size) as Data)
        }
    }
    
    public override func getFamily() -> Int32 {
        return AF_INET
    }
}

class SockAddr6 : SockAddr {
    public override init?(_ sockaddr: Data) {
        let family = sockaddr.withUnsafeBytes { (bytes : UnsafePointer<sockaddr_in6>) -> UInt8 in bytes.pointee.sin6_family }
        if family != AF_INET6 { return nil }
        super.init(sockaddr)
    }
    
    public override func getIPAddress() -> IPAddress {
        return sockaddr.withUnsafeBytes { (bytes : UnsafePointer<sockaddr_in6>) -> IPAddress in
            var in6_addr = bytes.pointee.sin6_addr
            return IPv6Address(NSData(bytes: &in6_addr, length: MemoryLayout<in6_addr>.size) as Data, scope: bytes.pointee.sin6_scope_id)
        }
    }

    public override func getFamily() -> Int32 {
        return AF_INET6
    }
}

class IPAddress : Equatable, NSCopying, Comparable, Hashable {
    public let inaddr : Data

    var hashValue: Int {
        return inaddr.hashValue
    }

    public init(_ inaddr: Data) {
        self.inaddr = inaddr
    }

    public init(mask_len: UInt8, data_size: Int) {
        inaddr = Data(count: data_size)
        inaddr.withUnsafeMutableBytes { (b: UnsafeMutablePointer<UInt8>) in
            var byte = 0, bit = 7
            for _ in 0..<mask_len {
                b[byte] |= 1<<bit
                bit -= 1
                if bit < 0 {
                    byte += 1
                    bit = 7
                }
            }
        }
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
    
    // Only IPv6 addresses can return nil
    public func toNumericString() -> String? {
        return toSockAddress()!.toNumericString()
    }

    private func map(netmask: IPAddress, _ map: (UInt8, UInt8) -> UInt8) -> Data {
        if netmask.inaddr.count != inaddr.count { fatalError("incompatible types") }

        var addr = inaddr
        var mask_bytes = [UInt8](netmask.inaddr)
        
        addr.withUnsafeMutableBytes { (bytes : UnsafeMutablePointer<UInt8>) in
            for idx in 0..<mask_bytes.count { bytes[idx] = map(bytes[idx], mask_bytes[idx]) }
        }
        
        return addr
    }

    public func _and(_ netmask: IPAddress) -> Data {
        return map(netmask: netmask) { $0 & $1 }
    }

    public func _or(_ netmask: IPAddress) -> Data {
        return map(netmask: netmask) { $0 | $1 }
    }

    public func _xor(_ netmask: IPAddress) -> Data {
        return map(netmask: netmask) { $0 ^ $1 }
    }

    public func and(_ netmask: IPAddress) -> IPAddress {
        fatalError("and on IPAddress")
    }
    
    public func or(_ netmask: IPAddress) -> IPAddress {
        fatalError("or on IPAddress")
    }
    
    public func xor(_ netmask: IPAddress) -> IPAddress {
        fatalError("xor on IPAddress")
    }

    public func next() -> IPAddress {
        fatalError("next on IPAddress")
    }

    static func == (lhs: IPAddress, rhs: IPAddress) -> Bool {
        return lhs.inaddr == rhs.inaddr
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return IPAddress(inaddr)
    }
    
    static func < (lhs: IPAddress, rhs: IPAddress) -> Bool {
        var x = lhs
        var y = rhs
        
        return withUnsafeBytes(of: &x) { (xp) -> Bool in
            withUnsafeBytes(of: &y, { (yp) -> Bool in
                if xp.count != yp.count { fatalError() }
                for i in 0..<xp.count { if xp[i] != yp[i] { return xp[i] < yp[i] } }
                return false
            })
        }
    }
}

class IPv4Address : IPAddress {
    public convenience init?(_ address: String) {
        var data = Data(count: MemoryLayout<in_addr>.size)
        let ret = data.withUnsafeMutableBytes { (bytes : UnsafeMutablePointer<in_addr>) -> Int32 in address.withCString { inet_aton($0, &bytes.pointee) } }
        if ret != 1 { return nil }
        self.init(data)
    }

    public convenience init(mask_len: UInt8) {
        self.init(mask_len: mask_len, data_size: MemoryLayout<in_addr>.size)
    }

    public override func getFamily() -> Int32 {
        return AF_INET
    }

    public override func toSockAddress() -> SockAddr? {
        let in_addr = inaddr.withUnsafeBytes { (bytes : UnsafePointer<in_addr>) -> in_addr in bytes.pointee }
        
        var data = Data(count: MemoryLayout<sockaddr_in>.size)
        data.withUnsafeMutableBytes { (bytes : UnsafeMutablePointer<sockaddr_in>) in
            bytes.pointee.sin_addr = in_addr
            bytes.pointee.sin_len = UInt8(MemoryLayout<in_addr>.size)
            bytes.pointee.sin_family = UInt8(AF_INET)
        }

        return SockAddr(data)
    }

    public override func next() -> IPAddress {
        var inaddr = self.inaddr
        inaddr.reverse()
        inaddr.withUnsafeMutableBytes { (bytes : UnsafeMutablePointer<UInt32>) in bytes.pointee += 1 }
        inaddr.reverse()
        return IPv4Address(inaddr)
    }
    
    public override func and(_ netmask: IPAddress) -> IPAddress {
        return IPv4Address(super._and(netmask))
    }

    public override func or(_ netmask: IPAddress) -> IPAddress {
        return IPv4Address(super._or(netmask))
    }

    public override func xor(_ netmask: IPAddress) -> IPAddress {
        return IPv4Address(super._xor(netmask))
    }

    private func bytes() -> [UInt8] {
        return inaddr.withUnsafeBytes { (bytes : UnsafePointer<UInt8>) -> [UInt8] in [ bytes[0], bytes[1], bytes[2], bytes[3] ] }
    }
    
    // private => unicast
    public func isPrivate() -> Bool {
        return bytes()[0] == 10 || (bytes()[0] == 192 && bytes()[1] == 168) || (bytes()[0] == 172 && (bytes()[1] >= 16 && bytes()[1] < 32))
    }

    // unicast
    public func isUnicast() -> Bool {
        return bytes()[0] < 224
    }

    // autoconfig => { not private, unicast }
    public func isAutoConfig() -> Bool {
        return bytes()[0] == 169 && bytes()[1] == 254
    }

    // local => { private, unicast }
    public func isLocal() -> Bool {
        return bytes()[0] == 127
    }
}

class IPv6Address : IPAddress {
    // scope zone index
    let scope : UInt32

    override var hashValue: Int {
        return super.hashValue &+ scope.hashValue
    }

    public init(_ inaddr: Data, scope: UInt32 = 0) {
        self.scope = scope
        super.init(inaddr)
    }

    public init(mask_len: UInt8) {
        scope = 0
        super.init(mask_len: mask_len, data_size: MemoryLayout<in6_addr>.size)
    }

    public convenience init?(_ address: String) {
        var data = Data(count: MemoryLayout<in6_addr>.size)
        let ret = data.withUnsafeMutableBytes { (bytes : UnsafeMutablePointer<in6_addr>) -> Int32 in address.withCString { inet_pton(AF_INET6, $0, &bytes.pointee) } }
        if ret != 1 { return nil }
        self.init(data)
    }

    public override func getFamily() -> Int32 {
        return AF_INET6
    }

    public override func toSockAddress() -> SockAddr? {
        let in6_addr = inaddr.withUnsafeBytes { (bytes : UnsafePointer<in6_addr>) -> in6_addr in bytes.pointee }
        
        var data = Data(count: MemoryLayout<sockaddr_in6>.size)
        data.withUnsafeMutableBytes {
            (bytes : UnsafeMutablePointer<sockaddr_in6>) in
            bytes.pointee.sin6_addr = in6_addr
            bytes.pointee.sin6_scope_id = scope
            bytes.pointee.sin6_len = UInt8(MemoryLayout<in6_addr>.size)
            bytes.pointee.sin6_family = UInt8(AF_INET6)
        }
        
        return SockAddr(data)
    }

    public override func and(_ netmask: IPAddress) -> IPAddress {
        return IPv6Address(super._and(netmask), scope: scope)
    }

    public override func or(_ netmask: IPAddress) -> IPAddress {
        return IPv6Address(super._or(netmask), scope: scope)
    }

    public override func xor(_ netmask: IPAddress) -> IPAddress {
        return IPv6Address(super._xor(netmask), scope: scope)
    }

    public override func next() -> IPAddress {
        fatalError("next on IPv6Address")
    }

    public func isULA() -> Bool {
        return and(IPv6Address("fe00::")!) == IPv6Address("fc00::")
    }

    public func isLLA() -> Bool {
        return and(IPv6Address("ffc0::")!) == IPv6Address("fe80::")
    }

    public func isUnicastPublic() -> Bool {
        return and(IPv6Address("e000::")!) == IPv6Address("2000::")
    }

    public func isMulticastPublic() -> Bool {
        return and(IPv6Address("ff00::")!) == IPv6Address("ff00::")
    }

    public func isReserved() -> Bool {
        return and(IPv6Address("ff00::")!) == IPv6Address("::")
    }
}

struct IPNetwork : Hashable {
    public let ip_address : IPAddress
    public let mask_len : UInt8
    
    public var hashValue: Int {
        return ip_address.hashValue &+ mask_len.hashValue
    }

    public init(ip_address: IPAddress, mask_len: UInt8) {
        self.ip_address = ip_address
        self.mask_len = mask_len
    }
}

final class NetTools {
}
