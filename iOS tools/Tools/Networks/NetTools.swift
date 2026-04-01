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
import iOSToolsMacros

// reproduire long timeout : blocage step 1 si wifi avec DNS manuel vers 1.2.3.4 et hostname pas dans le cache
public func resolveHostname(_ target_name: String, _ ipv4: Bool) async -> String? {
    let host = CFHostCreateWithName(nil, target_name as CFString).takeRetainedValue()
    CFHostStartInfoResolution(host, .addresses, nil)
    var success: DarwinBoolean = false
    if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray? {
        for case let theAddress as NSData in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 && ((ipv4 && isIPv4(String(cString: hostname))) || (!ipv4 && isIPv6(String(cString: hostname)))) {
                return String(cString: hostname)
            }
        }
    }
    return nil
}

public func isIPv4(_ str: String) -> Bool {
    var sin = sockaddr_in()
    return str.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1
}

public func isIPv6(_ str: String) -> Bool {
    var sin = sockaddr_in6()
    return str.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin.sin6_addr) }) == 1
}

public func toIpAddress(_ str: String) -> IPAddress {
    return isIPv4(str) ? (IPv4Address(str)! as IPAddress) : (IPv6Address(str)! as IPAddress)
}

public class SockAddr {
    fileprivate let saddrdata : Data

    public func getData() -> Data {
        return saddrdata
    }
    
    fileprivate init?(_ saddrdata: Data) {
        self.saddrdata = saddrdata
    }

