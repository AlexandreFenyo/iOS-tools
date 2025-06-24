//
//  Model.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit
import iOSToolsMacros

typealias PortMapper = [Port : (service: ServiceName?, bonjour_service: BonjourServiceName?, count: UInt)]

enum SectionType: Int, CaseIterable {
    case localhost = 0, ios, chargen_discard, snmp, gateway, internet, other
}

enum NodeType: Int, CaseIterable {
    case localhost = 0, ios, chargen, discard, snmp, gateway, internet
}

enum IPProtocol: Int, CaseIterable, CustomStringConvertible {
    var description: String {
        return rawValue == 0 ? "TCP" : "UDP"
    }
    
    case TCP, UDP
}
typealias PortNumber = UInt16
typealias ServiceName = String
typealias BonjourServiceName = String
struct Port : Hashable, CustomStringConvertible {
    var description: String {
        return "\(ip_protocol)/\(port_number)"
    }
    
    let port_number: PortNumber
    let ip_protocol: IPProtocol
}

// A domain part may contain a dot
// ex: fenyo.net, net, www.fenyo.net
class DomainPart : Hashable, Comparable {
    let name: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    init(_ name: String) {
        if name.isEmpty {
            #fatalError("DomainPart")
            self.name = "empty_domain_part"
            return
        }
        self.name = name
    }

    func toString() -> String {
        return name
    }
    
    static func == (lhs: DomainPart, rhs: DomainPart) -> Bool {
        return lhs.name == rhs.name
    }
    
    static func < (lhs: DomainPart, rhs: DomainPart) -> Bool {
        return lhs.name < rhs.name
    }
 }

// A host part must not contain a dot
// ex: www, localhost
class HostPart : DomainPart {
    override init(_ name: String) {
        if name.contains(".") {
            #fatalError("HostPart")
            super.init("empty_host_part")
            return
        }
        super.init(name)
    }
}

// A domain name must contain a host part and may optionally contain a domain part
// ex: {www, nil}, {www, fenyo.net}
class DomainName : Hashable, Comparable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(host_part)
        hasher.combine(domain_part)
    }
    
    let host_part: HostPart
    let domain_part: DomainPart?
    
    init(_ host_part : HostPart, _ domain_part : DomainPart? = nil) {
        self.host_part = host_part
        if let domain_part = domain_part { self.domain_part = domain_part }
        else { self.domain_part = nil }
    }
    
    init?(_ name: String) {
        if let idx = name.firstIndex(of: ".") {
            if idx == name.indices.first || idx == name.indices.last { return nil }
            host_part = HostPart(String(name.prefix(upTo: idx)))
            domain_part = DomainPart(String(name[name.index(after: idx)...]))
        } else {
            host_part = HostPart(name)
            domain_part = nil
        }
    }
    
    func toString() -> String {
        if let domain_part = domain_part {
            return host_part.toString() + "." + domain_part.toString()
        } else {
            return host_part.toString()
        }
    }
    
    func isFQDN() -> Bool {
        return domain_part != nil
    }
    
    static func == (lhs: DomainName, rhs: DomainName) -> Bool {
        return lhs.host_part == rhs.host_part && lhs.domain_part == rhs.domain_part
    }
    
    static func < (lhs: DomainName, rhs: DomainName) -> Bool {
        return lhs.toString() < rhs.toString()
    }
}

// A FQDN is a domain name that both contains a host part and a domain part
// ex: {www, fenyo.net}, {localhost, localdomain}
class FQDN : DomainName {
    init(_ host_part : String, _ domain_part : String) {
        super.init(HostPart(host_part), DomainPart(domain_part))
    }
}

class BonjourServiceInfo : Hashable {
    let name: String
    let port: String
    let attr: [String : String]
    
    init(_ name: String, _ port: String, _ attr: [String: String]) {
        self.name = name
        self.port = port
        self.attr = attr
    }
    
    static func == (lhs: BonjourServiceInfo, rhs: BonjourServiceInfo) -> Bool {
        return lhs.name == rhs.name && lhs.port == rhs.port && lhs.attr == rhs.attr
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(port)
        hasher.combine(attr)
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
        hasher.combine(udp_ports)
        hasher.combine(types)
        hasher.combine(services)
    }
    
    //    private var is_in_model = false
    
    // Design rule: updating those variables for a Node already included in the model MUST be done only by methods in this class. This is needed to be able to synchronize what is displayed in 3D with the main model.
    fileprivate var mcast_dns_names = Set<FQDN>()
    fileprivate var dns_names = Set<DomainName>()
    fileprivate var names = Set<String>()
    fileprivate var v4_addresses = Set<IPv4Address>()
    fileprivate var v6_addresses = Set<IPv6Address>()
    fileprivate var tcp_ports = Set<UInt16>()
    fileprivate var udp_ports = Set<UInt16>()
    fileprivate var types = Set<NodeType>()
    fileprivate var services = Set<BonjourServiceInfo>()
    
