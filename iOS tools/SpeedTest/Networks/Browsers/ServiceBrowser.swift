//
//  ServiceBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 18/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit
import iOSToolsMacros

/*
 voici la commande adéquate sur macOS :
 # dig -b '0.0.0.0#5352' @224.0.0.251 -p 5353  _services._dns-sd._udp.local. any +notcp +short
les réponses sont récupérées via un wireshark, ou il faut lancer cette commande sur MacOS

 les IP multicast :
 224.0.0.251
 ff02::fb

 liste des services Bonjour : https://jonathanmumm.com/tech-it/mdns-bonjour-bible-common-service-strings-for-various-vendors/
 <string>_services._dns-sd._udp</string>

 il faudrait identifier comment fonctionnent les sub pour les intégrer éventuellement
 <string>_invoke._sub._bp2p._tcp</string>
 <string>_webdav._sub._bp2p._tcp</string>
 <string>_print._sub._ipp._tcp</string>
 <string>_cups._sub._ipps._tcp</string>
 <string>_print._sub._ipps._tcp</string>
 <string>_printer._sub._http._tcp</string>
 <string>_Friendly._sub._bp2p._tcp</string>
 */

class BrowserDelegate : NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private var services: [NetService] = []
    private let type: String
    private let device_manager: DeviceManager

    init(_ type: String, deviceManager: DeviceManager) {
        self.type = type
        device_manager = deviceManager
    }

    private static func bytesToString(_ data: Data) -> String {
        var retval = ""
        for val in data { retval += String(UnicodeScalar(val)) }
        return retval
    }

    private func decodeTxt(_ data: Data) -> [String : String] {
        if let _size = data.first {
            let size = Int(_size)
            if size == 0 {
                // print("\(#function) error: invalid null size")
                return [:]
            }
            // from here, data.indices.first is not nil
            
            if data.count <= size {
                print("\(#function) error: not enough data")
                return [:]
            }
            
            let key_val = data.subdata(in: data.indices.first!.advanced(by: 1)..<data.indices.first!.advanced(by: size + 1))
            if let marker = key_val.firstIndex(of: ("=" as Character).asciiValue!) {
                // from here, key_val.indices.first is not nil

                if marker == key_val.indices.first! {
                    print("\(#function) error: empty key")
                    return decodeTxt(data.suffix(from: data.indices.first!.advanced(by: size + 1)))
                }
                let key = key_val.subdata(in: key_val.indices.first!..<marker)
                let key_str = Self.bytesToString(key)
                let val = key_val.suffix(from: marker.advanced(by: 1))
                let val_str = Self.bytesToString(val)

                var dict = size + 1 < data.count ? decodeTxt(data.suffix(from: data.indices.first!.advanced(by: size + 1))) : [:]
                dict[key_str] = val_str
                return dict
            } else {
                // on va créer une entrée sans valeur, de type "clé=THIS_IS_NOT_A_VALUE_AFAFAF", mais en réalité c'est une entrée sans "=", c'est permis par le protocole (https://grouper.ieee.org/groups/1722/contributions/2009/Bonjour%20Device%20Discovery.pdf), on remet en forme correctement au moment de l'afficher, dans DetailViewModel.updateDetails()
                var dict = size + 1 < data.count ? decodeTxt(data.suffix(from: data.indices.first!.advanced(by: size + 1))) : [:]
                dict[Self.bytesToString(key_val)] = "THIS_IS_NOT_A_VALUE_AFAFAF"
                return dict
            }
        }
        print("\(#function) error: empty data")
        return [:]
    }

    // MARK: - NetServiceBrowserDelegate

    // Remote service app discovered
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        // print(#function)
//        if (service.name != UIDevice.current.name) {
            services.append(service)
            service.delegate = self
            service.resolve(withTimeout: TimeInterval(10))
