//
//  SNMPManager.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 08/05/2025.
//  Copyright © 2025 Alexandre Fenyo. All rights reserved.
//

import Foundation
import iOSToolsMacros

enum SNMPManagerError: Error {
    case notAvailable
    case invalidRange
}

fileprivate enum SNMPManagerState: Int {
    case available = 0
    case walking
    // Finished state when data pulled by the manager have not been retrieved from it
    case walk_finished
    case pull_finished
}

class SNMPTarget: ObservableObject {
    typealias SNMPv1v2cCredentials = String

    class SNMPv3Credentials: ObservableObject {
        @Published var username: String = ""

        enum AuthProto {
            case MD5(String)
            case SHA1(String)
        }

        enum PrivacyProto {
            case DES(String)
            case AES(String)
        }

        enum SecurityLevel {
            case noAuthNoPriv
            case authNoPriv(AuthProto)
            case authPriv(AuthProto, PrivacyProto)
        }
        @Published var security_level: SecurityLevel = .noAuthNoPriv
    }

    @Published var host: String = ""
    @Published var port: String = ""

    enum IPProto {
        case TCP
        case UDP
    }
    @Published var ip_proto: IPProto = .TCP
    
    enum IPVersion {
        case IPv4
        case IPv6
    }
    @Published var ip_version: IPVersion = .IPv4
    
    enum Credentials {
        case v1(SNMPv1v2cCredentials)
        case v2c(SNMPv1v2cCredentials)
        case v3(SNMPv3Credentials)
    }
    @Published var credentials: Credentials = .v2c("public")
}

@MainActor
class SNMPManager {
    static let manager = SNMPManager()

    private var current_selected_IP: IPAddress?
    
    private var state: SNMPManagerState = .available
    private var is_option_output_X_called = false