    func isLocalHost() -> Bool {
        return types.contains(.localhost)
    }
    
    // NodeType is an enum, therefore no need to copy the Set elements to be sure they are not updated
    private func getTypes() -> Set<NodeType> {
        return types
    }
    
    // BonjourServiceInfo is a class with constant attributes (each declared as a let String), therefore no need to copy the Set elements to be sure they are not updated
    func getServices() -> Set<BonjourServiceInfo> {
        return services
    }
    
    // FQDN is a hierarchy of classes with constant attributes (each declared as a let struct), therefore no need to copy the Set elements to be sure they are not updated
    func getMcastDnsNames() -> Set<FQDN> {
        return mcast_dns_names
    }
    
    // DomainName is a hierarchy of classes with constant attributes (each declared as a let struct), therefore no need to copy the Set elements to be sure they are not updated
    func getDnsNames() -> Set<DomainName> {
        return dns_names
    }
    
    // No need to copy the set elements to be sure they are not updated
    func getNames() -> Set<String> {
        return names
    }
    
    // IPv4Address is a hierarchy of classes with constant attributes (each declared as a let struct), therefore no need to copy the Set elements to be sure they are not updated
    func getV4Addresses() -> Set<IPv4Address> {
        return v4_addresses
    }
    
    // IPv4Address is a hierarchy of classes with constant attributes (each declared as a let struct), therefore no need to copy the Set elements to be sure they are not updated
    func getV6Addresses() -> Set<IPv6Address> {
        return v6_addresses
    }
    
    // No need to copy the set elements to be sure they are not updated
    func getTcpPorts() -> Set<UInt16> {
        return tcp_ports
    }
    
    // No need to copy the set elements to be sure they are not updated
    func getUdpPorts() -> Set<UInt16> {
        return udp_ports
    }
    
    func setTypes(_ types: Set<NodeType>) {
        self.types = types
    }
    
    func addType(_ type: NodeType) {
        types.insert(type)
    }
    
    func addService(_ service: BonjourServiceInfo) {
        services.insert(service)
    }
    
    func addV4Address(_ address: IPv4Address) {
        v4_addresses.insert(address)
    }
    
    func addV6Address(_ address: IPv6Address) {
        v6_addresses.insert(address)
    }
    
    func addName(_ name: String) {
        names.insert(name)
    }
    
    func addDnsName(_ domain_name: DomainName) {
        dns_names.insert(domain_name)
    }
    
    func addMcastFQDN(_ domain_name: FQDN) {
        mcast_dns_names.insert(domain_name)
    }
    
    func addTcpPort(_ port: UInt16) {
        tcp_ports.insert(port)
    }
    
    func addUdpPort(_ port: UInt16) {
        udp_ports.insert(port)
    }
    
    init() { }
    
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
    
    func toSectionTypes() -> Set<SectionType> {
        var section_types = Set<SectionType>()
        
        if types.contains(.localhost) {
            section_types.insert(.localhost)
            return section_types
        }
        if types.contains(.ios) { section_types.insert(.ios) }
        if types.contains(.chargen) || types.contains(.discard) { section_types.insert(.chargen_discard) }
        if types.contains(.gateway) { section_types.insert(.gateway) }
        if types.contains(.internet) { section_types.insert(.internet) }
        if types.contains(.snmp) { section_types.insert(.snmp) }
        if !types.contains(.localhost) && !types.contains(.ios) && !types.contains(.chargen) && !types.contains(.discard) && !types.contains(.gateway) && !types.contains(.internet) && !types.contains(.snmp) { section_types.insert(.other) }
        
        return section_types
    }
    
    func merge(_ node: Node) {
        mcast_dns_names.formUnion(node.mcast_dns_names)
        dns_names.formUnion(node.dns_names)
        names.formUnion(node.names)
        v4_addresses.formUnion(node.v4_addresses)
        v6_addresses.formUnion(node.v6_addresses)
        types.formUnion(node.types)
        tcp_ports.formUnion(node.tcp_ports)
        udp_ports.formUnion(node.udp_ports)
        
        // merge services
        var name_to_service_info = [String: BonjourServiceInfo]()
        _ = services.map({ name_to_service_info[$0.name] = $0 })
        var node_name_to_service_info = [String: BonjourServiceInfo]()
        _ = node.services.map({ node_name_to_service_info[$0.name] = $0 })
        name_to_service_info.merge(node_name_to_service_info) { (_, new) in new }
        services = Set(name_to_service_info.map { $0.value })
    }
    
