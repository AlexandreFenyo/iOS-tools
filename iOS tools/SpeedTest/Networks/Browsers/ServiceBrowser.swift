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
        // Only add remote services
        if (service.name != UIDevice.current.name) {
            services.append(service)
            service.delegate = self
            service.resolve(withTimeout: TimeInterval(10))
        }
    }

    // Remote service app closed
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("didRemove")
        if let idx = services.index(of: service) { services.remove(at: idx) }
        else { print("warning: service app closed but not previously discovered") }
    }

    // Simulate by switching Wi-Fi off and returning to the app
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("didNotSearch")
        for err in errorDict { print("didNotSearch:", err.key, ":", err.value) }

        // Restart browsing
        browser.stop()
        browser.searchForServices(ofType: type, inDomain: NetworkDefaults.local_domain_for_browsing)
    }

    // A search is commencing
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserWillSearch")
    }

    // A search was stopped
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("netServiceBrowserDidStopSearch")
    }

    // MARK: - NetServiceDelegate

    // Service that the browser had found but has not been resolved
    // Simulate by setting a TimeInterval of 0.1 when resolving the service
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("didNotResolve")
        for err in errorDict { print("didNotResolve:", err.key, ":", err.value) }
        if let idx = services.index(of: sender) { services.remove(at: idx) }
        else { print("warning: service browsed but not resolved") }
    }

    // NetService resolved with address(es) and timeout reached
    public func netServiceDidStop(_ sender: NetService) {
        print("netServiceDidStop: NetService resolved with address(es) and timeout reached")
    }

    // May have found some addresses for the service
    public func netServiceDidResolveAddress(_ sender: NetService) {
        print("netServiceDidResolveAddress: name:", sender.name, "port:", sender.port)
        // From the documentation: "It is possible for a single service to resolve to more than one address or not resolve to any addresses."

        var addresses : [IPAddress] = []
        if sender.addresses != nil {
            for data in sender.addresses! {
                let sock_addr = SockAddr.getSockAddr(data)
                switch sock_addr.getFamily() {
                case AF_INET:
                    print("  hostname:", sock_addr.resolveHostName(), "IPv4:", sock_addr.getNumericAddress())
                    addresses.append(sock_addr.getIPAddress()!)

                case AF_INET6:
                    print("  hostname:", sock_addr.resolveHostName(), "IPv6:", sock_addr.getNumericAddress())
                    addresses.append(sock_addr.getIPAddress()!)

                default:
                    fatalError("can not be here")
                }
            }
        }

        device_manager.addDevice(name: sender.name, addresses: addresses)
    }
}

class ServiceBrowser : NetServiceBrowser {
    private let browser_delegate : BrowserDelegate
    private let type : String

    init(_ type: String, deviceManager: DeviceManager) {
        browser_delegate = BrowserDelegate(type, deviceManager: deviceManager)
        self.type = type
        super.init()
        self.delegate = browser_delegate
    }

    public func search() {
        print("START SEARCH")
        searchForServices(ofType: type, inDomain: NetworkDefaults.local_domain_for_browsing)
    }
}
