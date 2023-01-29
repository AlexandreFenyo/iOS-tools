//
//  ServiceBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 18/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit

class BrowserDelegate : NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private var services : [NetService] = []
    private let type : String
    private let device_manager : DeviceManager

    init(_ type: String, deviceManager: DeviceManager) {
        self.type = type
        device_manager = deviceManager
    }

    // MARK: - NetServiceBrowserDelegate

    // Remote service app discovered
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print(#function)
        // Only add remote services
        if (service.name != UIDevice.current.name) {
            services.append(service)
            service.delegate = self
            service.resolve(withTimeout: TimeInterval(10))
        }
    }

    // Remote service app closed
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print(#function)
        if let idx = services.firstIndex(of: service) { services.remove(at: idx) }
        else {
            print("warning: service app closed but not previously discovered")
        }
    }

    // Simulate by switching Wi-Fi off and returning to the app
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print(#function)
//        print("didNotSearch")
//        for err in errorDict {
//            print("didNotSearch:", err.key, ":", err.value)
//        }

        // Restart browsing
        // ce n'est pas la bonne méthode pour redémarrer la recherche car ce searchForServices rappelle netServiceBrowser avec didNotSearch donc on boucle jusqu'à saturer la pile, il faudrait déléguer à plus tard cette recherche, ou afficher un pop-up pour que l'utilisateur le fasse
        // browser.stop()
        // browser.searchForServices(ofType: type, inDomain: NetworkDefaults.local_domain_for_browsing)
    }

    // A search is commencing
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print(#function)
        device_manager.addTrace("Start browsing multicast DNS / Bonjour services of type \(type)", level: .INFO)
    }

    // A search was stopped
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print(#function)
        device_manager.addTrace("Stop browsing multicast DNS / Bonjour services of type \(type)", level: .INFO)
    }

    // MARK: - NetServiceDelegate

    // Service that the browser had found but has not been resolved
    // Simulate by setting a TimeInterval of 0.1 when resolving the service
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print(#function)
        for err in errorDict { print("didNotResolve:", err.key, ":", err.value) }
        if let idx = services.firstIndex(of: sender) { services.remove(at: idx) }
        else { print("warning: service browsed but not resolved") }
    }

    // NetService resolved with address(es) and timeout reached
    public func netServiceDidStop(_ sender: NetService) {
        print(#function)
        print("netServiceDidStop: NetService resolved with address(es) and timeout reached")
    }

    // May have found some addresses for the service
    public func netServiceDidResolveAddress(_ sender: NetService) {
        print(#function)
        // print("netServiceDidResolveAddress: name:", sender.name, "port:", sender.port)
        // From the documentation: "It is possible for a single service to resolve to more than one address or not resolve to any addresses."

        let node = Node()

        node.types = [ .chargen, .discard, .ios ]
        node.tcp_ports.insert(NetworkDefaults.speed_test_chargen_port)
        node.tcp_ports.insert(NetworkDefaults.speed_test_discard_port)
        node.tcp_ports.insert(NetworkDefaults.speed_test_app_port)

        if sender.addresses != nil {
            for data in sender.addresses! {
                let sock_addr = SockAddr.getSockAddr(data)
                switch sock_addr.getFamily() {
                case AF_INET:
                    node.v4_addresses.insert(sock_addr.getIPAddress() as! IPv4Address)
                    if let info = sock_addr.getIPAddress()!.toNumericString() { device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + info) }

                case AF_INET6:
                    node.v6_addresses.insert(sock_addr.getIPAddress() as! IPv6Address)
                    if let info = sock_addr.getIPAddress()!.toNumericString() { device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + info) }

                default:
                    fatalError("can not be here")
                }
            }
        }

        // sender.domain not used ("local.")
        if !sender.name.isEmpty {
            node.names.insert(sender.name)
            device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + sender.name)
        }
        if let domain = DomainName(sender.hostName!) {
            node.dns_names.insert(domain)
            device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + sender.name)
        }

        device_manager.addNode(node, resolve_ipv4_addresses: node.v4_addresses)
    }
}

class ServiceBrowser : NetServiceBrowser {
    private let browser_delegate : BrowserDelegate
    private let type : String
    private let device_manager : DeviceManager

    init(_ type: String, deviceManager: DeviceManager) {
        device_manager = deviceManager
        browser_delegate = BrowserDelegate(type, deviceManager: deviceManager)
        self.type = type
        super.init()
        self.delegate = browser_delegate
    }

    public func search() {
        device_manager.addTrace("searchForServices(\(type), \(NetworkDefaults.local_domain_for_browsing))", level: .ALL)

        searchForServices(ofType: type, inDomain: NetworkDefaults.local_domain_for_browsing)
    }
}
