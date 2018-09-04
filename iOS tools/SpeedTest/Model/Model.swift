//
//  Model.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 04/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class DomainPart : Hashable {
    var hashValue: Int
    internal let name: String

    public init(_ name : String) {
        if name.isEmpty { fatalError("DomainPart") }
        self.name = name
        hashValue = name.hashValue
    }

    static func == (lhs: DomainPart, rhs: DomainPart) -> Bool {
        return lhs.name == rhs.name
    }
}

class HostPart : DomainPart {
    public override init(_ name : String) {
        if name.contains(".") { fatalError("HostPart") }
        super.init(name)
    }
}

class DomainName : Hashable {
    var hashValue: Int
    
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

    static func == (lhs: DomainName, rhs: DomainName) -> Bool {
        return lhs.host_part == rhs.host_part && lhs.domain_part == rhs.domain_part
    }
}

class FQDN : DomainName {
    public init(_ host_part : String, _ domain_part : String) {
        super.init(HostPart(host_part), DomainPart(domain_part))
    }
}

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

class DBMaster {
    private var nodes : [Node] = []
}

func xxxtst() {
    var f = FQDN("toto", "truc")
    var address : [IPAddress] = []
    let ad = address + address
//    var g : DomainName
//    f = DomainName(FQDN)
    
}
