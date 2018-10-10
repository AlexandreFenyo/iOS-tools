//
//  Model.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

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

    public init(_ host_part : HostPart, _ domain_part : DomainPart?) {
        self.host_part = host_part
        if let domain_part = domain_part { self.domain_part = domain_part }
        else { self.domain_part = nil }
        hashValue = host_part.hashValue &+ (domain_part?.hashValue ?? 0)
    }

    public convenience init(_ host_part : String, _ domain_part : String?) {
        self.init(HostPart(host_part), domain_part != nil ? DomainPart(domain_part!) : nil)
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
// ex of dns names: localhost, localhost.localdomain, www.fenyo.net , www
class Node {
    private var mDNS_names = Set<FQDN>()
    private var dns_names = Set<DomainName>()
    private var v4_addresses = Set<IPv4Address>()
    private var v6_addresses = Set<IPv6Address>()

    private var adresses: Set<IPAddress> {
        return (v4_addresses as Set<IPAddress>).union(v6_addresses)
    }

    private var fqdn_dns_names: Set<FQDN> {
        return dns_names.filter { (dns_name) -> Bool in
            dns_name.isFQDN()
        } as! Set<FQDN>
    }

    private var fqdn_names: Set<FQDN> {
        return fqdn_dns_names.union(mDNS_names)
    }
    
    private var short_names: Set<HostPart> {
        return Set(mDNS_names.map { $0.host_part }).union(Set(dns_names.map { $0.host_part }))
    }

}

// The DBMaster database instance is accessible with DBMaster.shared
class DBMaster {
    private var nodes : [Node] = []
    static public let shared = DBMaster()
}

func xxxtst() {
    var f = FQDN("toto", "truc")
    var address : [IPAddress] = []
    let ad = address + address
//    var g : DomainName
//    f = DomainName(FQDN)
    
}