    func isSimilar(with: Node) -> Bool {
        if !(v4_addresses.filter { $0.isUnicast() /* && !$0.isLocal() */ }.intersection(with.v4_addresses.filter { $0.isUnicast() /* && !$0.isLocal() */ }).isEmpty) { return true }
        
        if !(v6_addresses.filter { !$0.isMulticastPublic() }.intersection(with.v6_addresses.filter { !$0.isMulticastPublic() }).isEmpty) { return true }
        
        if !mcast_dns_names.intersection(with.mcast_dns_names).isEmpty { return true }
        
        if !dns_names.intersection(with.dns_names).isEmpty { return true }
        
        return false
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.mcast_dns_names == rhs.mcast_dns_names && lhs.dns_names == rhs.dns_names && lhs.names == rhs.names && lhs.v4_addresses == rhs.v4_addresses && lhs.v6_addresses == rhs.v6_addresses && lhs.tcp_ports == rhs.tcp_ports && lhs.udp_ports == rhs.udp_ports && lhs.types == rhs.types && lhs.services == rhs.services
    }
    
    func dump() -> String {
        var ret = "DUMP NODE: "
        ret = ret + "dns_names: "
        for foo in dns_names {
            ret = ret + foo.toString() + "; "
        }
        return ret
    }
    
    func fullDump() -> String {
        var ret = "FULL DUMP NODE: "
        ret = ret + "mcast_dns_names: "
        for foo in mcast_dns_names {
            ret = ret + foo.toString() + "; "
        }
        ret = ret + "dns_names: "
        for foo in dns_names {
            ret = ret + foo.toString() + "; "
        }
        ret = ret + "names: "
        for foo in names {
            ret = ret + foo + "; "
        }
        ret = ret + "IPv4: "
        for foo in v4_addresses {
            ret = ret + (foo.toNumericString() ?? "no_string_for_this_IPv4") + "; "
        }
        ret = ret + "IPv6: "
        for foo in v6_addresses {
            ret = ret + (foo.toNumericString() ?? "no_string_for_this_IPv6") + "; "
        }
        return ret
    }
    
    func concisefullDump() -> String {
        var ret = ""
        for foo in mcast_dns_names {
            ret = ret + (ret.isEmpty ? "" :  " - ") + foo.toString()
        }
        for foo in dns_names {
            ret = ret + (ret.isEmpty ? "" :  " - ") + foo.toString()
        }
        for foo in names {
            ret = ret + (ret.isEmpty ? "" :  " - ") + foo
        }
        for foo in v4_addresses {
            ret = ret + (ret.isEmpty ? "" :  " - ") + (foo.toNumericString() ?? "no_string_for_this_IPv4")
        }
        for foo in v6_addresses {
            ret = ret + (ret.isEmpty ? "" :  " - ") + (foo.toNumericString() ?? "no_string_for_this_IPv6")
        }
        return ret
    }
}

class ModelSection {
    var icon_description: String
    var description: String
    var detailed_description: String
    var nodes = [Node]()
    
    init(_ icon_description: String, _ description: String, _ detailed_description: String) {
        self.icon_description = icon_description
        self.description = NSLocalizedString(description, comment: "description")
        self.detailed_description = NSLocalizedString(detailed_description, comment: "detailled description")
    }
}

struct DiscoveredPort: Identifiable {
    let id = UUID()
    var name: String
    var is_selected = true
    var port: Port
}

@MainActor
class DiscoveredPortsModel: ObservableObject {
    static let shared = DiscoveredPortsModel()
    @Published var discovered_ports = [DiscoveredPort]() {
        didSet(oldValue) {
            filtering = !getSelectedPorts().isEmpty
        }
    }
    @Published var filtering = false
    @Published var filter_active = false

    func getDiscoveredPortIndex(id: UUID) -> Array<DiscoveredPort>.Index? {
        return discovered_ports.firstIndex { $0.id == id }
    }
    
    func selectAll() {
        for idx in discovered_ports.indices {
            discovered_ports[idx].is_selected = true
        }
    }
    
    func deSelectAll() {
        for idx in discovered_ports.indices {
            discovered_ports[idx].is_selected = false
        }
    }

    func getSelectedPorts() -> [Port] {
        discovered_ports.filter { $0.is_selected }.map { $0.port }
    }
    
