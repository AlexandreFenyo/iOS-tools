//
//  GenericNetTools.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 19/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// Règles :
// - on utilise de préférence des IPAddress plutôt que des SockAddr pour stocker des infos
// - les SockAddr permettent de convertir des sock_addr en IPAddress

import Foundation

class SockAddr : Equatable, NSCopying {
    public let saddrdata : Data

    public init?(_ saddrdata: Data) {
        self.saddrdata = saddrdata
    }

    public static func getSockAddr(_ saddrdata: Data) -> SockAddr {
        let family = saddrdata.withUnsafeBytes { (bytes : UnsafeRawBufferPointer) -> UInt8 in
            bytes.bindMemory(to: sockaddr.self).baseAddress!.pointee.sa_family
        }
        
        switch Int32(family) {
        case AF_INET:
                return SockAddr4(saddrdata)!
            
        case AF_INET6:
            return SockAddr6(saddrdata)!

        default:
            fatalError("bad address family")
        }
    }
    
    public func getIPAddress() -> IPAddress? {
        return nil
    }

    // pour debug
    public func _getNameInfo(_ flags: Int32) -> String? {
        return getNameInfo(flags)
    }

    // Warning: an address like fe81:abcd:: may throw an error because 'cd' contains the scope, and it must be the index of an existing interface
    private func getNameInfo(_ flags: Int32) -> String? {
        return saddrdata.withUnsafeBytes {
            (bytes : UnsafeRawBufferPointer) -> String? in
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let ret = getnameinfo(bytes.bindMemory(to: sockaddr.self).baseAddress!, UInt32(MemoryLayout<sockaddr>.size), &buffer, UInt32(NI_MAXHOST), nil, 0, flags)
            if ret != 0 {
                print("getNameInfo error: ", terminator: "")
                puts(gai_strerror(ret))
            }

            var retval = ""
            for idx in 0..<saddrdata.count {
                retval = retval + String(format: "%02x", saddrdata[idx])
                if idx + 1 < saddrdata.count { retval = retval + ":" }
            }
//            print("[", retval, "]")

            return ret == 0 ? String(cString: buffer) : nil
        }
    }

    public func getRawBytes() -> String {
        var retval = "raw bytes: "
        for idx in 0..<saddrdata.count {
            retval = retval + String(format: "%02x", saddrdata[idx])
            if idx + 1 < saddrdata.count { retval = retval + ":" }
        }
//        print("[", retval, "]")
        return retval
    }
    
    public func resolveHostName() -> String? {
        return getNameInfo(NI_NAMEREQD)
    }

    public func toNumericString() -> String? {
        return getNameInfo(NI_NUMERICHOST)
    }
    
    public func getFamily() -> Int32 {
        return Int32(saddrdata.withUnsafeBytes { (bytes : UnsafeRawBufferPointer) -> UInt8 in bytes.bindMemory(to: sockaddr.self).baseAddress!.pointee.sa_family })
    }

    static func == (lhs: SockAddr, rhs: SockAddr) -> Bool {
        return lhs.saddrdata == rhs.saddrdata
    }

    func copy(with zone: NSZone? = nil) -> Any {
        return SockAddr(saddrdata)!
    }
}

class SockAddr4 : SockAddr {
    public override init?(_ sockaddr: Data) {
        let family = sockaddr.withUnsafeBytes { (bytes : UnsafeRawBufferPointer) -> UInt8 in bytes.bindMemory(to: sockaddr_in.self).baseAddress!.pointee.sin_family }
        if family != AF_INET { return nil }
        super.init(sockaddr)
    }

    public override func getIPAddress() -> IPAddress {
        return saddrdata.withUnsafeBytes {
            var in_addr = $0.bindMemory(to: sockaddr_in.self).baseAddress!.pointee.sin_addr
            return IPv4Address(NSData(bytes: &in_addr, length: MemoryLayout<in_addr>.size) as Data)
        }
    }
    
    public override func getFamily() -> Int32 {
        return AF_INET
    }
}

class SockAddr6 : SockAddr {
    public override init?(_ sockaddr: Data) {
        let family = sockaddr.withUnsafeBytes { (bytes : UnsafeRawBufferPointer) -> UInt8 in bytes.bindMemory(to: sockaddr_in6.self).baseAddress!.pointee.sin6_family }
        if family != AF_INET6 { return nil }
        super.init(sockaddr)
    }
    
    public override func getIPAddress() -> IPAddress {
        return saddrdata.withUnsafeBytes {
            var in6_addr = $0.bindMemory(to: sockaddr_in6.self).baseAddress!.pointee.sin6_addr
            return IPv6Address(NSData(bytes: &in6_addr, length: MemoryLayout<in6_addr>.size) as Data, scope: $0.bindMemory(to: sockaddr_in6.self).baseAddress!.pointee.sin6_scope_id)
        }
    }

    public override func getFamily() -> Int32 {
        return AF_INET6
    }
}

class IPAddress /*:*/ /*Equatable,*/ /*NSCopying,*/ /*Comparable,*/ /*Hashable*/ : Hashable {
    public let inaddr : Data

