//
//  ServiceBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 18/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import UIKit

/*
 voici la commande adéquate sur macOS :
 # dig -b '0.0.0.0#5352' @224.0.0.251 -p 5353  _services._dns-sd._udp.local. any +notcp +short
les réponses sont récupérées via un wireshark, ou il faut lancer cette commande sur MacOS

 les IP multicast :
 224.0.0.251
 ff02::fb

 liste des services Bonjour : https://jonathanmumm.com/tech-it/mdns-bonjour-bible-common-service-strings-for-various-vendors/
 <string>_services._dns-sd._udp</string>

 <string>_invoke._sub._bp2p._tcp</string>
 <string>_webdav._sub._bp2p._tcp</string>
 <string>_print._sub._ipp._tcp</string>
 <string>_cups._sub._ipps._tcp</string>
 <string>_print._sub._ipps._tcp</string>
 <string>_printer._sub._http._tcp</string>
 <string>_Friendly._sub._bp2p._tcp</string>

 <string>_adisk._tcp</string>
 <string>_airplay._tcp</string>
 <string>_airport._tcp</string>
 <string>_atc._tcp</string>
 <string>_companion-link._tcp</string>
 <string>_dhnap._tcp</string>
 <string>_ewelink._tcp</string>
 <string>_googlecast._tcp</string>
 <string>_googlezone._tcp</string>
 <string>_hap._tcp</string>
 <string>_homekit._tcp</string>
 <string>_http._tcp</string>
 <string>_hue._tcp</string>
 <string>_ipp._tcp</string>
 <string>_ipps._tcp</string>
 <string>_mediaremotetv._tcp</string>
 <string>_meshcop._udp</string>
 <string>_pdl-datastream._tcp</string>
 <string>_pgpkey-hkp._tcp</string>
 <string>_raop._tcp</string>
 <string>_rdlink._tcp</string>
 <string>_rfb._tcp</string>
 <string>_sane-port._tcp</string>
 <string>_scanner._tcp</string>
 <string>_sengled._udp</string>
 <string>_sftp-ssh._tcp</string>
 <string>_sleep-proxy._udp</string>
 <string>_smb._tcp</string>
 <string>_spotify-connect._tcp</string>
 <string>_ssh._tcp</string>
 <string>_touch-able._tcp</string>
 <string>_viziocast._tcp</string>
 <string>_workstation._tcp</string>
 <string>_adisk._tcp</string>
 <string>_afpovertcp._tcp</string>
 <string>_airdroid._tcp</string>
 <string>_airdrop._tcp</string>
 <string>_airplay._tcp</string>
 <string>_airport._tcp</string>
 <string>_amzn-wplay._tcp</string>
 <string>_apple-mobdev2._tcp</string>
 <string>_apple-sasl._tcp</string>
 <string>_appletv-v2._tcp</string>
 <string>_atc._tcp</string>
 <string>_sketchmirror._tcp</string>
 <string>_bcbonjour._tcp</string>
 <string>_bp2p._tcp</string>
 <string>_companion-link._tcp</string>
 <string>_cloud._tcp</string>
 <string>_daap._tcp</string>
 <string>_device-info._tcp</string>
 <string>_distcc._tcp</string>
 <string>_dpap._tcp</string>
 <string>_eppc._tcp</string>
 <string>_esdevice._tcp</string>
 <string>_esfileshare._tcp</string>
 <string>_ftp._tcp</string>
 <string>_googlecast._tcp</string>
 <string>_googlezone._tcp</string>
 <string>_hap._tcp</string>
 <string>_homekit._tcp</string>
 <string>_home-sharing._tcp</string>
 <string>_http._tcp</string>
 <string>_hudson._tcp</string>
 <string>_ica-networking._tcp</string>
 <string>_ichat._tcp</string>
 <string>_jenkins._tcp</string>
 <string>_KeynoteControl._tcp</string>
 <string>_keynotepair._tcp</string>
 <string>_mediaremotetv._tcp</string>
 <string>_nfs._tcp</string>
 <string>_nvstream._tcp</string>
 <string>_androidtvremote._tcp</string>
 <string>_omnistate._tcp</string>
 <string>_pdl-datastream._tcp</string>
 <string>_photoshopserver._tcp</string>
 <string>_printer._tcp</string>
 <string>_raop._tcp</string>
 <string>_readynas._tcp</string>
 <string>_rfb._tcp</string>
 <string>_physicalweb._tcp</string>
 <string>_riousbprint._tcp</string>
 <string>_rsp._tcp</string>
 <string>_scanner._tcp</string>
 <string>_servermgr._tcp</string>
 <string>_sftp-ssh._tcp</string>
 <string>_sleep-proxy._udp</string>
 <string>_smb._tcp</string>
 <string>_spotify-connect._tcp</string>
 <string>_ssh._tcp</string>
 <string>_teamviewer._tcp</string>
 <string>_telnet._tcp</string>
 <string>_touch-able._tcp</string>
 <string>_tunnel._tcp</string>
 <string>_udisks-ssh._tcp</string>
 <string>_webdav._tcp</string>
 <string>_workstation._tcp</string>
 <string>_xserveraid._tcp</string>
 */