    func update(port_list: PortMapper) {
        // Amélioration potentielle : plutôt que de tout recréer, il faudrait plutôt faire du différentiel pour ne pas supprimer les UUID déjà existants et qui restent
        
        var is_prev_name_selected = [Port: Bool]()
        for port in discovered_ports {
            is_prev_name_selected[port.port] = port.is_selected
        }
        
        var new_discovered_ports = [DiscoveredPort]()

        for port_list_key in port_list.keys.sorted(by: { $0.port_number <= $1.port_number }) {
            let port_info = port_list[port_list_key]!
            
            var name = port_info.bonjour_service?.description
            if name == nil {
                name = port_info.service?.description
                if name == nil {
                    name = ""
                }
            }
            guard var name else { fatalError("should not happen") }
            
            // let name_prefix = "\(port_list_key.ip_protocol == .TCP ? "TCP" : "UDP")/\(port_list_key.port_number)"
            let name_prefix = port_list_key.description

            if name.hasPrefix("_") {
                name = String(name.dropFirst())
            }
            
            if name.hasSuffix("._tcp.") || name.hasSuffix("._udp.") {
                name = String(name.dropLast(6))
            }

            // Already discovered ports do not change selection status and new ports are selected by default
            let is_selected = is_prev_name_selected[port_list_key] ?? false

            // Some devices rename standard TCP ports with weird names (HP scanners name the TCP/80 port "uscan" and the TCP/443 port "uscans"), so we recover the standard name
            if port_list_key.port_number == 80 && port_list_key.ip_protocol == .TCP { name = "http" }
            if port_list_key.port_number == 443 && port_list_key.ip_protocol == .TCP { name = "https" }

            new_discovered_ports.append(DiscoveredPort(name: "\(name_prefix) x\(port_info.count): \(name)", is_selected: is_selected, port: port_list_key))
        }
        
        discovered_ports = new_discovered_ports
    }
}

// The DBMaster database instance is accessible with DBMaster.shared
@MainActor
class DBMaster {
    static let shared = DBMaster()

    var sections: [SectionType : ModelSection]

    private(set) var nodes: Set<Node> {
        didSet(oldValue) {
            DiscoveredPortsModel.shared.update(port_list: DBMaster.getPorts())
        }
    }
    
    private(set) var networks: Set<IPNetwork>

    func resetNetworks() {
        networks = Set<IPNetwork>()
    }

    // Get the first indexPath corresponding to a node
    func getIndexPath(_ node: Node) -> IndexPath? {
        for section_type in SectionType.allCases {
            let section = sections[section_type]!
            for node_index in 0..<section.nodes.count {
                if section.nodes[node_index].isSimilar(with: node) {
                    return IndexPath(row: node_index, section: section_type.rawValue)
                }
            }
        }
        return nil
    }

    func addNode(_ new_node: Node, demo_mode: Bool = false) -> (removed_paths: [IndexPath], inserted_paths: [IndexPath], is_new_node: Bool, updated_nodes: Set<Node>, removed_nodes: [Node : Node?]) {
        if iOS_tools.demo_mode && demo_mode == false {
            return (removed_paths: [], inserted_paths: [], is_new_node: false, updated_nodes: Set(), removed_nodes: [:])
        }
        return addOrRemoveNode(new_node, add: true)
    }

    func removeNode(_ node: Node) -> [IndexPath] {
        return addOrRemoveNode(node, add: false).removed_paths
    }

