//
//  TCPPortBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 03/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

let debug = false
class TCPPortBrowser {
//    private static let ports_set : Set<UInt16> = Set(1...1023).union(Set([8080, 3389, 5900, 6000]))
    private static let ports_set : Set<UInt16> = Set(1...65535)
//    private static let ports_set : Set<UInt16> = Set(22...24).union(Set([22, 30, 80]))
    private let device_manager : DeviceManager
    private var finished : Bool = false // Set by Main thread
    private var ip_to_tcp_port : [IPAddress: Set<UInt16>] = [:] // Browse thread
    private var ip_to_tcp_port_open : [IPAddress: Set<UInt16>] = [:] // Browse thread

    // Main thread
    public func stop() {
        finished = true
    }

    // userInitiated thread (Browse thread)
    public func browse() {
        // Initialize port lists to connect to
        
//        let a = IPv4Address("192.168.1.254")!
//        let a = IPv4Address("10.69.184.194")!
//        let a = IPv4Address("1.2.3.4")!
//        ip_to_tcp_port[a] = TCPPortBrowser.ports_set
        DispatchQueue.main.sync {
            for node in DBMaster.shared.nodes {
                if let addr = node.v4_addresses.first {
                    ip_to_tcp_port[addr] = TCPPortBrowser.ports_set.subtracting(node.tcp_ports)
                } else if let addr = node.v6_addresses.first {
                    ip_to_tcp_port[addr] = TCPPortBrowser.ports_set.subtracting(node.tcp_ports)
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
                var ports = self.ip_to_tcp_port[addr]!

                for delay : Int32 in [ 1000, 5000, 20000 /* , 800000 */ ] {
                    if self.finished { break }
                    
                    if delay > 1000 { ports.formIntersection(Set(1...1023)) }

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
                        
                        ret = addr.toSockAddress(port: port)!.sockaddr.withUnsafeBytes { (sockaddr : UnsafePointer<sockaddr>) in
                            connect(s, sockaddr, addr.getFamily() == AF_INET ? UInt32(MemoryLayout<sockaddr_in>.size) : UInt32(MemoryLayout<sockaddr_in6>.size))
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
                                    if debug { var d1 = 1000000 * (NSDate().timeIntervalSince1970 - t1); d1.round(.down); print(addr.toNumericString()!, "duration select", d1) }
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
        
        DispatchQueue.main.sync { device_manager.setInformation("") }
    }

    // Browse a set of networks
    // Main thread
    public init(device_manager: DeviceManager) {
        self.device_manager = device_manager
    }
}
