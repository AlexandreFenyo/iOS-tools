//
//  TCPPortBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 03/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

let debug = true
class TCPPortBrowser {
//    private static let ports_set : Set<UInt16> = Set(1...1023).union(Set([8080, 3389, 5900, 6000]))
    // liste des ports à scanner lors d'un browse du réseau complet
    private static let ports_set : Set<UInt16> = Set(1...65535)
//    private static let ports_set : Set<UInt16> = Set(8020...8022)

    // liste des ports à scanner lors d'un browse d'une IP spécifique
    private static let ports_set_one_host : Set<UInt16> = Set(1...65535)
//    private static let ports_set_one_host : Set<UInt16> = Set(8020...8022)

    //    private static let ports_set : Set<UInt16> = Set(22...24).union(Set([22, 30, 80]))
    private let device_manager : DeviceManager
    private var finished : Bool = false // Set by Main thread
    private var ip_to_tcp_port : [IPAddress: Set<UInt16>] = [:] // Browse thread
    private var ip_to_tcp_port_open : [IPAddress: Set<UInt16>] = [:] // Browse thread

    // Main thread
    public func stop() {
        finished = true
    }
    
    private func addPort(addr: IPAddress, port: UInt16) {
        DispatchQueue.main.async {
            let node = Node()
            if addr.getFamily() == AF_INET { node.v4_addresses.insert(addr as! IPv4Address) }
            else { node.v6_addresses.insert(addr as! IPv6Address) }
            node.tcp_ports.insert(port)
            self.device_manager.setInformation(addr.toNumericString()! + ": port " + String(port))
            switch port {
            case 9:
                node.types.insert(.discard)
            case 19:
                node.types.insert(.chargen)
            case 4:
                node.types.insert(.ios)
            default:
                ()
            }
            self.device_manager.addNode(node)
        }
    }

    // userInitiated thread (Browse thread)
    public func browse(address: IPAddress? = nil, doAtEnd: @escaping () -> Void = {}) {
        // Initialize port lists to connect to
        
//        let a = IPv4Address("192.168.1.254")!
//        let a = IPv4Address("10.69.184.194")!
//        let a = IPv4Address("1.2.3.4")!
//        ip_to_tcp_port[a] = TCPPortBrowser.ports_set

        if let address = address {
            ip_to_tcp_port[address] = TCPPortBrowser.ports_set_one_host
        } else {
            // ne pas rescanner les ports déjà identifiés
            DispatchQueue.main.sync {
                for node in DBMaster.shared.nodes {
                    if let addr = node.v4_addresses.first {
                        ip_to_tcp_port[addr] = TCPPortBrowser.ports_set.subtracting(node.tcp_ports)
                    } else if let addr = node.v6_addresses.first {
                        ip_to_tcp_port[addr] = TCPPortBrowser.ports_set.subtracting(node.tcp_ports)
                    }
                }
            }
        }
        
        let dispatchGroup = DispatchGroup()
        DispatchQueue.main.sync { device_manager.setInformation("browsing TCP ports") }

        for addr in self.ip_to_tcp_port.keys {
            if debug { print(addr.toNumericString()!, "tcp - starting address") }
            dispatchGroup.enter()
            
            self.ip_to_tcp_port_open[addr] = Set<UInt16>()
            
            // Create a thread for each address
            DispatchQueue.global(qos: .userInitiated).async {
                let _ports = self.ip_to_tcp_port[addr]!

                for delay : Int32 in [ 100000, 1000, 5000, 20000, 800000 ] {
                    if self.finished { break }

                    var ports = _ports
                    
                    // à partir du 2ième essai, on ne teste plus que les ports inférieurs à 1024
                    if delay > 1000 { ports.formIntersection(Set(1...1023)) }
                    if delay == 100000 { ports.formIntersection(Set(1...23)) }

                    for port in self.ip_to_tcp_port[addr]!.sorted() {
                        if self.finished { break }
                        if ports.contains(port) == false { continue }
                        
                        let s = socket(addr.getFamily(), SOCK_STREAM, getprotobyname("tcp").pointee.p_proto)
                        if s < 0 {
                            GenericTools.perror("socket")
                            fatalError("browse: socket")
                        }
                        if debug { print(addr.toNumericString()!, "socket fd:", s) }
                        
                        var ret : Int32;
                        ret = fcntl(s, F_GETFL)
                        ret = fcntl(s, F_SETFL, O_NONBLOCK)
                        if (ret < 0) {
                            GenericTools.perror("fcntl")
                            close(s)
                            fatalError("browse: fcntl")
                        }
                        
                        if debug { print(addr.toNumericString()!, ": trying port", port, "for", delay, "microseconds") }
                        let t0 = NSDate().timeIntervalSince1970
                        
                        ret = addr.toSockAddress(port: port)!.getData().withUnsafeBytes {
                            connect(s, $0.bindMemory(to: sockaddr.self).baseAddress, addr.getFamily() == AF_INET ? UInt32(MemoryLayout<sockaddr_in>.size) : UInt32(MemoryLayout<sockaddr_in6>.size))
                        }
                        if debug { var d0 = 1000000 * (NSDate().timeIntervalSince1970 - t0); d0.round(.down); print(addr.toNumericString()!, "duration connect", d0) }
                        
                        if (ret < 0) {
                            // connect(): error
                            if errno != EINPROGRESS {
                                perror(addr.toNumericString()! + "connect")
                                if debug { print(addr.toNumericString()!, "ERREUR connect port", port) }
                                // do not retry this port
                                ports.remove(port)
                            } else {
                                // EINPROGRESS
                                
                                if self.finished { break }
                                
                                var need_retry = false
                                repeat {
                                    let t1 = NSDate().timeIntervalSince1970
                                    // https://cr.yp.to/docs/connect.html
                                    var read_fds : fd_set = getfds(s)
                                    var write_fds : fd_set = getfds(s)
                                    var except_fds : fd_set = getfds(s)
                                    var tv = timeval(tv_sec: 0, tv_usec: delay)
                                    
                                    ret = select(s + 1, &read_fds, &write_fds, &except_fds, &tv)
                                    if debug { var d1 = 1000000 * (NSDate().timeIntervalSince1970 - t1); d1.round(.down)
                                        print(addr.toNumericString()!, "duration select", d1)
                                    }
                                    if ret > 0 {
                                        // socket is in FDS
                                        var so_error : Int32 = 0
                                        var len : socklen_t = 4
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
                                                    print(addr.toNumericString()!, "getpeername PORT CONNECTED : port", port, "after", delay)
                                                    // do not retry this port
                                                    ports.remove(port)
                                                    self.addPort(addr: addr, port: port)
                                                }
                                                
                                            case ECONNREFUSED:
                                                // do not retry this port
                                                ports.remove(port)
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
                            print("port found", port)
                            self.ip_to_tcp_port_open[addr]!.insert(port)
                            // do not retry this port
                            ports.remove(port)
                            self.addPort(addr: addr, port: port)
                        }
                        close(s)
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()
        print("TCP browse ADDRESSE: FIN")
//        exit(1)

        // peut etre mettre ceci dans le doAtEnd au moment où il est construit
        DispatchQueue.main.sync {
            device_manager.setInformation("")
        }
 
        doAtEnd()
    }

    // Browse a set of networks
    // Main thread
    public init(device_manager: DeviceManager) {
        self.device_manager = device_manager
    }
}