    func hash(into hasher: inout Hasher) {
        hasher.combine(inaddr)
    }
    
    public init(_ inaddr: Data) {
        self.inaddr = inaddr
    }

    public init(mask_len: UInt8, data_size: Int) {
        var inaddr = Data(count: data_size)
        inaddr.withUnsafeMutableBytes {
            var byte = 0, bit = 7
            for _ in 0..<mask_len {
                $0[byte] |= 1<<bit
                bit -= 1
                if bit < 0 {
                    byte += 1
                    bit = 7
                }
            }
        }
        self.inaddr = inaddr
    }

    public func getFamily() -> Int32 {
        fatalError("getFamily() on IPAddress")
    }

    public func toSockAddress() -> SockAddr? {
        fatalError("toSockAddress() on IPAddress")
    }

    public func toSockAddress(port: UInt16) -> SockAddr? {
        fatalError("toSockAddress(port) on IPAddress")
    }
    
    public func resolveHostName() -> String? {
        return toSockAddress()!.resolveHostName()
    }
    
    // Only IPv6 addresses can return nil
    public func toNumericString() -> String? {
        return toSockAddress()!.toNumericString()
    }

    private func map(netmask: IPAddress, _ map: (UInt8, UInt8) -> UInt8) -> Data {
        if netmask.inaddr.count != inaddr.count { fatalError("incompatible types") }

        var addr = inaddr
        let mask_bytes = [UInt8](netmask.inaddr)
        
        addr.withUnsafeMutableBytes {
            for idx in 0..<mask_bytes.count { $0[idx] = map($0[idx], mask_bytes[idx]) }
        }
        
        return addr
    }

    fileprivate func _and(_ netmask: IPAddress) -> Data {
        return map(netmask: netmask) { $0 & $1 }
    }

    fileprivate func _or(_ netmask: IPAddress) -> Data {
        return map(netmask: netmask) { $0 | $1 }
    }

