//
//  TCPPortBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 03/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import iOSToolsMacros

// en mode debug, le grand nombre de logs fait qu'on croit que ça ne s'arrête pas quand on fait stop, c'est simplement le buffer de logs qui est devenu énorme et qui ne se vide pas assez vite, on a donc des logs anciens qui continuent à défiler
let debug = false

// CONTINUER comme ceci : supprimer tous les appels à une Queue
// puis faire mettre à jour la liste des ports dans SwiftUI à la création d'un nouveau port

actor TCPPortBrowserData {
    private var finished: Bool = false
    private var ip_to_tcp_port: [IPAddress : Set<UInt16>] = [:]
    private var ip_to_tcp_port_open: [IPAddress : Set<UInt16>] = [:]

    func setIpToTcpPort(address: IPAddress, port_set: Set<UInt16>) {
        ip_to_tcp_port[address] = port_set
    }

    func substractPorts(address: IPAddress, port_set: Set<UInt16>) {
        ip_to_tcp_port[address] = TCPPortBrowser.ports_set.subtracting(port_set)
    }

    func getAddresses() -> Set<IPAddress> {
        var addresses = Set<IPAddress>()
        for addr in ip_to_tcp_port.keys {
            addresses.insert(addr)
        }
        return addresses
    }

    func getIPToTcpPorts(address: IPAddress) -> Set<UInt16> {
        guard let ports = ip_to_tcp_port[address] else {
            return Set<UInt16>()
        }
        return ports
    }

    func addOpenPort(address: IPAddress, port: UInt16) {
        if ip_to_tcp_port_open.keys.contains(address) == false {
            ip_to_tcp_port_open[address] = Set<UInt16>()
        }
        ip_to_tcp_port_open[address]!.insert(port)
    }
    
    func isFinished() -> Bool {
        return finished
    }

    func setFinished(_ finished: Bool) {
        self.finished = finished
    }
}

class TCPPortBrowser {
    //    private static let ports_set : Set<UInt16> = Set(1...1023).union(Set([8080, 3389, 5900, 6000]))
    // liste des ports à scanner lors d'un browse du réseau complet
    fileprivate static let ports_set: Set<UInt16> = Set(1...65535)
    //    private static let ports_set : Set<UInt16> = Set(8020...8022)
    
    // liste des ports à scanner lors d'un browse d'une IP spécifique
    fileprivate static let ports_set_one_host: Set<UInt16> = Set(1...65535)
    //    private static let ports_set_one_host : Set<UInt16> = Set(8020...8022)
    
    //    private static let ports_set : Set<UInt16> = Set(22...24).union(Set([22, 30, 80]))
    private let device_manager: DeviceManager

    private let private_data_actor = TCPPortBrowserData()
    
//    private var finished: Bool = false // Set by Main thread
    // CONTINUER ICI : supprimer les deux var suivantes pour utiliser private_data_actor
//    private var ip_to_tcp_port: [IPAddress : Set<UInt16>] = [:] // Browse thread
//    private var ip_to_tcp_port_open: [IPAddress : Set<UInt16>] = [:] // Browse thread
    
    // Main thread
    func stop() async {
        await private_data_actor.setFinished(true)
    }
    
    // Any thread
    private func isFinished() async -> Bool {
        await private_data_actor.isFinished()
    }
    
    private func addPort(addr: IPAddress, port: UInt16) {
        let node = Node()
        if addr.getFamily() == AF_INET { node.addV4Address(addr as! IPv4Address) }
        else { node.addV6Address(addr as! IPv6Address) }
        node.addTcpPort(port)
        switch port {
        case 9:
            node.addType(.discard)
        case 19:
            node.addType(.chargen)
        case 4:
            node.addType(.ios)
        default:
            ()
        }
        Task {
            await self.device_manager.setInformation(addr.toNumericString()! + ": port " + String(port))
            await self.device_manager.addNode(node)
        }
    }
    