class BrowserDelegate : NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    private var services: [ NetService ] = []
    private let type: String
    private let device_manager : DeviceManager

    init(_ type: String, deviceManager: DeviceManager) {
        self.type = type
        device_manager = deviceManager
    }

    private static func bytesToString(_ data: Data) -> String {
        var retval = ""
        for val in data { retval += String(UnicodeScalar(val)) }
        return retval
    }

    private func decodeTxt(_ data: Data) -> [ String: String ] {
        print("")
        print("DECODETXT size=\(data.count) content=\(Self.bytesToString(data))")
        print("FIRST BYTE OF DATA: \(data.first)")
        
        if let _size = data.first {
            let size = Int(_size)
            print("première taille: \(size)")
            if size == 0 {
                print("\(#function) error: invalid null size")
                return [:]
            }
            // from here, data.indices.first is not nil
            
            if data.count <= size {
                print("\(#function) error: not enough data")
                return [:]
            }
            
            let key_val = data.subdata(in: data.indices.first!.advanced(by: 1)..<data.indices.first!.advanced(by: size + 1))
            print("key_val.count=\(key_val.count)")
            
            if let marker = key_val.firstIndex(of: ("=" as Character).asciiValue!) {
                // from here, key_val.indices.first is not nil
                
                print("key_val.ind.first=\(key_val.indices.first!) key_val[0]=\(key_val.first!)")
                
                if marker == key_val.indices.first! {
                    print("\(#function) error: empty key")
                    return decodeTxt(data.suffix(from: data.indices.first!.advanced(by: size + 1)))
                }
                let key = key_val.subdata(in: key_val.indices.first!..<marker)
                let key_str = Self.bytesToString(key)
                print("key=\(key_str)")
                
                print("marker=\(marker)")
                let val = key_val.suffix(from: marker.advanced(by: 1))
                print("val.count=\(val.count)")
                let val_str = Self.bytesToString(val)
                print("val=\(val_str)")

                var dict = size + 1 < data.count ? decodeTxt(data.suffix(from: data.indices.first!.advanced(by: size + 1))) : [:]
                print("\(#function): adding \(key_str) = \(val_str)")
                dict[key_str] = val_str
                return dict
            } else {
                print("\(#function) error: bad format (no =)")
                return decodeTxt(data.suffix(from: data.indices.first!.advanced(by: size + 1)))
            }
        }
        print("\(#function)error: empty data")
        return [:]
    }

    // MARK: - NetServiceBrowserDelegate

    // Remote service app discovered
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print(#function)
        print("service.name = \(service.name)")
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
    }

    // May have found some addresses for the service
    public func netServiceDidResolveAddress(_ sender: NetService) {
        print(#function)
        // print("netServiceDidResolveAddress: name:", sender.name, "port:", sender.port)
        // From the documentation: "It is possible for a single service to resolve to more than one address or not resolve to any addresses."

        if type != NetworkDefaults.speed_test_app_service_type {
            if let data = sender.txtRecordData() {
                decodeTxt(data)
            }
            print("TYPE = type:\(type) name:\(sender.name) hostname:\(sender.hostName) sender.type:\(sender.type) port:\(sender.port) descr:\(sender.description) debug:\(sender.debugDescription) domain:\(sender.domain) txt:\(sender.txtRecordData())")

            
            
            if let txt = sender.txtRecordData() {
                var s = ""
                for b in txt {
                    s = s + String(UnicodeScalar(b))
                }
                print("<<<< " + s + " >>>>")
            }
            for data in sender.addresses! {
                print(data.description)
            }
            return
        }
        
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