    fileprivate func _xor(_ netmask: IPAddress) -> Data {
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
        fatalError("copy() on IPAddress")
        // return IPAddress(inaddr)
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

class IPv4Address : IPAddress, Comparable {
    public convenience init?(_ address: String) {
        var data = Data(count: MemoryLayout<in_addr>.size)
        let ret = data.withUnsafeMutableBytes { (bytes : UnsafeMutableRawBufferPointer) -> Int32 in address.withCString { inet_aton($0, bytes.bindMemory(to: in_addr.self).baseAddress) } }
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
        return toSockAddress(port: 0)
    }

    public override func toSockAddress(port: UInt16) -> SockAddr? {
        let my_in_addr = inaddr.withUnsafeBytes { (bytes : UnsafeRawBufferPointer) -> in_addr in bytes.bindMemory(to: in_addr.self).baseAddress!.pointee }
        
        var data = Data(count: MemoryLayout<sockaddr_in>.size)
        data.withUnsafeMutableBytes {
            $0.bindMemory(to: sockaddr_in.self).baseAddress!.pointee.sin_addr = my_in_addr
            $0.bindMemory(to: sockaddr_in.self).baseAddress!.pointee.sin_port = _htons(port)
            $0.bindMemory(to: sockaddr_in.self).baseAddress!.pointee.sin_len = UInt8(MemoryLayout<in_addr>.size)
            $0.bindMemory(to: sockaddr_in.self).baseAddress!.pointee.sin_family = UInt8(AF_INET)
        }
        
        return SockAddr4(data)
    }

    public override func next() -> IPAddress {
        var inaddr = self.inaddr
        inaddr.reverse()
        inaddr.withUnsafeMutableBytes { $0.bindMemory(to: UInt32.self).baseAddress!.pointee += 1 }
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
        return inaddr.withUnsafeBytes { (bytes : UnsafeRawBufferPointer) -> [UInt8] in [ bytes[0], bytes[1], bytes[2], bytes[3] ] }
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

    static func == (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
        return lhs.inaddr == rhs.inaddr
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        return IPv4Address(inaddr)
    }

    static func < (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
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

class IPv6Address : IPAddress, Comparable {
    // scope zone index
    let scope : UInt32

    static func getBytes(_ addr: in6_addr) -> [UInt8] {
        return Mirror(reflecting: addr.__u6_addr.__u6_addr8).children.map { $0.value as! UInt8 }
    }

    static func extractScope(_ addr: in6_addr) -> (addr: in6_addr, scope: UInt32) {
        var scope = UInt32(0)
        var bytes = getBytes(addr)
        if (bytes[0] == 0xFF && (bytes[1] == 0x01 || bytes[1] == 0x02)) || (bytes[0] == 0xFE && (bytes[1] & 0xC0 == 0x80)) {
            bytes[2] = 0
            bytes[3] = 0
            scope = UInt32(bytes[3]) + 16 * UInt32(bytes[2])
            print("CLEARING", bytes[2], bytes[3], scope)
        }

        var retval = in6_addr()
        retval.__u6_addr.__u6_addr8 = (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
        return (retval, scope)
    }

    override func hash(into hasher: inout Hasher) {
        hasher.combine(inaddr)
        hasher.combine(scope)
    }

    private func bytes() -> [UInt8] {
        return inaddr.withUnsafeBytes { (bytes : UnsafeRawBufferPointer) -> [UInt8] in [ bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15] ] }
    }

    public func getRawBytes() -> String {
        var retval = "raw bytes: "
        for idx in 0..<inaddr.count {
            retval = retval + String(format: "%02x", inaddr[idx])
            if idx + 1 < inaddr.count { retval = retval + ":" }
        }
        return retval
    }

    public init(_ inaddr: Data, scope: UInt32 = 0) {
        self.scope = scope
        super.init(inaddr)
//        print("INITIALISATION 1 IPv6Address: ", getRawBytes(), " scope=", scope)
    }

    public init(mask_len: UInt8) {
        scope = 0
        super.init(mask_len: mask_len, data_size: MemoryLayout<in6_addr>.size)
//        print("INITIALISATION 2 IPv6Address: ", getRawBytes(), " scope=", scope)
    }

    public convenience init?(_ address: String) {
        var data = Data(count: MemoryLayout<in6_addr>.size)
        let ret = data.withUnsafeMutableBytes { (bytes : UnsafeMutableRawBufferPointer) -> Int32 in address.withCString { inet_pton(AF_INET6, $0, bytes.bindMemory(to: in_addr.self).baseAddress) } }
        if ret != 1 { return nil }
        self.init(data)
    }

    public override func getFamily() -> Int32 {
        return AF_INET6
    }

    public override func toSockAddress() -> SockAddr? {
        return toSockAddress(port: 0)
    }

    public override func toSockAddress(port: UInt16) -> SockAddr? {
        var inaddr_clean = inaddr
        inaddr_clean.withUnsafeMutableBytes { (bytes : UnsafeMutableRawBufferPointer) in
            if (bytes[0] == 0xFF && (bytes[1] == 0x01 || bytes[1] == 0x02)) || (bytes[0] == 0xFE && (bytes[1] & 0xC0 == 0x80)) {
                print("CLEANING", bytes[2], bytes[3])
                bytes[2] = 0
                bytes[3] = 0
            }
        }
        let my_in6_addr = inaddr_clean.withUnsafeBytes { $0.bindMemory(to: in6_addr.self).baseAddress!.pointee }

        var data = Data(count: MemoryLayout<sockaddr_in6>.size)
        data.withUnsafeMutableBytes {
            $0.bindMemory(to: sockaddr_in6.self).baseAddress!.pointee.sin6_addr = my_in6_addr
            $0.bindMemory(to: sockaddr_in6.self).baseAddress!.pointee.sin6_port = _htons(port)
            $0.bindMemory(to: sockaddr_in6.self).baseAddress!.pointee.sin6_scope_id = scope
            $0.bindMemory(to: sockaddr_in6.self).baseAddress!.pointee.sin6_len = UInt8(MemoryLayout<in6_addr>.size)
            $0.bindMemory(to: sockaddr_in6.self).baseAddress!.pointee.sin6_family = UInt8(AF_INET6)
        }

        return SockAddr6(data)
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
        return and(IPv6Address("fe00::")!) == IPv6Address("fc00::")!
    }

    public func isLLA() -> Bool {
        return and(IPv6Address("ffc0::")!) == IPv6Address("fe80::")!
    }

    public func isUnicastPublic() -> Bool {
        return and(IPv6Address("e000::")!) == IPv6Address("2000::")!
    }

    public func isMulticastPublic() -> Bool {
        return and(IPv6Address("ff00::")!) == IPv6Address("ff00::")!
    }

    public func isReserved() -> Bool {
        return and(IPv6Address("ff00::")!) == IPv6Address("::")!
    }

    static func == (lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        return lhs.inaddr == rhs.inaddr && lhs.scope == rhs.scope
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        return IPv6Address(inaddr, scope: scope)
    }

    static func < (lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        var x = lhs
        var y = rhs

        if x.scope != y.scope { return x.scope < y.scope }

        return withUnsafeBytes(of: &x) { (xp) -> Bool in
            withUnsafeBytes(of: &y, { (yp) -> Bool in
                if xp.count != yp.count { fatalError() }
                for i in 0..<xp.count { if xp[i] != yp[i] { return xp[i] < yp[i] } }
                return false
            })
        }
    }
}

struct IPNetwork : Hashable, Equatable {
    public let ip_address : IPAddress
    public let mask_len : UInt8
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ip_address)
        hasher.combine(mask_len)
    }

    public init(ip_address: IPAddress, mask_len: UInt8) {
        self.ip_address = ip_address
        self.mask_len = mask_len
    }

    static func == (lhs: IPNetwork, rhs: IPNetwork) -> Bool {
        return lhs.ip_address == rhs.ip_address && lhs.mask_len == rhs.mask_len
    }
}

final class NetTools {
}