    // Appelé depuis Task, donc (background) nonisolated context
    func browseAsync(address: IPAddress? = nil, doAtEnd: @escaping () async -> Void = {}) async {
        if let address = address {
            await private_data_actor.setIpToTcpPort(address: address, port_set: TCPPortBrowser.ports_set_one_host)
        } else {
            // Do not scan already discovered ports
            for (addr, ports) in await DBMaster.getIPsAndPorts() {
                await private_data_actor.substractPorts(address: addr, port_set: ports)
            }
        }
        
        await MainActor.run {
            device_manager.setInformation(NSLocalizedString("browsing TCP ports", comment: "browsing TCP ports"))
        }
        
        await withTaskGroup(of: Void.self) { group in
            for addr in await self.private_data_actor.getAddresses() {
                if debug { print(addr.toNumericString()!, "tcp - starting address") }
                
                await MainActor.run {
                    self.device_manager.addTrace("TCP ports browsing: \(addr.toNumericString()!)", level: .INFO)
                    // Add link
                    DBMaster.shared.notifyScanPorts(address: addr)
                }
                
                group.addTask {
//                    let _ports = self.ip_to_tcp_port[addr]!
                    let _ports = await self.private_data_actor.getIPToTcpPorts(address: addr)
                    
                    // delay: microseconds
                    for delay : Int32 in [ 100000, 20000,  10000 /*, 40000*/ ] {
                        if await self.isFinished() { break }
                        
                        var ports = _ports
                        
                        // Internet, limited port range
                        // delay == 100000 => 3 sec (0.1 * 30)
                        if delay == 100000 { ports.formIntersection(ReducedStandardTCPPorts) }
                        
                        // local network, standard port range
                        // delay == 20000 => 104 sec (0.02 * 5200)
                        if delay == 20000 { ports.formIntersection(StandardTCPPorts) }
                        
                        // local network, standard port range 2nd try
                        // delay == 10000 => 52 sec (0.01 * 5200)
                        if delay == 10000 { ports.formIntersection(StandardTCPPorts) }
                        
                        let ports_count = ports.count
                        await MainActor.run {
                            self.device_manager.addTrace("TCP ports browsing: \(addr.toNumericString()!): will scan \(ports_count) ports waiting \(delay) µs for each", level: .INFO)
                        }
                        
                        // WiFi donc latence élevée donc impossible de parcourir tous les ports sans paralléliser le traitement, même pour une IP => à reprogrammer dans le futur
                        // Internet, full port range
                        // delay == 40000 => 52 sec (0.04 * 65535)
                        // if delay == 40000 { ports.formIntersection(StandardTCPPorts) }
                        
                        for port in await self.private_data_actor.getIPToTcpPorts(address: addr).sorted() {
                            if await self.isFinished() { break }
                            if ports.contains(port) == false { continue }
                            
                            let s = socket(addr.getFamily(), SOCK_STREAM, getprotobyname("tcp").pointee.p_proto)
                            if s < 0 {
                                GenericTools.perror("socket")
                                #fatalError("browse: socket")
                                return
                            }
                            if debug { print(addr.toNumericString()!, "socket fd:", s) }
                            
                            var ret : Int32;
                            ret = fcntl(s, F_GETFL)
                            ret = fcntl(s, F_SETFL, O_NONBLOCK)
                            if (ret < 0) {
                                GenericTools.perror("fcntl")
                                close(s)
                                #fatalError("browse: fcntl")
                                return
                            }
                            
                            /* TROP consommateur de CPU, ça ralentit tout le processus
                             DispatchQueue.main.async {
                             self.device_manager.addTrace("TCP ports browsing: \(addr.toNumericString()!): trying port \(port) for \(delay)ms", level: .ALL)
                             }*/
                            
                            if debug { print(addr.toNumericString()!, ": trying port", port, "for", delay, "microseconds") }
                            let t0 = NSDate().timeIntervalSince1970
                            
                            ret = addr.toSockAddress(port: port)!.getData().withUnsafeBytes {
                                connect(s, $0.bindMemory(to: sockaddr.self).baseAddress, addr.getFamily() == AF_INET ? UInt32(MemoryLayout<sockaddr_in>.size) : UInt32(MemoryLayout<sockaddr_in6>.size))
                            }
                            if debug { var d0 = 1000000 * (NSDate().timeIntervalSince1970 - t0); d0.round(.down); print(addr.toNumericString()!, "duration connect", d0) }
                            
                            if (ret < 0) {
                                // connect(): error
                                if errno != EINPROGRESS {
                                    perror(addr.toNumericString()! + " connect")
                                    if debug { print(addr.toNumericString()!, "ERREUR connect port", port) }
                                    // do not retry this port
                                    ports.remove(port)
                                } else {
                                    // EINPROGRESS
                                    var need_retry = false
                                    repeat {
                                        if await self.isFinished() { break }
                                        
                                        let t1 = NSDate().timeIntervalSince1970
                                        // https://cr.yp.to/docs/connect.html
                                        var read_fds: fd_set = getfds(s)
                                        var write_fds: fd_set = getfds(s)
                                        var except_fds: fd_set = getfds(s)
                                        var tv = timeval(tv_sec: 0, tv_usec: delay)
                                        
                                        ret = select(s + 1, &read_fds, &write_fds, &except_fds, &tv)
                                        if debug {
                                            var d1 = 1000000 * (NSDate().timeIntervalSince1970 - t1); d1.round(.down)
                                            print(addr.toNumericString()!, "duration select", d1)
                                        }
                                        if ret > 0 {
                                            // socket is in FDS
                                            var so_error: Int32 = 0
                                            var len: socklen_t = 4
                                            ret = getsockopt(s, SOL_SOCKET, SO_ERROR, &so_error, &len)
                                            if ret < 0 {
                                                // can not get socket status
                                                if debug {
                                                    perror(addr.toNumericString()! + "getsockopt")
                                                    print(addr.toNumericString()!, "ERREUR getsockopt", "port", port)
                                                }
                                                // do not retry this port
                                                ports.remove(port)
                                            } else {
                                                // socket status returned
                                                switch so_error {
                                                case 0:
                                                    var saddr = sockaddr()
                                                    var slen = UInt32(MemoryLayout<sockaddr>.size)
                                                    let rr = getpeername(s, &saddr, &slen)
                                                    if rr < 0 {
                                                        if errno == ENOTCONN {
                                                            print(addr.toNumericString()!, "ENOTCONN")
                                                            need_retry = true
                                                        } else {
                                                            if debug { perror(addr.toNumericString()! + "getpeername") }
                                                            // do not retry this port
                                                            ports.remove(port)
                                                        }
                                                    } else {
                                                        // we got a peer name
                                                        if debug { print(addr.toNumericString()!, "getpeername PORT CONNECTED : port", port, "after", delay) }
                                                        await MainActor.run {
                                                            self.device_manager.addTrace("TCP ports browsing: \(addr.toNumericString()!):  discovered open port \(port)", level: .DEBUG)
                                                            DBMaster.shared.notifyPortDiscovered(address: addr, port: port)
                                                        }
                                                        // do not retry this port
                                                        ports.remove(port)
                                                        self.addPort(addr: addr, port: port)
                                                    }
                                                    
                                                case ECONNREFUSED:
                                                    // do not retry this port
                                                    ports.remove(port)
                                                    /* TROP consommateur de CPU, ça ralentit tout le processus
                                                     DispatchQueue.main.async {
                                                     self.device_manager.addTrace("TCP ports browsing: \(addr.toNumericString()!):  connection refused on port \(port)", level: .ALL)
                                                     }*/
                                                    if debug { print(addr.toNumericString()!, "getsockopt connection refused port", port) }
                                                    
                                                default:
                                                    if debug { print(addr.toNumericString()!, "ERREUR getsockopt other state port", port, "so_error", so_error) }
                                                }
                                            }
                                        } else {
                                            // socket in FDS
                                            if ret == 0 {
                                                // timeout reached
                                                if debug { print(addr.toNumericString()!, "select timeout reached port", port) }
                                            } else {
                                                // select error : ??? EBADF
                                                perror(addr.toNumericString()! + "select")
                                                print(addr.toNumericString()!, "ERREUR select", s, "port", port)
                                            }
                                        }
                                    } while need_retry
                                }
                                
                            } else {
                                // connect(): no error, successful completion
                                if debug { print("port found", port) }
                                
                                await self.private_data_actor.addOpenPort(address: addr, port: port)
                                // do not retry this port
                                ports.remove(port)
                                self.addPort(addr: addr, port: port)
                            }
                            close(s)
                        }
                    }
                    
                    await MainActor.run {
                        self.device_manager.addTrace("TCP ports browsing: finished with address \(addr.toNumericString()!)", level: .INFO)
                        DBMaster.shared.notifyScanPortsFinished(address: addr)
                    }
                }
                
                
            }
        }
        
        // print("TCP browse ADDRESSE: FIN")
        
        // peut etre mettre ceci dans le doAtEnd au moment où il est construit
        await MainActor.run {
            device_manager.addTrace("TCP ports browsing: finished", level: .INFO)
            device_manager.setInformation("")
        }
        
        await doAtEnd()
    }
    
    // Browse a set of networks
    // Main thread
    init(device_manager: DeviceManager) {
        self.device_manager = device_manager
    }
}