//        }
    }

    // Remote service app closed
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        // print(#function)
        if let idx = services.firstIndex(of: service) {
            let trace = "Bonjour/mDNS: service disappeared: name:\(service.name); hostname:\(service.hostName ?? ""); sender.type:\(service.type); port:\(service.port); descr:\(service.description); domain:\(service.domain)"
            Task.detached {
                await self.device_manager.addTrace(trace, level: .DEBUG)
            }
            services.remove(at: idx)
        }
        else {
            print("warning: service app closed but not previously discovered")
        }
    }

    // Simulate by switching Wi-Fi off and returning to the app
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        // print(#function)
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
//        print(#function)
        Task {
            await device_manager.addTrace("Bonjour/mDNS: start browsing multicast DNS / Bonjour services of type \(type)", level: .ALL)
        }
    }

    // A search was stopped
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        // print(#function)
        Task {
            await device_manager.addTrace("Bonjour/mDNS: stop browsing multicast DNS / Bonjour services of type \(type)", level: .ALL)
        }
    }

    // MARK: - NetServiceDelegate

    // Service that the browser had found but has not been resolved
    // Simulate by setting a TimeInterval of 0.1 when resolving the service
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        // print(#function)
        /*
        for err in errorDict {
            print("didNotResolve:", err.key, ":", err.value)
        }
         */

        if let idx = services.firstIndex(of: sender) { services.remove(at: idx) }
        else { print("warning: service browsed but not resolved") }
    }

    // NetService resolved with address(es) and timeout reached
    public func netServiceDidStop(_ sender: NetService) {
//        print(#function)
    }

    // May have found some addresses for the service
    public func netServiceDidResolveAddress(_ sender: NetService) {
        //        print(#function)
        // print("netServiceDidResolveAddress: name:", sender.name, "port:", sender.port)
        // From the documentation: "It is possible for a single service to resolve to more than one address or not resolve to any addresses."
        
        let txt_record = sender.txtRecordData()
        let port = sender.port
        let type = sender.type
        let addresses = sender.addresses
        let name = sender.name
        let host_name = sender.hostName
        let description = sender.description
        let domain = sender.domain
        
        Task.detached { @MainActor in
            
            let node = Node()
            
            var text_attr = [String : String]()
            if let data = txt_record {
                text_attr = self.decodeTxt(data)
            }
            // type value ex.: "_adisk._tcp."
            node.addService(BonjourServiceInfo(self.type, String(port), text_attr))
            /*
             print("STATIC ATTRIBUTES: type:\(type) name:\(sender.name) hostname:\(sender.hostName) sender.type:\(sender.type) port:\(sender.port) descr:\(sender.description) debug:\(sender.debugDescription) domain:\(sender.domain)")
             print("DYNAMIC ATTRIBUTES for '\(sender.name)' with type \(type): \(text_attr)")
             */
            // Fill in the dictionary ports_to_bonjour_services with the latest bonjour service name associated to a port.
            let port_number = PortNumber(port)
            let service_type = type
            Task {
                let ip_protocol: IPProtocol
                if self.type.hasSuffix("._tcp.") {
                    ip_protocol = .TCP
                } else if self.type.hasSuffix("._udp.") {
                    ip_protocol = .UDP
                } else {
                    #fatalError("invalid Bonjour service name")
                    return
                }
                let port = Port(port_number: port_number, ip_protocol: ip_protocol)
                Ports2BonjourServices.shared.add(port, service_type)
            }
            
            if self.type == NetworkDefaults.speed_test_app_service_type {
                node.setTypes([ .chargen, .discard, .ios ])
                node.addTcpPort(NetworkDefaults.speed_test_chargen_port)
                node.addTcpPort(NetworkDefaults.speed_test_discard_port)
                node.addTcpPort(NetworkDefaults.speed_test_app_port)
            }
            
            if self.type.hasSuffix("._tcp.") {
                node.addTcpPort(UInt16(port))
            } else {
                node.addUdpPort(UInt16(port))
            }
            
            if addresses != nil {
                for data in addresses! {
                    let sock_addr = SockAddr.getSockAddr(data)
                    switch sock_addr.getFamily() {
                    case AF_INET:
                        node.addV4Address(sock_addr.getIPAddress() as! IPv4Address)
                        if let info = sock_addr.getIPAddress()!.toNumericString() { self.device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + info) }
                        SNMPManager.manager.addIpToCheck(sock_addr.getIPAddress() as! IPv4Address)
                        
                    case AF_INET6:
                        node.addV6Address(sock_addr.getIPAddress() as! IPv6Address)
                        if let info = sock_addr.getIPAddress()!.toNumericString() { self.device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + info) }
                        SNMPManager.manager.addIpToCheck(sock_addr.getIPAddress() as! IPv6Address)

                    default:
                        #fatalError("can not be here")
                    }
                }
            }
            
            // sender.domain not used ("local.")
            if !name.isEmpty {
                node.addName(name)
                self.device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + name)
            }
            if let domain = DomainName(host_name!) {
                node.addDnsName(domain)
                self.device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + name)
            }
            
            self.device_manager.addTrace("Bonjour/mDNS: service found: type:\(self.type); name:\(name); hostname:\(host_name ?? ""); sender.type:\(type); port:\(port); descr:\(description); domain:\(domain); attributes:\(text_attr)", level: .DEBUG)
            self.device_manager.addNode(node, resolve_ipv4_addresses: node.getV4Addresses())
        }
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
        searchForServices(ofType: type, inDomain: NetworkDefaults.local_domain_for_browsing)
    }
}
