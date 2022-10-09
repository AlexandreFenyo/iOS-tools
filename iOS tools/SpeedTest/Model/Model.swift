//
//  Model.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit

enum SectionType: Int, CaseIterable {
    case localhost = 0, ios, chargen_discard, gateway, internet, other
}

enum NodeType: Int, CaseIterable {
    case localhost = 0, ios, chargen, discard, gateway, internet
}

// A domain part may contain a dot
// ex: fenyo.net, net, www.fenyo.net
class DomainPart : Hashable {
    internal let name: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    public init(_ name : String) {
        if name.isEmpty { fatalError("DomainPart") }
        self.name = name
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
    func hash(into hasher: inout Hasher) {
        hasher.combine(host_part)
        hasher.combine(domain_part)
    }

    internal let host_part: HostPart
    internal let domain_part: DomainPart?

    public init(_ host_part : HostPart, _ domain_part : DomainPart? = nil) {
        self.host_part = host_part
        if let domain_part = domain_part { self.domain_part = domain_part }
        else { self.domain_part = nil }
    }

    public init?(_ name: String) {
        if let idx = name.firstIndex(of: ".") {
            if idx == name.indices.first || idx == name.indices.last { return nil }
            host_part = HostPart(String(name.prefix(upTo: idx)))
            domain_part = DomainPart(String(name[name.index(after: idx)...]))
        } else {
            host_part = HostPart(name)
            domain_part = nil
        }
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
    func hash(into hasher: inout Hasher) {
        hasher.combine(mcast_dns_names)
        hasher.combine(dns_names)
        hasher.combine(names)
        hasher.combine(v4_addresses)
        hasher.combine(v6_addresses)
        hasher.combine(tcp_ports)
        hasher.combine(types)
    }
    
    public var mcast_dns_names = Set<FQDN>()
    public var dns_names = Set<DomainName>()
    public var names = Set<String>()
    public var v4_addresses = Set<IPv4Address>()
    public var v6_addresses = Set<IPv6Address>()
    public var tcp_ports = Set<UInt16>()
    public var types = Set<NodeType>()
    
    public init() { }
    
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
        
        if types.contains(.localhost) {
            section_types.insert(.localhost)
            return section_types
        }
        if types.contains(.ios) { section_types.insert(.ios) }
        if types.contains(.chargen) || types.contains(.discard) { section_types.insert(.chargen_discard) }
        if types.contains(.gateway) { section_types.insert(.gateway) }
        if types.contains(.internet) { section_types.insert(.internet) }
        
        if !types.contains(.localhost) && !types.contains(.ios) && !types.contains(.chargen) && !types.contains(.discard) && !types.contains(.gateway) && !types.contains(.internet) { section_types.insert(.other) }
        
        return section_types
    }
    
    public func merge(_ node: Node) {
        mcast_dns_names.formUnion(node.mcast_dns_names)
        dns_names.formUnion(node.dns_names)
        names.formUnion(node.names)
        v4_addresses.formUnion(node.v4_addresses)
        v6_addresses.formUnion(node.v6_addresses)
        types.formUnion(node.types)
        tcp_ports.formUnion(node.tcp_ports)
    }
    
    public func isSimilar(with: Node) -> Bool {
        if !(v4_addresses.filter { $0.isUnicast() /* && !$0.isLocal() */ }.intersection(with.v4_addresses.filter { $0.isUnicast() /* && !$0.isLocal() */ }).isEmpty) { return true }
        
        if !(v6_addresses.filter { !$0.isMulticastPublic() }.intersection(with.v6_addresses.filter { !$0.isMulticastPublic() }).isEmpty) { return true }
        
        if !mcast_dns_names.intersection(with.mcast_dns_names).isEmpty { return true }
        
        if !dns_names.intersection(with.dns_names).isEmpty { return true }
        
        return false
    }
    
    public static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.mcast_dns_names == rhs.mcast_dns_names && lhs.dns_names == rhs.dns_names && lhs.names == rhs.names && lhs.v4_addresses == rhs.v4_addresses && lhs.v6_addresses == rhs.v6_addresses && lhs.tcp_ports == rhs.tcp_ports && lhs.types == rhs.types
    }