    public static func getSockAddr(_ saddrdata: Data) -> SockAddr {
        let family = saddrdata.withUnsafeBytes {
            $0.bindMemory(to: sockaddr.self).baseAddress!.pointee.sa_family
        }
        switch Int32(family) {
        case AF_INET:
            return SockAddr4(saddrdata)!
            
        case AF_INET6:
            return SockAddr6(saddrdata)!

        default:
            fatalError(#saveTrace("bad address family"))
        }
    }
    
    public func getIPAddress() -> IPAddress? {
        fatalError(#saveTrace("should not be called"))
    }

    // pour debug
    public func _getNameInfo(_ flags: Int32) -> String? {
        return getNameInfo(flags)
    }

    // Warning: an address like fe81:abcd:: may throw an error because 'abcd' contains the scope, and it must be the index of an existing interface
    private func getNameInfo(_ flags: Int32) -> String? {
        return saddrdata.withUnsafeBytes {
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let ret = getnameinfo($0.bindMemory(to: sockaddr.self).baseAddress!, UInt32(MemoryLayout<sockaddr>.size), &buffer, UInt32(NI_MAXHOST), nil, 0, flags)
//             print("request:", (getIPAddress() as? IPv4Address)?.bytes())
            if ret != 0 {
//                print("getNameInfo error:", gai_strerror(ret)!)
            } else {
//                print("getNameInfo returned 0:", String(cString: buffer))
            }
            return ret == 0 ? String(cString: buffer) : nil
        }
    }

    public func resolveHostName() -> String? {
        // DNS request
        return getNameInfo(NI_NAMEREQD)
    }

    public func toNumericString() -> String? {
        // no DNS request
        return getNameInfo(NI_NUMERICHOST)
    }
    
    public func getFamily() -> Int32 {
        fatalError(#saveTrace("should not be called"))
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

public class SockAddr6 : SockAddr {
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

public final class IPv4AddressSendable: Sendable {
    let inaddr: Data
    
    fileprivate init(_ inaddr: Data) {
        self.inaddr = inaddr
    }

    func toAddress() -> IPv4Address {
        return IPv4Address(inaddr)
    }
}

public final class IPv6AddressSendable: Sendable {
    private let inaddr: Data
    private let scope: UInt32

    fileprivate init(_ inaddr: Data, scope: UInt32) {
        self.inaddr = inaddr
        self.scope = scope
    }
    
    func toAddress() -> IPv6Address {
        return IPv6Address(inaddr, scope: scope)
    }
}

public class IPAddress : Hashable, Codable {
    fileprivate let inaddr: Data
    
    public func hash(into hasher: inout Hasher) {
        fatalError(#saveTrace("should not be called"))
    }
    
     enum CodingKeys: CodingKey {
        case inaddr
    }

    /*
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inaddr, forKey: .inaddr)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.inaddr = try container.decode(Data.self, forKey: .inaddr)
    }*/

    fileprivate init(_ inaddr: Data) {
        self.inaddr = inaddr
    }

    fileprivate init(mask_len: UInt8, data_size: Int) {
        var inaddr = Data(count: data_size)
        inaddr.withUnsafeMutableBytes {
            var byte = 0, bit = 7
            for _ in 0..<mask_len {
                // pour éviter une erreur du compilateur à la ligne d'après, on met ceci (ambiguous use of subscript, found candidates UnsafeMutablePointer, UnsageMutableRawBufferPointer
                _ = $0
                
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
        fatalError(#saveTrace("getFamily() on IPAddress"))
    }

    public func toSockAddress() -> SockAddr? {
        fatalError(#saveTrace("toSockAddress() on IPAddress"))
    }

    public func toSockAddress(port: UInt16) -> SockAddr? {
        fatalError(#saveTrace("toSockAddress(port) on IPAddress"))
    }
    
    public func resolveHostName() -> String? {
        return toSockAddress()!.resolveHostName()
    }
    
    // Only IPv6 addresses can return nil
    public func toNumericString() -> String? {
        return toSockAddress()!.toNumericString()
    }

    private func map(netmask: IPAddress, _ map: (UInt8, UInt8) -> UInt8) -> Data {
        if netmask.inaddr.count != inaddr.count { fatalError(#saveTrace("incompatible types")) }

        var addr = inaddr
        let mask_bytes = [UInt8](netmask.inaddr)
        
        addr.withUnsafeMutableBytes {
            // pour éviter une erreur du compilateur à la ligne d'après, on met ceci (ambiguous use of subscript, found candidates UnsafeMutablePointer, UnsageMutableRawBufferPointer
            _ = $0

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
        fatalError(#saveTrace("and on IPAddress"))
    }
    
    public func or(_ netmask: IPAddress) -> IPAddress {
        fatalError(#saveTrace("or on IPAddress"))
    }
    
    public func xor(_ netmask: IPAddress) -> IPAddress {
        fatalError(#saveTrace("xor on IPAddress"))
    }

    public func next() -> IPAddress {
        fatalError(#saveTrace("next on IPAddress"))
    }

    public static func == (lhs: IPAddress, rhs: IPAddress) -> Bool {
        if let lhsv4 = lhs as? IPv4Address {
            if let rhsv4 = rhs as? IPv4Address {
                return lhsv4 == rhsv4
            } else {
                return false
            }
        }

        if let lhsv6 = lhs as? IPv6Address {
            if let rhsv6 = rhs as? IPv6Address {
                return lhsv6 == rhsv6
            } else {
                return false
            }
        }

        #fatalError("equality")
        return false
    }

    func copy(with zone: NSZone? = nil) -> Any {
        fatalError(#saveTrace("copy() on IPAddress"))
    }

    static func isLowerThan(lhs: IPAddress, rhs: IPAddress) -> Bool {
        return withUnsafeBytes(of: lhs.inaddr) { (xp) -> Bool in
            withUnsafeBytes(of: rhs.inaddr, { (yp) -> Bool in
                if xp.count != yp.count {
                    #fatalError("isLowerThan")
                    return false
                }
                for i in 0..<xp.count { if xp[i] != yp[i] { return xp[i] < yp[i] } }
                return false
            })
        }
    }

    static func < (lhs: IPAddress, rhs: IPAddress) -> Bool {
        #fatalError("< on IPAddress")
        return false
    }
}

public class IPv4Address : IPAddress, Comparable, LosslessStringConvertible {
    public var description: String {
        return "\(bytes()[0]).\(bytes()[1]).\(bytes()[2]).\(bytes()[3])"
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(inaddr)
    }

    func toSendable() -> IPv4AddressSendable {
        return IPv4AddressSendable(inaddr)
    }

    override init(_ inaddr: Data) {
        super.init(inaddr)
    }
    
    required public init?(_ address: String) {
        var data = Data(count: MemoryLayout<in_addr>.size)
        let ret = data.withUnsafeMutableBytes { (bytes : UnsafeMutableRawBufferPointer) -> Int32 in address.withCString { inet_aton($0, bytes.bindMemory(to: in_addr.self).baseAddress) } }
        if ret != 1 { return nil }
        super.init(data)
    }

    public init(mask_len: UInt8) {
        super.init(mask_len: mask_len, data_size: MemoryLayout<in_addr>.size)
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
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

    fileprivate func bytes() -> [UInt8] {
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

    public static func < (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
        return isLowerThan(lhs: lhs, rhs: rhs)
    }
}

// Note : compliant to LosslessStringConvertible only for addresses with no scope (this includes global IPv6 addresses)
public class IPv6Address : IPAddress, Comparable, LosslessStringConvertible {
    public var description: String {
        return bytes().map { String(format: "%02x", $0) }.joined(separator: ":")
    }
    
    // scope zone index
    private var scope: UInt32

    static private let _ipv6_fe00 = IPv6Address("fe00::")!
    static private let _ipv6_fc00 = IPv6Address("fc00::")!
    static private let _ipv6_ffc0 = IPv6Address("ffc0::")!
    static private let _ipv6_ff00 = IPv6Address("ff00::")!
    static private let _ipv6_e000 = IPv6Address("e000::")!
    static private let _ipv6_fe80 = IPv6Address("fe80::")!
    static private let _ipv6_2000 = IPv6Address("2000::")!

    func toSendable() -> IPv6AddressSendable {
        return IPv6AddressSendable(inaddr, scope: scope)
    }

    public init(_ inaddr: Data, scope: UInt32) {
        var in6_addr = IPv6Address.filterScope(inaddr).addr
        let _inaddr = NSData(bytes: &in6_addr, length: MemoryLayout<in6_addr>.size) as Data
        self.scope = scope
        super.init(_inaddr)
    }

    public init(mask_len: UInt8) {
        scope = 0
        super.init(mask_len: mask_len, data_size: MemoryLayout<in6_addr>.size)
    }

    required public convenience init?(_ address: String) {
        var data = Data(count: MemoryLayout<in6_addr>.size)
        let ret = data.withUnsafeMutableBytes { (bytes : UnsafeMutableRawBufferPointer) -> Int32 in address.withCString { inet_pton(AF_INET6, $0, bytes.bindMemory(to: in_addr.self).baseAddress) } }
        if ret != 1 { return nil }
        let addr_and_scope = IPv6Address.filterScope(data)
        self.init(IPv6Address.getData(addr_and_scope.addr), scope: addr_and_scope.scope)
    }
    
    enum CodingKeys: String, CodingKey { case scope }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scope = try container.decode(UInt32.self, forKey: .scope)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scope, forKey: .scope)
        try super.encode(to: encoder)
    }

    func bytes() -> [UInt8] {
        return inaddr.withUnsafeBytes { (bytes : UnsafeRawBufferPointer) -> [UInt8] in [ bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15] ] }
    }

    public func getScope() -> UInt32 {
        return scope
    }
    
    private static func getBytes(_ addr: in6_addr) -> [UInt8] {
        let foo = addr.__u6_addr.__u6_addr8
        // This way, we can do a loop on the tuple members, but it takes a lot of CPU
        // return Mirror(reflecting: addr.__u6_addr.__u6_addr8).children.map { $0.value as! UInt8 }
        return [ foo.0, foo.1, foo.2, foo.3, foo.4, foo.5, foo.6, foo.7, foo.8, foo.9, foo.10, foo.11, foo.12, foo.13, foo.14, foo.15 ]
    }

    private static func getData(_ addr: in6_addr) -> Data {
        var my_addr = addr
        return NSData(bytes: &my_addr, length: MemoryLayout<in6_addr>.size) as Data
    }

    private static func filterScope(_ inaddr: Data) -> (addr: in6_addr, scope: UInt32) {
        return filterScope(inaddr.withUnsafeBytes { $0.bindMemory(to: in6_addr.self).baseAddress!.pointee })
    }

    private static func filterScope(_ addr: in6_addr) -> (addr: in6_addr, scope: UInt32) {
        var scope = UInt32(0)
        var bytes = getBytes(addr)
        if (bytes[0] == 0xFF && (bytes[1] == 0x01 || bytes[1] == 0x02)) || (bytes[0] == 0xFE && (bytes[1] & 0xC0 == 0x80)) {
            scope = UInt32(bytes[3]) + 256 * UInt32(bytes[2])
            bytes[2] = 0
            bytes[3] = 0
//            print("filterScope CLEARING bytes 2 & 3 & scope", bytes[2], bytes[3], scope)
        }

        var retval = in6_addr()
        retval.__u6_addr.__u6_addr8 = (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
        return (retval, scope)
    }

    public override func hash(into hasher: inout Hasher) {
        hasher.combine(inaddr)
        hasher.combine(scope)
    }

    public func getRawBytes() -> String {
        var retval = "IPv6Address raw bytes: "
        for idx in 0..<inaddr.count {
            retval = retval + String(format: "%02x", inaddr[idx])
            if idx + 1 < inaddr.count { retval = retval + ":" }
        }
        return retval
    }

    public func changeScope(scope: UInt32) -> IPv6Address {
        return IPv6Address(inaddr, scope: scope)
    }

    public override func getFamily() -> Int32 {
        return AF_INET6
    }

    public override func toSockAddress() -> SockAddr6? {
        return toSockAddress(port: 0)
    }

    public override func toSockAddress(port: UInt16) -> SockAddr6? {
        var inaddr_clean = inaddr
        inaddr_clean.withUnsafeMutableBytes { (bytes : UnsafeMutableRawBufferPointer) in
            if (bytes[0] == 0xFF && (bytes[1] == 0x01 || bytes[1] == 0x02)) || (bytes[0] == 0xFE && (bytes[1] & 0xC0 == 0x80)) {
                // Cleaning bytes 2 & 3
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
        if (netmask as! IPv6Address).scope != 0 {
            #fatalError("invalid scope for netmask")
        }
        return IPv6Address(super._and(netmask), scope: scope)
    }

    public override func or(_ netmask: IPAddress) -> IPAddress {
        if (netmask as! IPv6Address).scope != 0 {
            #fatalError("invalid scope for netmask")
        }
        return IPv6Address(super._or(netmask), scope: scope)
    }

    public override func xor(_ netmask: IPAddress) -> IPAddress {
        if (netmask as! IPv6Address).scope != 0 {
            #fatalError("invalid scope for netmask")
        }
        return IPv6Address(super._xor(netmask), scope: scope)
    }

    public override func next() -> IPAddress {
        fatalError(#saveTrace("next on IPv6Address"))
    }

    public func isULA() -> Bool {
        return and(IPv6Address._ipv6_fe00) as! IPv6Address == IPv6Address._ipv6_fc00
    }

    public func isLLA() -> Bool {
        return and(IPv6Address._ipv6_fc00).inaddr == IPv6Address._ipv6_fe80.inaddr
    }

    public func isUnicastPublic() -> Bool {
        return and(IPv6Address._ipv6_e000) as! IPv6Address == IPv6Address._ipv6_2000
    }

    public func isMulticastPublic() -> Bool {
        return and(IPv6Address._ipv6_ff00) as! IPv6Address == IPv6Address._ipv6_ff00
    }

    static func == (lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        return lhs.inaddr == rhs.inaddr && lhs.scope == rhs.scope
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        return IPv6Address(inaddr, scope: scope)
    }

    public static func < (lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        if lhs.scope != rhs.scope { return lhs.scope < rhs.scope }
        return isLowerThan(lhs: lhs, rhs: rhs)
    }
}

struct IPNetwork : Hashable, Equatable {
    public let ip_address: IPAddress
    public let mask_len: UInt8
    
    func hash(into hasher: inout Hasher) {
        if let addr = ip_address as? IPv4Address {
            hasher.combine(addr)
        } else if let addr = ip_address as? IPv6Address {
            hasher.combine(addr)
        } else {
            #fatalError("invalid address family")
        }

        hasher.combine(mask_len)
    }

    public init(ip_address: IPAddress, mask_len: UInt8) {
        self.ip_address = ip_address
        self.mask_len = mask_len
    }

    static func == (lhs: IPNetwork, rhs: IPNetwork) -> Bool {
        if lhs.ip_address.getFamily() != rhs.ip_address.getFamily() {
            return false
        }

        switch lhs.ip_address.getFamily() {
        case AF_INET:
            return lhs.ip_address as! IPv4Address == rhs.ip_address as! IPv4Address && lhs.mask_len == rhs.mask_len
        case AF_INET6:
            return lhs.ip_address as! IPv6Address == rhs.ip_address as! IPv6Address && lhs.mask_len == rhs.mask_len
        default:
            #fatalError("invalid family")
            return false
        }
    }
}

final class NetTools {
}
