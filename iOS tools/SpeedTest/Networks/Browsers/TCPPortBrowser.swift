//
//  TCPPortBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 03/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class TCPPortBrowser {
//    private static let ports_set : Set<UInt16> = Set(1...1023).union(Set([8080, 3389, 5900, 6000]))
    private static let ports_set : Set<UInt16> = Set(20...80).union(Set([8080, 3389, 5900, 6000]))
    private let device_manager : DeviceManager
    private var finished : Bool = false // Main thread
    private var ip_to_tcp_port : [IPAddress: Set<UInt16>] = [:]

    // Main thread
    public func stop() {
        finished = true
    }

    // Main thread
    public func browse() {
        // Initialize port lists to connect to
        
        let a = IPv4Address("10.69.127.250")!
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
            var tv = timeval(tv_sec: 0, tv_usec: 900000)
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                for port in self.ip_to_tcp_port[addr]! {
                    let s = socket(addr.getFamily(), SOCK_STREAM, getprotobyname("tcp").pointee.p_proto)
                    if s < 0 {
                        GenericTools.perror("socket")
                        fatalError("browse: socket")
                    }

                    var ret = fcntl(s, F_SETFL, O_NONBLOCK)
                    if (ret < 0) {
                        GenericTools.perror("fcntl")
                        fatalError("browse: fcntl")
                    }

                    ret = addr.toSockAddress(port: port)!.sockaddr.withUnsafeBytes { (sockaddr : UnsafePointer<sockaddr>) in
                        connect(s, sockaddr, addr.getFamily() == AF_INET ? UInt32(MemoryLayout<sockaddr_in>.size) : UInt32(MemoryLayout<sockaddr_in6>.size))
                    }
                    if (ret < 0 && errno != EINPROGRESS) {
                        perror("connect")
                        print("connect", addr.toNumericString(), "port", port)
                    } else {
                        var fds : fd_set = getfds(s)
                        ret = select(s + 1, nil, &fds, nil, &tv)
                        if ret > 0 {
                            var so_error : Int32 = 0
                            var len : socklen_t = 4
                            ret = getsockopt(s, SOL_SOCKET, SO_ERROR, &so_error, &len)
                            if ret < 0 {
                                perror("getsockopt")
                                print("getsockopt", addr.toNumericString(), "port", port)
                            } else {
                                switch so_error {
                                case 0:
                                    print("getsockopt port open", addr.toNumericString(), "port", port)
                                    
                                case ECONNREFUSED:
                                    print("getsockopt connection refused", addr.toNumericString(), "port", port)
                                    
                                default:
                                    print("getsockopt other state", addr.toNumericString(), "port", port, "so_error", so_error)
                                }
                            }
                        } else {
                            if ret == 0 {
                                print("select timeout reached", addr.toNumericString(), "port", port)
                            } else {
                                perror("select")
                                print("select", addr.toNumericString(), "port", port)

                            }
                        }
                        // /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/sys/socket.h
                    }

                    close(s)
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()
        print("TCP browse ADDRESSE: FIN")
        
        device_manager.setInformation("")
    }

    // Browse a set of networks
    // Main thread
    public init(device_manager: DeviceManager) {
        self.device_manager = device_manager
    }
}