    public func dump() -> String {
        var ret = "DUMP NODE: "
/*        ret = ret + "mcast_dns_names: "
        for foo in mcast_dns_names {
            ret = ret + foo.toString() + "; "
        } */
        ret = ret + "dns_names: "
        for foo in dns_names {
            ret = ret + foo.toString() + "; "
        }/*
        ret = ret + "names: "
        for foo in names {
            ret = ret + foo + "; "
        }*/
        return ret
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
    public var nodes : Set<Node>
    public var networks : Set<IPNetwork>
    
    static public let shared = DBMaster()

    public func addNode(_ new_node: Node) -> ([IndexPath], [IndexPath]) {
        return addOrRemoveNode(new_node, add: true)
    }
    
    public func removeNode(_ node: Node) -> [IndexPath] {
        let (index_paths_removed, _) = addOrRemoveNode(node, add: false)
        return index_paths_removed
    }

    /* 1 gateway per IP */
    /*
    public func getLocalGateways() -> [Node] {
        var gateways = [Node]()

        var idx : Int32 = 0, ret : Int32
        repeat {
            var data = Data(count: MemoryLayout<sockaddr_storage>.size)
            ret = data.withUnsafeMutableBytes { getlocalgatewayipv4(idx, $0, UInt32(MemoryLayout<sockaddr_storage>.size)) }

            if (ret >= 0) {
                let addr = SockAddr4(data.prefix(MemoryLayout<sockaddr_in>.size))!.getIPAddress() as! IPv4Address
                let gw = Node()
                gw.types.insert(.gateway)
                gw.v4_addresses.insert(addr)
                gateways.append(gw)
            }
            idx += 1
        } while ret >= 0

        idx = 0
        repeat {
            var data = Data(count: MemoryLayout<sockaddr_storage>.size)
            ret = data.withUnsafeMutableBytes { getlocalgatewayipv6(idx, $0, UInt32(MemoryLayout<sockaddr_storage>.size)) }
            
            if (ret >= 0) {
                let addr = SockAddr6(data.prefix(MemoryLayout<sockaddr_in6>.size))!.getIPAddress() as! IPv6Address
                let gw = Node()
                gw.types.insert(.gateway)
                gw.v6_addresses.insert(addr)
                gateways.append(gw)
            }
            idx += 1
        } while ret >= 0

        return gateways
    }
 */

    /* A unique gateway */
    public func getLocalGateways() -> [Node] {
        var gateways = [Node]()
        let gw = Node()
        gw.types.insert(.gateway)
        
        var idx : Int32 = 0, ret : Int32
        repeat {
            var data = Data(count: MemoryLayout<sockaddr_storage>.size)
            ret = data.withUnsafeMutableBytes {
                getlocalgatewayipv4(idx, $0.bindMemory(to: sockaddr.self).baseAddress, UInt32(MemoryLayout<sockaddr_storage>.size))
            }
            if (ret >= 0) {
                if let s = SockAddr4(data.prefix(MemoryLayout<sockaddr_in>.size)) {
                    let addr = s.getIPAddress() as! IPv4Address
                    gw.v4_addresses.insert(addr)
                }
            }
            idx += 1
        } while ret >= 0
        
        idx = 0
        repeat {
            var data = Data(count: MemoryLayout<sockaddr_storage>.size)
            ret = data.withUnsafeMutableBytes { getlocalgatewayipv6(idx, $0.bindMemory(to: sockaddr.self).baseAddress, UInt32(MemoryLayout<sockaddr_storage>.size)) }

            if (ret >= 0) {
                let addr = SockAddr6(data.prefix(MemoryLayout<sockaddr_in6>.size))!.getIPAddress() as! IPv6Address
                gw.v6_addresses.insert(addr)
            }
            idx += 1
        } while ret >= 0
        
        if !gw.v4_addresses.isEmpty || !gw.v6_addresses.isEmpty {
            gateways.append(gw)
        }
        
        return gateways
    }
    
    public func getLocalNode() -> Node {
        let node = Node()
        node.types = [ .localhost ]
        var idx : Int32 = 0, mask_len : Int32
        repeat {
            var data = Data(count: MemoryLayout<sockaddr_storage>.size)
            mask_len = data.withUnsafeMutableBytes { getlocaladdr(idx, $0.bindMemory(to: sockaddr.self).baseAddress, UInt32(MemoryLayout<sockaddr_storage>.size)) }
            if mask_len >= 0 {
                let my_sock_addr = SockAddr.getSockAddr(data)
                switch my_sock_addr.getFamily() {
                case AF_INET:
                    let address = my_sock_addr.getIPAddress() as! IPv4Address
                    node.v4_addresses.insert(address)
                    networks.insert(IPNetwork(ip_address: address.and(IPv4Address(mask_len: UInt8(mask_len))), mask_len: UInt8(mask_len)))

                case AF_INET6:
                    let address = my_sock_addr.getIPAddress() as! IPv6Address
                    node.v6_addresses.insert(address)
                    networks.insert(IPNetwork(ip_address: address.and(IPv6Address(mask_len: UInt8(mask_len))), mask_len: UInt8(mask_len)))
                    
                default:
                    fatalError("bad address family")
                }
            }
            idx += 1
        } while mask_len >= 0

        node.names.insert(UIDevice.current.name)
        node.dns_names.insert(DomainName(HostPart(UIDevice.current.name.replacingOccurrences(of: ".", with: "_"))))
        return node
    }

    private func addOrRemoveNode(_ new_node: Node, add: Bool) -> ([IndexPath], [IndexPath]) {
        // pour débugguer la complexité de l'algo de création d'un noeud
//        let start_time = Date()
//        GenericTools.printDuration(idx: 0, start_time: start_time)

        var index_paths_removed = [IndexPath]()
        var index_paths_inserted = [IndexPath]()

        if new_node == Node() || (add && nodes.contains(new_node)) { return (index_paths_removed, index_paths_inserted) }
        
        // Create the new node list including the new node
        var arr_nodes = Array(nodes)
        
        // Track deduplicated nodes
        var dedup = [Node]()

        // pour débugguer la complexité de l'algo de création d'un noeud
//        GenericTools.printDuration(idx: 1, start_time: start_time)

        if add {
            var merged_index: Int = -1
            for i in 0..<arr_nodes.count {
                if arr_nodes[i].isSimilar(with: new_node) {
                    arr_nodes[i].merge(new_node)
                    merged_index = i
                    break
                }
            }
            if merged_index == -1 { arr_nodes.append(new_node) }
            else {
                repeat {
                    var merged = false
                    for i in 0..<arr_nodes.count {
                        if i == merged_index { continue }
                        if arr_nodes[i].isSimilar(with: arr_nodes[merged_index]) {
                            arr_nodes[i].merge(arr_nodes[merged_index])
                            dedup.append(arr_nodes[i])
                            arr_nodes.remove(at: merged_index)
                            if i < merged_index { merged_index = i } else { merged_index = i - 1 }
                            merged = true
                            break
                        }
                    }
                    if !merged { merged_index = -1 }
                } while merged_index != -1
            }
        } else { arr_nodes.removeAll { $0 == new_node } }

        // pour débugguer la complexité de l'algo de création d'un noeud
//        GenericTools.printDuration(idx: 2, start_time: start_time)

        // In each section, locate and let only one node for those that have been deduplicated
        for n in dedup {
            SectionType.allCases.forEach {
                var cnt = 0
                for idx in (0..<sections[$0]!.nodes.count).reversed() {
                    if n.isSimilar(with: sections[$0]!.nodes[idx]) { cnt += 1 }
                }
                if cnt >= 2 {
                    for _ in 1..<cnt {
                        for idx in (0..<sections[$0]!.nodes.count).reversed() {
                            if n.isSimilar(with: sections[$0]!.nodes[idx]) {
                                index_paths_removed.append(IndexPath(row: idx, section: $0.rawValue))
                                sections[$0]!.nodes.remove(at: idx)
                                break
                            }
                        }
                    }
                }
            }
        }

        // In each section, locate and remove nodes that have been removed
        SectionType.allCases.forEach {
            for idx in (0..<sections[$0]!.nodes.count).reversed() {
                if !arr_nodes.contains(sections[$0]!.nodes[idx]) {
                    index_paths_removed.append(IndexPath(row: idx, section: $0.rawValue))
                    sections[$0]!.nodes.remove(at: idx)
                }
            }
        }

        // pour débugguer la complexité de l'algo de création d'un noeud
//        GenericTools.printDuration(idx: 3, start_time: start_time)

        // Add the new nodes in each section
        SectionType.allCases.forEach {
            for node in arr_nodes {
                if node.toSectionTypes().contains($0) && !sections[$0]!.nodes.contains(node) {
                    index_paths_inserted.append(IndexPath(row: sections[$0]!.nodes.count, section: $0.rawValue))
                    sections[$0]!.nodes.append(node)
                }
            }
        }

        nodes = Set(arr_nodes)

        // pour débugguer la complexité de l'algo de création d'un noeud
//        GenericTools.printDuration(idx: 4, start_time: start_time)

        return (index_paths_removed, index_paths_inserted)
    }

    public init() {
        networks = Set<IPNetwork>()
        nodes = Set<Node>()
        sections = [
            .localhost: Section("Localhost", "this host"),
            .ios: Section("iOS devices", "other devices running this app"),
            .chargen_discard: Section("ChargenDiscard services", "other devices running these services"),
            .gateway: Section("Local gateway", "local router"),
            .internet: Section("Internet", "remote host on the Internet"),
            .other: Section("Other hosts", "any host")
        ]

        var node = Node()
        node.mcast_dns_names.insert(FQDN("dns", "google"))
        node.v4_addresses.insert(IPv4Address("8.8.4.4")!)
        node.v4_addresses.insert(IPv4Address("8.8.8.8")!)
        node.v6_addresses.insert(IPv6Address("2001:4860:4860::8844")!)
        node.v6_addresses.insert(IPv6Address("2001:4860:4860::8888")!)
        node.types = [ .internet ]
        _ = addNode(node)

        node = Node()
        node.mcast_dns_names.insert(FQDN("dns9", "quad9.net"))
        node.v4_addresses.insert(IPv4Address("9.9.9.9")!)
        node.v4_addresses.insert(IPv4Address("149.112.112.9")!)
        node.v6_addresses.insert(IPv6Address("2620:fe::9")!)
        node.v6_addresses.insert(IPv6Address("2620:fe::fe:9")!)
        node.types = [ .internet ]
        _ = addNode(node)
        
//        var node = Node()
        /*
        node.mcast_dns_names.insert(FQDN("iOS device 1", "local"))
        node.v4_addresses.insert(IPv4Address("1.2.3.4")!)
        node.v4_addresses.insert(IPv4Address("1.2.3.5")!)
        node.v6_addresses.insert(IPv6Address("fe80:1::abcd:1234")!)
        node.types = [ .chargen , .discard, .ios ]
        _ = addNode(node)

        node = Node()
        node.v4_addresses.insert(IPv4Address("1.2.3.6")!)
        node.types = [ .chargen, .discard ]
        _ = addNode(node)

        node = Node()
        node.dns_names.insert(DomainName(HostPart("chargen device 1")))
        node.v6_addresses.insert(IPv6Address("fe80:1::abcd:1234")!)
        node.types = [ .chargen, .discard ]
        _ = addNode(node)

        node = Node()
        node.dns_names.insert(DomainName(HostPart("Local gateway")))
        node.types = [ .gateway ]
        _ = addNode(node)

        node = Node()
        node.dns_names.insert(DomainName(HostPart("IPv4 Internet")))
        node.types = [ .internet ]
        _ = addNode(node)

        node = Node()
        node.dns_names.insert(DomainName(HostPart("IPv6 Internet")))
        node.types = [ .internet ]
        _ = addNode(node)
*/
        
        // Add localhost
//        _ = addNode(getLocalNode())

        // Add gateways
//        for gw in getLocalGateways() { _ = addNode(gw) }
    }
}
