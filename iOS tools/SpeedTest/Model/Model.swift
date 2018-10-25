//
//  Model.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

enum SectionType: Int, CaseIterable {
    case localhost = 0, ios, chargen_discard, gateway, internet, other
}

enum NodeType: Int, CaseIterable {
    case localhost = 0, ios, chargen, discard, gateway, internet, locked
}

// A domain part may contain a dot
// ex: fenyo.net, net, www.fenyo.net
class DomainPart : Hashable {
    internal var hashValue: Int
    internal let name: String

    public init(_ name : String) {
        if name.isEmpty { fatalError("DomainPart") }
        self.name = name
        hashValue = name.hashValue
    }

    public func toString() -> String {
        return name
    }
    
    public static func == (lhs: DomainPart, rhs: DomainPart) -> Bool {
        return lhs.name == rhs.name
    }
}

// A host part must not contain a dot
// ex: www, localhost
class HostPart : DomainPart {
    public override init(_ name : String) {
        if name.contains(".") { fatalError("HostPart") }
        super.init(name)
    }
}

// A domain name must contain a host part and may optionally contain a domain part
// ex: {www, nil}, {www, fenyo.net}
class DomainName : Hashable {
    internal var hashValue: Int
    
    internal let host_part: HostPart
    internal let domain_part: DomainPart?

    public init(_ host_part : HostPart, _ domain_part : DomainPart? = nil) {
        self.host_part = host_part
        if let domain_part = domain_part { self.domain_part = domain_part }
        else { self.domain_part = nil }
        hashValue = host_part.hashValue &+ (domain_part?.hashValue ?? 0)
    }

    public func toString() -> String {
        if let domain_part = domain_part {
            return host_part.toString() + "." + domain_part.toString()
        } else {
            return host_part.toString()
        }
    }
    
    public func isFQDN() -> Bool {
        return domain_part != nil
    }

    public static func == (lhs: DomainName, rhs: DomainName) -> Bool {
        return lhs.host_part == rhs.host_part && lhs.domain_part == rhs.domain_part
    }
}

// A FQDN is a domain name that both contains a host part and a domain part
// ex: {www, fenyo.net}, {localhost, localdomain}
class FQDN : DomainName {
    public init(_ host_part : String, _ domain_part : String) {
        super.init(HostPart(host_part), DomainPart(domain_part))
    }
}

// A node is an object that has sets of multicast DNS names (FQDNs), or domain names, or IPv4 addresses or IPv6 addresses
// ex of mDNS name: iPad de Alexandre.local
// ex of dns names: localhost, localhost.localdomain, www.fenyo.net, www
class Node : Hashable {
    internal var hashValue: Int

    public var mcast_dns_names = Set<FQDN>()
    public var dns_names = Set<DomainName>()
    public var v4_addresses = Set<IPv4Address>()
    public var v6_addresses = Set<IPv6Address>()
    public var tcp_ports = Set<UInt32>()
    public var types = Set<NodeType>()

    public init() {
        hashValue = mcast_dns_names.hashValue &+ dns_names.hashValue &+ v4_addresses.hashValue &+ v6_addresses.hashValue &+ tcp_ports.hashValue &+ types.hashValue
    }

    private var adresses: Set<IPAddress> {
        return (v4_addresses as Set<IPAddress>).union(v6_addresses)
    }

    private var fqdn_dns_names: Set<FQDN> {
        return dns_names.filter { (dns_name) -> Bool in
            dns_name.isFQDN()
        } as! Set<FQDN>
    }

    private var fqdn_names: Set<FQDN> {
        return fqdn_dns_names.union(mcast_dns_names)
    }
    
    private var short_names: Set<HostPart> {
        return Set(mcast_dns_names.map { $0.host_part }).union(Set(dns_names.map { $0.host_part }))
    }

    public func toSectionTypes() -> Set<SectionType> {
        var section_types = Set<SectionType>()

        if types.contains(.localhost) { section_types.insert(.localhost) }
        if types.contains(.ios) { section_types.insert(.ios) }
        if types.contains(.chargen) || types.contains(.discard) { section_types.insert(.chargen_discard) }
        if types.contains(.gateway) { section_types.insert(.gateway) }
        if types.contains(.internet) { section_types.insert(.internet) }

        if !types.contains(.localhost) && !types.contains(.ios) && !types.contains(.chargen) && !types.contains(.discard) && !types.contains(.gateway) && !types.contains(.internet) { section_types.insert(.other) }

        return section_types
    }
    
    public static func == (lhs: Node, rhs: Node) -> Bool {
        if !(lhs.v4_addresses.filter { $0.isUnicast() && !$0.isLocal() }.intersection(rhs.v4_addresses.filter { $0.isUnicast() && !$0.isLocal() }).isEmpty) { return true }
        
        if !(lhs.v6_addresses.filter { !$0.isMulticastPublic() }.intersection(rhs.v6_addresses.filter { !$0.isMulticastPublic() }).isEmpty) { return true }

        if !lhs.mcast_dns_names.intersection(rhs.mcast_dns_names).isEmpty { return true }

        if !lhs.dns_names.intersection(rhs.dns_names).isEmpty { return true }

        return false
    }
}