    /* 1 gateway per IP */
    /*
    func getLocalGateways() -> [Node] {
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

    static func getNode(name: String) -> Node? {
        shared.nodes.filter { $0.names.contains(name) }.first
    }

    static func getNode(mcast_fqdn: FQDN) -> Node? {
        shared.nodes.filter { $0.mcast_dns_names.contains(mcast_fqdn) }.first
    }

    static func getNode(address: IPAddress) -> Node? {
        if address.getFamily() == AF_INET {
            let addr = address as! IPv4Address
            let nodes = shared.nodes.filter { $0.v4_addresses.contains(addr) }
            if nodes.count > 1 {
                print("\(#function): Warning: bad number of nodes for one IPv4 address")
            }
            return nodes.first
        } else {
            let addr = address as! IPv6Address
            let nodes = shared.nodes.filter { $0.v6_addresses.contains(addr) }
            if nodes.count > 1 {
                print("\(#function): Warning: bad number of nodes for one IPv6 address")
            }
            return nodes.first
        }
    }

    static private func getPorts(nodes: Set<Node>? = nil) -> PortMapper {
        var port_list = PortMapper()

        var tcp_ports = Set<PortNumber>()
        var udp_ports = Set<PortNumber>()
        var tcp_ports_count = [PortNumber : UInt]()
        var udp_ports_count = [PortNumber : UInt]()

        for node in shared.nodes {
            tcp_ports.formUnion(node.tcp_ports)
            udp_ports.formUnion(node.udp_ports)
            for n in node.tcp_ports {
                if !tcp_ports_count.keys.contains(n) { tcp_ports_count[n] = 0 }
                tcp_ports_count[n]! += 1
            }
            for n in node.udp_ports {
                if !udp_ports_count.keys.contains(n) { udp_ports_count[n] = 0 }
                udp_ports_count[n]! += 1
            }
        }

        for n in tcp_ports {
            let port = Port(port_number: n, ip_protocol: .TCP)
            port_list[port] = (service: TCPPort2Service[n], bonjour_service: Ports2BonjourServices.shared.get(port), count: tcp_ports_count[n]!)
        }

        for n in udp_ports {
            let port = Port(port_number: n, ip_protocol: .UDP)
            port_list[port] = (service: TCPPort2Service[n], bonjour_service: Ports2BonjourServices.shared.get(port), count: udp_ports_count[n]!)
        }
        
        return port_list
    }
    
    static private func getPorts() -> PortMapper {
        var port_list = [Port : (service: ServiceName?, bonjour_service: BonjourServiceName?, count: UInt)]()

        var tcp_ports = Set<PortNumber>()
        var udp_ports = Set<PortNumber>()
        var tcp_ports_count = [PortNumber : UInt]()
        var udp_ports_count = [PortNumber : UInt]()

        for node in shared.nodes {
            tcp_ports.formUnion(node.tcp_ports)
            udp_ports.formUnion(node.udp_ports)
            for n in node.tcp_ports {
                if !tcp_ports_count.keys.contains(n) { tcp_ports_count[n] = 0 }
                tcp_ports_count[n]! += 1
            }
            for n in node.udp_ports {
                if !udp_ports_count.keys.contains(n) { udp_ports_count[n] = 0 }
                udp_ports_count[n]! += 1
            }
        }

        for n in tcp_ports {
            let port = Port(port_number: n, ip_protocol: .TCP)
            port_list[port] = (service: TCPPort2Service[n], bonjour_service: Ports2BonjourServices.shared.get(port), count: tcp_ports_count[n]!)
        }

        for n in udp_ports {
            let port = Port(port_number: n, ip_protocol: .UDP)
            port_list[port] = (service: TCPPort2Service[n], bonjour_service: Ports2BonjourServices.shared.get(port), count: udp_ports_count[n]!)
        }
        
        return port_list
    }

    static func getNodes(_ port: Port) -> Set<Node> {
        var nodes = Set<Node>()

        for node in shared.nodes {
            switch port.ip_protocol {
            case .TCP:
                if node.tcp_ports.contains(port.port_number) {
                    nodes.insert(node)
                }

            case .UDP:
                if node.udp_ports.contains(port.port_number) {
                    nodes.insert(node)
                }
            }
        }

        return nodes
    }

    static func getIPsAndPorts() -> [(IPAddress, Set<UInt16>)] {
        var result = [(IPAddress, Set<UInt16>)]()

        for node in shared.nodes {
            // We only get the first IPv4 and IPv6 addresses to optimize the browsing process
            if let addr = node.getV4Addresses().first {
                result.append((addr, node.getTcpPorts()))
            } else if let addr = node.getV6Addresses().first {
                result.append((addr, node.getTcpPorts()))
            }
        }

        return result
    }

    /* A unique gateway */
    func getLocalGateways() -> [Node] {
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
                    // We only add IPv4 gateway IPs since only one such IP is necessary to check the local host for SNMP and there are a lot if IPv6 addresses on iOS devices. So it is faster to only add IPv4 addresses.
                    SNMPManager.manager.addIpToCheck(addr)
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

    func getLocalNodeIfExists() -> Node? {
        nodes.filter { $0.isLocalHost() }.first
    }
    
    func getLocalNode() -> Node {
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
                    // Do not check local IP adresses, for the SNMP module to be more available
                    // We only add IPv4 local IPs since only one such IP is necessary to check the local host for SNMP and there are a lot if IPv6 addresses on iOS devices. So it is faster to only add IPv4 addresses.
                    // SNMPManager.manager.addIpToCheck(address)

                case AF_INET6:
                    let address = my_sock_addr.getIPAddress() as! IPv6Address
                    node.v6_addresses.insert(address)
                    networks.insert(IPNetwork(ip_address: address.and(IPv6Address(mask_len: UInt8(mask_len))), mask_len: UInt8(mask_len)))
                    
                default:
                    #fatalError("bad address family")
                }
            }
            idx += 1
        } while mask_len >= 0

        node.names.insert(UIDevice.current.name)
        node.dns_names.insert(DomainName(HostPart(UIDevice.current.name.replacingOccurrences(of: ".", with: "_"))))
        return node
    }
    
    func notifyBroadcast() {
        Interman3DModel.shared.notifyBroadcast()
    }

    func notifyBroadcastFinished() {
        Interman3DModel.shared.notifyBroadcastFinished()
    }
    
    func notifyScanPorts(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyScanNode(node, address)
    }

    func notifyScanPortsFinished(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        if node.isLocalHost() { return }
        Interman3DModel.shared.notifyScanNodeFinished(node, address)
    }

    func notifyPortDiscovered(address: IPAddress, port: UInt16) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        if node.isLocalHost() { return }
        Interman3DModel.shared.notifyPortDiscovered(node, port)
    }

    func notifyICMPSent(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyICMPSent(node, address)
    }

    func notifyICMPReceived(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyICMPReceived(node, address)
    }
    
    func notifyFloodUDP(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyFloodUDP(node, address)
    }

    func notifyFloodUDPFinished(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyFloodUDPFinished(node, address)
    }

    func notifyFloodTCP(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyFloodUDP(node, address)
    }

    func notifyFloodTCPFinished(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyFloodUDPFinished(node, address)
    }

    func notifyChargenTCP(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyFloodUDP(node, address)
    }

    func notifyChargenTCPFinished(address: IPAddress) {
        guard let node = DBMaster.getNode(address: address) else {
            print("can not find node with address \(address)")
            return
        }
        Interman3DModel.shared.notifyFloodUDPFinished(node, address)
    }

    func removeAllNodes() {
        SectionType.allCases.forEach {
            sections[$0]!.nodes.removeAll()
        }
        nodes.forEach {
            Interman3DModel.shared.notifyNodeRemoved($0)
        }
        nodes.removeAll()
    }
    
    private func addOrRemoveNode(_ new_node: Node, add: Bool) -> (removed_paths: [IndexPath], inserted_paths: [IndexPath], is_new_node: Bool, updated_nodes: Set<Node>, removed_nodes: [Node : Node]) {
        var first_merged_node: Node? = nil
        
        // le pb : removed_nodes : values doit pas être nil - créer in noeud dont l'IP est 0.0.0.0 ?
        
//        print(#function)
        // pour débugguer la complexité de l'algo de création d'un noeud
//        let start_time = Date()
//        GenericTools.printDuration(idx: 0, start_time: start_time)

        // This algorithm does not make the assumption that being similar is having a common property value: it works even if merging two similar nodes into one of them results in a node that may be similar to nodes that where not similar to the two inital nodes. This is a lazier definition of similarity than having a common property value.

        var index_paths_removed = [IndexPath]()
        var index_paths_inserted = [IndexPath]()

        var is_new_node = false
        // keys: removed nodes; values: nodes in which removed nodes have been merged into
        var removed_nodes = [Node : Node]()
        
        // Track deduplicated nodes: nodes in arr_nodes that were already in arr_nodes and that have been updated (merged) with other nodes already present in arr_nodes (those other nodes are removed from arr_nodes during this process). Therefore, the nodes that have been updated are dedup nodes and the node in which new_node has been merged into (if it was similar to an existing node).
        var dedup = Set<Node>()

        if new_node == Node() || (add && nodes.contains(new_node)) {
            return (index_paths_removed, index_paths_inserted, is_new_node, dedup, removed_nodes)
        }
        
        // Create the new node list including the new node
        var arr_nodes = Array(nodes)
        
        // pour débugguer la complexité de l'algo de création d'un noeud
//        GenericTools.printDuration(idx: 1, start_time: start_time)

        // Merge into one node the new node and every nodes which are similar to it
        if add {
            var merged_index: Int = -1
            // Find one node similar to the new one and merge the new one in it, then set merged_index to its index
            for i in 0..<arr_nodes.count {
                if arr_nodes[i].isSimilar(with: new_node) {
                    arr_nodes[i].merge(new_node)
                    merged_index = i
                    break
                }
            }

            // If no similar node was found, add the new node
            if merged_index == -1 {
                is_new_node = true
                arr_nodes.append(new_node)
                // since this is a new node, dedup and removed_nodes will be empty
            }
            // If one similar node has been merged into one existing node, merge every similar nodes into the existing node
            else {
                first_merged_node = arr_nodes[merged_index]
                repeat {
                    var merged = false
                    for i in 0..<arr_nodes.count {
                        if i == merged_index { continue }
                        if arr_nodes[i].isSimilar(with: arr_nodes[merged_index]) {
                            arr_nodes[i].merge(arr_nodes[merged_index])
                            dedup.insert(arr_nodes[i])
                            removed_nodes[arr_nodes[merged_index]] = arr_nodes[i]
                            arr_nodes.remove(at: merged_index)
                            if i < merged_index { merged_index = i } else { merged_index = i - 1 }
                            merged = true
                            break
                        }
                    }
                    if !merged { merged_index = -1 }
                } while merged_index != -1
            }
        } else {
            arr_nodes.removeAll { $0 == new_node }
            removed_nodes[new_node] = Node()
        }
        // Starting at this line, arr_nodes contains every distinct nodes (i.e. not similar) and dedup contains the subset of arr_nodes that have been merged

        // pour débugguer la complexité de l'algo de création d'un noeud
//        GenericTools.printDuration(idx: 2, start_time: start_time)

        // In each section, locate and let only one node for those that have been deduplicated (for the others, it is already done)
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

        // Flatten removed_nodes
        removed_nodes.keys.forEach { node in
            func containsIdentical(keys: Dictionary<Node, Node>.Keys, search: Node) -> Bool {
                for key in keys {
                    if key === search {
                        return true
                    }
                }
                return false
            }
            func getLastInChain(_ node: Node) -> Node {
                // Do not use removed_nodes.keys.contains(node) but containsIdentical(keys: removed_nodes.keys, search: node) because contains() makes use of == and not ===. Using == leads to an infinite loop.
                return containsIdentical(keys: removed_nodes.keys, search: node) ? getLastInChain(removed_nodes[node]!) : node
            }
            removed_nodes[node] = getLastInChain(node)
        }
        
        // pour débugguer la complexité de l'algo de création d'un noeud
        // GenericTools.printDuration(idx: 4, start_time: start_time)

        // Sync this model with the 3D model

        // Deal with removed or merged nodes
        removed_nodes.forEach { (key: Node, value: Node) in
            if value != Node() {
                Interman3DModel.shared.notifyNodeMerged(key, value)
            } else {
                Interman3DModel.shared.notifyNodeRemoved(key)
            }
        }

        // New node (therefore there is not any removed, merged nor updated nodes)
        if is_new_node {
            Interman3DModel.shared.notifyNodeAdded(new_node)
        }

        if let first_merged_node {
            // Add first_merged_node to dedup to make dedup finally contain every updated nodes, since we notify about every updated nodes and return them at the end of this function
            dedup.insert(first_merged_node)
            // dedup is now the updated node set
        }

        // Deal with updated nodes
        dedup.forEach { node in
            Interman3DModel.shared.notifyNodeUpdated(node)
        }
        
        return (index_paths_removed, index_paths_inserted, is_new_node, dedup, removed_nodes)
    }

    private let ips_v4_google = [ "8.8.4.4", "8.8.8.8" ]
    private let ips_v6_google = [ "2001:4860:4860::8844", "2001:4860:4860::8888" ]
    private let ips_v4_quad9 = [ "9.9.9.9", "149.112.112.9" ]
    private let ips_v6_quad9 = [ "2620:fe::9", "2620:fe::fe:9" ]

    func addDefaultNodes() async {
        if demo_mode {
            // To get a good looking screenshot: set iPhone Agnès to the right and let Marantz being viewed from side
            var node = Node()

            node.mcast_dns_names.insert(FQDN("  router", "fenyo.net"))
            node.v4_addresses.insert(IPv4Address("192.168.0.254")!)
            node.v6_addresses.insert(IPv6Address("2a01:e0a:582:ab83:20d:edff:fec0:49c3")!)
            node.types = [ .gateway ]
            _ = addNode(node, demo_mode: true)

            node = Node()
            node.mcast_dns_names.insert(FQDN("   Mac Mini", "local"))
            node.v4_addresses.insert(IPv4Address("192.168.0.42")!)
            node.v6_addresses.insert(IPv6Address("2a01:e0a:582:ab83:abed:42ba:dd1:abb0")!)
            node.addService(BonjourServiceInfo("_airplay._tcp.", "7000", ["model":"Macmini"]))
            _ = addNode(node, demo_mode: true)

            node = Node()
            node.mcast_dns_names.insert(FQDN("iPhone Agnès", "local"))
            node.v4_addresses.insert(IPv4Address("192.168.0.17")!)
            node.v6_addresses.insert(IPv6Address("2a01:e0a:582:ab83:9331:91aa:2dd2:53c1")!)
            _ = addNode(node, demo_mode: true)

            node = Node()
            node.mcast_dns_names.insert(FQDN("Mac Book", "local"))
            node.v4_addresses.insert(IPv4Address("192.168.0.172")!)
            node.v6_addresses.insert(IPv6Address("2a01:e0a:582:ab83:831:ab8:2232:5ba")!)
            _ = addNode(node, demo_mode: true)

            node = Node()
            node.mcast_dns_names.insert(FQDN("iPad Alexandre", "local"))
            node.v4_addresses.insert(IPv4Address("192.168.0.20")!)
            node.v6_addresses.insert(IPv6Address("2a01:e0a:582:ab83:812:9a52:2aab:ffe0")!)
            _ = addNode(node, demo_mode: true)

            node = Node()
            node.mcast_dns_names.insert(FQDN("Home Pod", "local"))
            node.v4_addresses.insert(IPv4Address("192.168.0.125")!)
            node.v6_addresses.insert(IPv6Address("2a01:e0a:582:ab83:f3a:3911:a92:7a11")!)
            node.addService(BonjourServiceInfo("_airplay._tcp.", "7000", ["model":"AudioAccessory"]))
            _ = addNode(node, demo_mode: true)

            node = Node()
            node.mcast_dns_names.insert(FQDN("Apple TV", "local"))
            node.v4_addresses.insert(IPv4Address("192.168.0.45")!)
            node.v6_addresses.insert(IPv6Address("2a01:e0a:582:ab83:ff2:2c2a:192:22a1")!)
            node.addService(BonjourServiceInfo("_airplay._tcp.", "7000", ["model":"AppleTV"]))
            _ = addNode(node, demo_mode: true)

            node = Node()
            node.mcast_dns_names.insert(FQDN("printer", "fenyo.net"))
            node.v4_addresses.insert(IPv4Address("192.168.0.12")!)
            node.v6_addresses.insert(IPv6Address("2a01:e0a:582:ab83:32a:edfe:ab20:24c1")!)
            node.addService(BonjourServiceInfo("_pdl-datastream._tcp.", "515", [:]))
            _ = addNode(node, demo_mode: true)

            node = Node()
            node.mcast_dns_names.insert(FQDN("Marantz", "local"))
            node.v4_addresses.insert(IPv4Address("192.168.0.63")!)
            node.addService(BonjourServiceInfo("_raop._tcp.", "49152", [:]))
            _ = addNode(node, demo_mode: true)
        }
        
        var node = Node()
        node.mcast_dns_names.insert(FQDN("flood", "eowyn.eu.org"))
        node.v4_addresses.insert(IPv4Address("51.75.31.39")!)
        node.v6_addresses.insert(IPv6Address("2001:41d0:304:200::9001")!)
        node.types = [ .chargen, .internet ]
        _ = addNode(node, demo_mode: true)
        SNMPManager.manager.addIpToCheck(IPv4Address("51.75.31.39")!)

        node = Node()
        node.mcast_dns_names.insert(FQDN("dns", "google"))
        for addr in ips_v4_google { node.v4_addresses.insert(IPv4Address(addr)!) }
        for addr in ips_v6_google { node.v6_addresses.insert(IPv6Address(addr)!) }
        node.types = [ .internet ]
        _ = addNode(node, demo_mode: true)

        node = Node()
        node.mcast_dns_names.insert(FQDN("dns9", "quad9.net"))
        for addr in ips_v4_quad9 { node.v4_addresses.insert(IPv4Address(addr)!) }
        for addr in ips_v6_quad9 { node.v6_addresses.insert(IPv6Address(addr)!) }
        node.types = [ .internet ]
        _ = addNode(node, demo_mode: true)

        let config = UserDefaults.standard.stringArray(forKey: "nodes") ?? [ ]
        for str in config {
            let str_fields = str.split(separator: ";", maxSplits: 2)
            let (target_name, target_ip, node_type_str) = (String(str_fields[0]), String(str_fields[1]), String(str_fields[2]))
            let node_type: NodeType = NodeType(rawValue: Int(node_type_str)!)!
            let node = Node()
            node.dns_names.insert(DomainName(target_name)!)
            if isIPv4(target_ip) {
                node.v4_addresses.insert(IPv4Address(target_ip)!)
                SNMPManager.manager.addIpToCheck(IPv4Address(target_ip)!)
            } else if isIPv6(target_ip) {
                node.v6_addresses.insert(IPv6Address(target_ip)!)
                SNMPManager.manager.addIpToCheck(IPv6Address(target_ip)!)
            }
            if Int(node_type_str) != NodeType.localhost.rawValue {
                node.types = [ node_type ]
            }
            _ = addNode(node, demo_mode: true)
        }
    }

    func isPublicDefaultService(_ ip: String) -> Bool {
        if ips_v4_google.contains(ip) || ips_v6_google.contains(ip) || ips_v4_quad9.contains(ip) || ips_v6_quad9.contains(ip) { return true }
        return false
    }
    
    init() {
        networks = Set<IPNetwork>()

        nodes = Set<Node>()
        sections = [
            .localhost: ModelSection("Localhost", "Localhost", "this host"),
            .ios: ModelSection("iOS devices", "iOS devices", "other devices running this app"),
            .chargen_discard: ModelSection("Chargen Discard services", "Chargen Discard services", "other devices running these services"),
            .snmp: ModelSection("SNMP agents", "SNMP agents", "Devices running some SNMP agent"),
            .gateway: ModelSection("Local gateway", "Local gateway", "local router"),
            .internet: ModelSection("Internet", "Internet", "remote hosts on the Internet"),
            .other: ModelSection("Other hosts", "Other hosts", "any host")
        ]

        Task.detached { @MainActor in
            await self.addDefaultNodes()
        }
        
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