    /*
    func getWalkCommandeLine(host: String) -> [String] {
        var str_array = [ "snmpwalk" ]
        
        // Call '-OX' only once since it is an option that is toggled in net-snmp.
        if is_option_output_X_called == false {
            str_array.append("-OX");
            is_option_output_X_called = true;
        }
        str_array.append(contentsOf: [ "-v2c", "-c", "public", host/*, "IF-MIB::ifInOctets"*/ ]);

        return str_array;
    }
     */
    
    func setCurrentSelectedIP(_ ip: IPAddress?) {
        current_selected_IP = ip
    }

    func getCurrentSelectedIP() -> IPAddress? {
        return current_selected_IP
    }

    func getWalkCommandeLineFromTarget(target: SNMPTarget) -> [String] {
        var str_array = ["snmpwalk"]

        // Call '-OX' only once since it is an option that is toggled in net-snmp.
        if is_option_output_X_called == false {
            str_array.append("-OX");
            is_option_output_X_called = true;
        }
//        str_array.append(contentsOf: [ "-v2c", "-c", "public", target.host/*, "IF-MIB::ifInOctets"*/ ]);

        switch target.credentials {
        case .v1(let community):
            str_array.append(contentsOf: ["-v1", "-c", community])
        case .v2c(let community):
            str_array.append(contentsOf: ["-v2c", "-c", community])
        case .v3(let v3cred):
            str_array.append(contentsOf: ["-u", v3cred.username])
            switch v3cred.security_level {
            case .noAuthNoPriv:
                str_array.append(contentsOf: ["-v3", "-l", "noAuthNoPriv"])
            case .authNoPriv(let auth_proto):
                switch auth_proto {
                case .MD5(let str):
                    str_array.append(contentsOf: ["-v3", "-l", "authNoPriv", "-a", "MD5", "-A", str])
                case .SHA1(let str):
                    str_array.append(contentsOf: ["-v3", "-l", "authNoPriv", "-a", "SHA1", "-A", str])
                }
            case .authPriv(let auth_proto, let priv_proto):
                switch auth_proto {
                case .MD5(let str):
                    str_array.append(contentsOf: ["-v3", "-l", "authPriv", "-a", "MD5", "-A", str])
                case .SHA1(let str):
                    str_array.append(contentsOf: ["-v3", "-l", "authPriv", "-a", "SHA1", "-A", str])
                }
                switch priv_proto {
                case .DES(let str):
                    str_array.append(contentsOf: ["-x", "DES", "-X", str])
                case .AES(let str):
                    str_array.append(contentsOf: ["-x", "AES", "-X", str])
                }
            }
        }
        
        var agent_string = target.ip_proto == .UDP ? "udp" : "tcp"

        if target.ip_version == .IPv6 {
            agent_string.append("6")
        }
        
        agent_string.append(":")
        agent_string.append(target.host)
        agent_string.append(":")
        agent_string.append(String(target.port == "" ? "161" : target.port))

        str_array.append(contentsOf: [agent_string]);

        print("XXXXX: \(str_array)")
        
        return str_array;
    }

    func initLibSNMP() {
        // Initialize net-snmp library

        // $HOME=/var/mobile/Containers/Data/Application/<UUID_de_l_application>
        // contient :
        // - Documents : accessibles via l'app Fichiers
        // - Library : pour l'app, en lecture/écriture
        
        // homedir: /private/var/mobile/Containers/Data/Application/A9640F58-D593-402A-A647-8830A667096E
        let homedir = ProcessInfo.processInfo.environment["HOME"]!

        // bundledir: /private/var/containers/Bundle/Application/DB28E2B7-DA7C-4BA1-9871-13CB22577CAB/iOS tools.app
        let bundledir = Bundle.main.path(forResource: "BRIDGE-MIB", ofType: "txt")!.replacingOccurrences(of: "/BRIDGE-MIB.txt", with: "")
        
        // documentsurl: $HOME/Documents
        if let documentsurl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            // snmpurl: $HOME/Documents/snmp
            let snmpurl = documentsurl.appendingPathComponent("snmp")
            // Créer le répertoire $HOME/Documents/snmp
            try? FileManager.default.createDirectory(at: snmpurl, withIntermediateDirectories: true, attributes: nil)
            // Créer le fichier $HOME/Documents/snmp/snmp.conf
            let snmpconfurl = snmpurl.appendingPathComponent("snmp.conf")
            let content = "mibdirs \"\(bundledir)\"\n"
            try? content.write(to: snmpconfurl, atomically: true, encoding: .utf8)
         }

        // Créer un lien symbolique nommé snmp.txt et pointant vers snmp.conf, pour pouvoir facilement voir le contenu depuis l'IHM d'un iPhone/iPad
        try? FileManager.default.linkItem(at: URL(fileURLWithPath: "\(homedir)/Documents/snmp/snmp.conf"), to: URL(fileURLWithPath: "\(homedir)/Documents/snmp/snmp.txt"))

        let str = "\(homedir)/Documents/snmp"
        if let pointer = GenericTools.stringToUnsafeMutablePointer(str) {
            alex_setsnmpconfpath(pointer)
            pointer.deallocate()
        }

        let str2 = bundledir
        if let pointer = GenericTools.stringToUnsafeMutablePointer(str2) {
            alex_setsnmpmibdir(pointer)
            pointer.deallocate()
        }
    }
    
    private func setState(_ state: SNMPManagerState) {
        self.state = state
    }

    private func getState() -> SNMPManagerState {
        if state == .walk_finished && alex_rollingbuf_isempty() == 1 {
            state = .pull_finished
        }
        return state
    }

    // Must be in sync with alex_walk.c
    let ALEX_AV_TAB_LEN = 32
    let ALEX_AV_STR_LEN = 1024
    let ALEX_ERRBUF_LEN = 4096
    let ALEX_TRANSLATE_IN_LEN = 1024
    let ALEX_TRANSLATE_OUT_LEN = 8192

    func pushArray(_ str_array: [String]) throws(SNMPManagerError) {
        if str_array.count > ALEX_AV_TAB_LEN {
            #fatalError("pushArray: str_array.count too large")
            throw SNMPManagerError.invalidRange
        }
        alex_set_av_count(0);
        for i in 0..<str_array.count {
            if str_array[i].count > ALEX_AV_STR_LEN - 1 {
                #fatalError("pushArray: string length too large")
                throw SNMPManagerError.invalidRange
            }
            if let pointer = GenericTools.stringToUnsafeMutablePointer(str_array[i]) {
                alex_setsnmpconfpath(pointer)
                alex_set_av(Int32(i), pointer)
                pointer.deallocate()
            } else {
                #fatalError("pushArray: can not push argument")
            }
        }
        alex_set_av_count(Int32(str_array.count));
    }
    
    func translate(_ str: String) throws(SNMPManagerError) -> String {
        if state != .available {
            throw SNMPManagerError.notAvailable
        }

        if let pointer = GenericTools.stringToUnsafeMutablePointer("IF-MIB::ifNumber") {
            alex_translate(pointer)
            pointer.deallocate()
        } else {
            #fatalError("alex_translate")
            return ""
        }

        let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: ALEX_TRANSLATE_OUT_LEN)
        alex_get_translation(pointer)
        let translation = String(cString: pointer)
        pointer.deallocate()
        return translation
    }
    
    func walk(onEnd: @escaping (OIDNode, String) -> Void) throws(SNMPManagerError) {
        if state != .available {
            throw SNMPManagerError.notAvailable
        }
        state = .walking
        alex_rollingbuf_init();

        // Launch a background thread that runs snmpwalk
        Task.detached {
            alex_errbuf_clear()
            alex_walk()
            await self.setState(.walk_finished)
        }

        // Launch a background thread that continuously pulls the results from the static length buffer used by alex_walk()
        Task.detached {
            let oid_root = OIDNode(type: .root, val: "")
            while await self.getState() != .pull_finished {
                let len = Int(alex_rollingbuf_poplength())
                if len == -1 {
                    // No value to pull, we wait 0.2 sec for the alex_walk() thread to collect data
                    usleep(useconds_t(200000))
                } else {
                    let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: len + 1)
                    let ret = alex_rollingbuf_pop(pointer)
                    if ret == -1 {
                        #fatalError("walk: alex_rollingbuf_pop: \(ret)")
                    } else {
                        oid_root.mergeSingleOID(OIDNode.parse(String(cString: pointer)))
                    }
                    pointer.deallocate()
                }
            }
            await MainActor.run {
                let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: self.ALEX_ERRBUF_LEN + 1)
                alex_errbuf_get(pointer)
                let errbuf = String(cString: pointer)
                pointer.deallocate()
                onEnd(oid_root, errbuf)
            }
            await self.setState(.available)
        }
    }
}