class Section {
    public var description: String
    public var detailed_description: String
    public var nodes = [Node]()
    
    public init(_ description: String, _ detailed_description: String) {
        self.description = description
        self.detailed_description = detailed_description
    }
}

// The DBMaster database instance is accessible with DBMaster.shared
class DBMaster {
    public var sections : [SectionType: Section]
    private var nodes : Set<Node>
    private var networks : Set<IPNetwork>
    static public let shared = DBMaster()

    public func addNode(_ new_node: Node) {
        if let node = (nodes.filter { $0 == new_node }).first {
            // The node is already registered
            node.mcast_dns_names.formUnion(new_node.mcast_dns_names)
            node.dns_names.formUnion(new_node.mcast_dns_names)
            node.v4_addresses.formUnion(new_node.v4_addresses)
            node.v6_addresses.formUnion(new_node.v6_addresses)
            node.types.formUnion(new_node.types)
            node.tcp_ports.formUnion(new_node.tcp_ports)
        } else {
            // We have discovered a new node
            nodes.insert(new_node)
        }
        
        // Update sections
        let node = (nodes.filter { $0 == new_node }).first!
        SectionType.allCases.forEach {
            if node.toSectionTypes().contains($0) {
                if !sections[$0]!.nodes.contains(node) { sections[$0]!.nodes.append(node) }
            } else { sections[$0]!.nodes.removeAll { $0 == node } }
        }
    }

    public func removeNode(_ node: Node) {
        SectionType.allCases.forEach { sections[$0]!.nodes.removeAll { $0 == node }}
        nodes.remove(node)
    }
    
    public func locateNode(_ node: Node) -> [IndexPath] {
        var paths = [IndexPath]()
        SectionType.allCases.forEach {
            for idx in sections[$0]!.nodes.indices {
                if sections[$0]!.nodes[idx] == node { paths.append(IndexPath(row: idx, section: $0.rawValue)) }
            }
        }
        return paths
    }

    public init() {
        networks = Set<IPNetwork>()

        nodes = Set<Node>()
        sections = [
            .localhost: Section("localhost", "this host"),
            .ios: Section("iOS devices", "other devices running this app"),
            .chargen_discard: Section("Chargen/Discard services", "other devices running these services"),
            .gateway: Section("Local gateway", "local router"),
            .internet: Section("Internet", "remote host on the Internet"),
            .other: Section("Other hosts", "any host")
        ]
        
        var node = Node()
        node.mcast_dns_names.insert(FQDN("iOS device 1", "local"))
        node.v4_addresses.insert(IPv4Address("1.2.3.4")!)
        node.v4_addresses.insert(IPv4Address("1.2.3.5")!)
        node.v6_addresses.insert(IPv6Address("fe80:1::abcd:1234")!)
        node.types = [ .chargen, .discard, .ios ]
        addNode(node)

        node = Node()
        node.v4_addresses.insert(IPv4Address("1.2.3.6")!)
        node.types = [ .chargen, .discard ]
        addNode(node)

        node = Node()
        node.dns_names.insert(DomainName(HostPart("chargen device 1")))
        node.v6_addresses.insert(IPv6Address("fe80:1::abcd:1234")!)
        node.types = [ .chargen, .discard ]
        addNode(node)

        node = Node()
        node.dns_names.insert(DomainName(HostPart("Local gateway")))
        node.types = [ .gateway ]
        addNode(node)

        node = Node()
        node.dns_names.insert(DomainName(HostPart("IPv4 Internet")))
        node.types = [ .internet, .locked ]
        addNode(node)

        node = Node()
        node.dns_names.insert(DomainName(HostPart("IPv6 Internet")))
        node.types = [ .internet, .locked ]
        addNode(node)

        // Add localhost
        node = Node()
        node.types = [ .localhost ]
        var idx : Int32 = 0, ret : Int32 = 0
        repeat {
            var data = Data(count: MemoryLayout<sockaddr_storage>.size)
            ret = data.withUnsafeMutableBytes { getlocaladdr(idx, $0, UInt32(MemoryLayout<sockaddr_storage>.size)) }
            if ret >= 0 {
                if SockAddr(data)!.getFamily() == AF_INET {
                    let address = SockAddr4(data.prefix(MemoryLayout<sockaddr_in>.size))!.getIPAddress() as! IPv4Address
                    node.v4_addresses.insert(address)
                    networks.insert(IPNetwork(ip_address: address.and(IPv4Address(mask_len: UInt8(ret))), mask_len: UInt8(ret)))
                } else {
                    let address = SockAddr6(data.prefix(MemoryLayout<sockaddr_in6>.size))!.getIPAddress() as! IPv6Address
                    node.v6_addresses.insert(address)
                    networks.insert(IPNetwork(ip_address: address.and(IPv6Address(mask_len: UInt8(ret))), mask_len: UInt8(ret)))
                }
            }
            idx += 1
        } while ret >= 0

        addNode(node)
    }
}
