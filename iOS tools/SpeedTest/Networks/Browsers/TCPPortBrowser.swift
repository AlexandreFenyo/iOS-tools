//
//  TCPPortBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 03/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class TCPPortBrowser {
    private static let ports_set : Set<UInt16> = Set(1...1023).union(Set([8080, 3389, 5900, 6000]))
//    private static let ports_set : Set<UInt16> = Set(22...24).union(Set([22]))
    private let device_manager : DeviceManager
    private var finished : Bool = false // Main thread
    private var ip_to_tcp_port : [IPAddress: Set<UInt16>] = [:]
    private var ip_to_tcp_port_open : [IPAddress: Set<UInt16>] = [:] // Main thread

    // Main thread
    public func stop() {
        finished = true
    }

    // Main thread
    public func browse() {
        // Initialize port lists to connect to
        
        let a = IPv4Address("192.168.1.254")!
//        let a = IPv4Address("1.2.3.4")!
        ip_to_tcp_port[a] = TCPPortBrowser.ports_set
//        for node in DBMaster.shared.nodes {
//            if let addr = node.v4_addresses.first {
//                ip_to_tcp_port[addr] = TCPPortBrowser.ports_set.subtracting(node.tcp_ports)
//            } else if let addr = node.v6_addresses.first {
//                ip_to_tcp_port[addr] = TCPPortBrowser.ports_set.subtracting(node.tcp_ports)
//            }
//        }

        let dispatchGroup = DispatchGroup()

        device_manager.setInformation("browsing TCP ports")

        for addr in self.ip_to_tcp_port.keys {
            dispatchGroup.enter()
            
            self.ip_to_tcp_port_open[addr] = Set<UInt16>()
            
            DispatchQueue.global(qos: .userInitiated).async {
                for delay : Int32 in [ 4000 /*, 4000, 20000, 60000, 400000 */ ] {
                    var ports = self.ip_to_tcp_port[addr]!

                    for port in self.ip_to_tcp_port[addr]! {
                        if ports.contains(port) == false { continue }

                        let s = socket(addr.getFamily(), SOCK_STREAM, getprotobyname("tcp").pointee.p_proto)
                        if s < 0 {
                            GenericTools.perror("socket")
                            fatalError("browse: socket")
                        }
                        
                        var ret = fcntl(s, F_SETFL, O_NONBLOCK)
                        if (ret < 0) {
                            GenericTools.perror("fcntl")
                            close(s)
                            fatalError("browse: fcntl")
                        }
                        
                        
                        ret = addr.toSockAddress(port: port)!.sockaddr.withUnsafeBytes { (sockaddr : UnsafePointer<sockaddr>) in
                            connect(s, sockaddr, addr.getFamily() == AF_INET ? UInt32(MemoryLayout<sockaddr_in>.size) : UInt32(MemoryLayout<sockaddr_in6>.size))
                        }
                        
                        if (ret < 0) {
                            // connect(): error
                            if errno != EINPROGRESS {
                                perror("connect")
                                print("ERREUR connect", addr.toNumericString(), "port", port)
                                // do not retry this port
                                ports.remove(port)
                            } else {
                                // EINPROGRESS
                                
                                var need_repeat = false
                                repeat {
                                    
                                    need_repeat = false
                                    

// https://cr.yp.to/docs/connect.html
                                    var fds : fd_set = getfds(s)
                                    var tv = timeval(tv_sec: 0, tv_usec: delay)
print("avant select")
                                    ret = select(s + 1, nil, &fds, nil, &tv)
print("apres select")
                                    if ret > 0 {
                                        // socket is in FDS
                                        
                                        var so_error : Int32 = 0
                                        var len : socklen_t = 4
                                        ret = getsockopt(s, SOL_SOCKET, SO_ERROR, &so_error, &len)
                                        if ret < 0 {
                                            // can not get socket status
                                            perror("getsockopt")
                                            print("ERREUR getsockopt", addr.toNumericString(), "port", port)
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
                                                        need_repeat = true
                                                    } else {
                                                        perror("getpeername")
                                                        // do not retry this port
                                                        ports.remove(port)
                                                    }
                                                } else {
                                                    // we got a peer name
                                                    print("getpeername PORT CONNECTED : ", addr.toNumericString(), "port", port)
                                                    // do not retry this port
                                                    ports.remove(port)
                                                }

                                            case ECONNREFUSED:
                                                // do not retry this port
                                                ports.remove(port)
                                                print("getsockopt connection refused", addr.toNumericString(), "port", port)
                                                
                                            default:
                                                print("ERREUR getsockopt other state", addr.toNumericString(), "port", port, "so_error", so_error)
                                            }
                                        }
                                    } else {
                                        // socket ein FDS
                                        if ret == 0 {
                                            // timeout reached
                                            print("select timeout reached", addr.toNumericString(), "port", port)
                                        } else {
                                            // select error : ???
                                            perror("select")
                                            print("ERREUR select", addr.toNumericString(), "port", port)
                                            
                                        }
                                    }
                                
                                    
                                }  while need_repeat
                                
                            }
                                
                        } else {
                            // connect(): no error, successful completion
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
        exit(1)
        
        device_manager.setInformation("")
    }

    // Browse a set of networks
    // Main thread
    public init(device_manager: DeviceManager) {
        self.device_manager = device_manager
    }
}
