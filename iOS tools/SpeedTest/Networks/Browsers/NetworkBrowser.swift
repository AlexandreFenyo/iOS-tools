//
//  NetworkBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 27/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

// IPv4 only
// Only a single instance can work at a time, since ICMP replies are sent to any thread calling recvfrom()
class NetworkBrowser {
    private let device_manager : DeviceManager
    private let browser_tcp : TCPPortBrowser
    private var reply_ipv4 : [IPv4Address: (Int, Date?)] = [:]
    private var reply_ipv6 : [IPv6Address: (Int, Date?)] = [:]
    private var broadcast_ipv4 = Set<IPv4Address>()
    private var multicast_ipv6 = Set<IPv6Address>()
    private var finished : Bool = false // Main thread

    // Browse a set of networks
    // Main thread
    public init(networks: Set<IPNetwork>, device_manager: DeviceManager, browser_tcp: TCPPortBrowser) {
        self.device_manager = device_manager
        self.browser_tcp = browser_tcp
        for network in networks {
            if let network_addr = network.ip_address as? IPv6Address {
                if network_addr == IPv6Address("::1") { continue }
                let multicast = network_addr.and(IPv6Address("0000:ffff::")!).or((IPv6Address("ff02::1")!))
                multicast_ipv6.insert(multicast as! IPv6Address)
            }

multicast_ipv6.insert(IPv6Address("::1%en0")!)

            if let network_addr = network.ip_address as? IPv4Address {
                let netmask = IPv4Address(mask_len: network.mask_len)
                let broadcast = network_addr.or(netmask.xor(IPv4Address("255.255.255.255")!))
// A REMETTRE
                if network.mask_len < /*22*/ 200 { broadcast_ipv4.insert(broadcast as! IPv4Address) }
                else {
                    var current = network_addr.and(netmask).next() as! IPv4Address
                    repeat {
                        if (DBMaster.shared.nodes.filter { $0.v4_addresses.contains(current) }).isEmpty { reply_ipv4[current] = (NetworkDefaults.n_icmp_echo_reply, nil) }
                        current = current.next() as! IPv4Address
                    } while current != broadcast
                }
            }
        }
    }

    // Any thread
    private func getIPForTask() -> IPv4Address? {
        return DispatchQueue.main.sync {
            guard let address = reply_ipv4.filter({
                guard let last_use = $0.value.1 else { return true }
                return Date().timeIntervalSince(last_use) > 3
            }).first?.key else { return nil }
            reply_ipv4[address]!.0 -= 1
            if let info = address.toNumericString() { device_manager.setInformation((reply_ipv4[address]!.0 == NetworkDefaults.n_icmp_echo_reply - 1 ? "" : "re") + "trying " + info) }
            if reply_ipv4[address]!.0 == 0 { reply_ipv4.removeValue(forKey: address) }
            else { reply_ipv4[address]!.1 = Date() }
            return address
        }
    }

    // Any thread
    private func manageAnswer(from: IPAddress) {
        DispatchQueue.main.sync {
            let node = Node()
            switch from.getFamily() {
            case AF_INET:
                node.v4_addresses.insert(from as! IPv4Address)
                device_manager.addNode(node, resolve_ipv4_addresses: node.v4_addresses)
                if let info = from.toNumericString() {
                    device_manager.setInformation("found " + info)
                    print("manageAnswer() FOUND IPv4:" , info)
                }
                reply_ipv4.removeValue(forKey: from as! IPv4Address)

            case AF_INET6:
                node.v6_addresses.insert(from as! IPv6Address)
                device_manager.addNode(node, resolve_ipv6_addresses: node.v6_addresses)
                if let info = from.toNumericString() {
                    device_manager.setInformation("found " + info)
                    print("manageAnswer() FOUND IPv6:" , info)
                }
                reply_ipv6.removeValue(forKey: from as! IPv6Address)

            default:
                print("manageAnswer(): invalid family", from.getFamily())
            }

        }
    }
    
    // Main thread
    public func stop() {
        finished = true
    }

    // Any thread
    private func isFinishedOrEmpty() -> Bool {
        return DispatchQueue.main.sync { return finished || reply_ipv4.isEmpty }
    }

    // Any thread
    private func isFinished() -> Bool {
        return DispatchQueue.main.sync { return finished }
    }

    // Main thread
    public func browse() {
        DispatchQueue.global(qos: .userInitiated).async {
            let s = socket(PF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
            if s < 0 {
                GenericTools.perror("socket")
                fatalError("browse: socket")
            }
            
            var tv = timeval(tv_sec: 3, tv_usec: 0)
            var ret = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
            if ret < 0 {
                GenericTools.perror("setsockopt")
                fatalError("browse: setsockopt")
            }

            let s6 = socket(PF_INET6, SOCK_DGRAM, getprotobyname("icmp6").pointee.p_proto)
            if s6 < 0 {
                GenericTools.perror("socket6")
                fatalError("browse: socket6")
            }
            
            ret = setsockopt(s6, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
            if ret < 0 {
                GenericTools.perror("setsockopt")
                fatalError("browse: setsockopt")
            }

            let dispatchGroup = DispatchGroup()
            
            // Unicast ICMPv4
            dispatchGroup.enter()
            // wait .5 sec to let the recvfrom() start before sending ICMP packets
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                repeat {
                    let address = self.getIPForTask()
                    if let address = address {
                        var hdr = icmp()
                        hdr.icmp_type = UInt8(ICMP_ECHO)
                        hdr.icmp_code = 0
                        hdr.icmp_hun.ih_idseq.icd_seq = _htons(13)
                        let capacity = MemoryLayout<icmp>.size / MemoryLayout<ushort>.size
                        hdr.icmp_cksum = withUnsafePointer(to: &hdr) {
                            $0.withMemoryRebound(to: u_short.self, capacity: capacity) {
                                var sum : u_short = 0
                                for idx in 0..<capacity { sum = sum &+ $0[idx] }
                                sum ^= u_short.max
                                return sum
                            }
                        }
                        
                        let ret = withUnsafePointer(to: &hdr) { (bytes) -> Int in
                            address.toSockAddress()!.sockaddr.withUnsafeBytes { (sockaddr : UnsafePointer<sockaddr>) in
                                sendto(s, bytes, MemoryLayout<icmp>.size, 0, sockaddr, UInt32(MemoryLayout<sockaddr_in>.size))
                            }
                        }
                        if ret < 0 { GenericTools.perror("sendto") }
                    } else { sleep(1) }
                } while !self.isFinishedOrEmpty()
                
                dispatchGroup.leave()
            }

            // Multicast ICMPv4
            dispatchGroup.enter()
            // wait .5 sec to let the recvfrom() start before sending ICMP packets
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                for address in self.broadcast_ipv4 {
                    var hdr = icmp()
                    hdr.icmp_type = UInt8(ICMP_ECHO)
                    hdr.icmp_code = 0
                    hdr.icmp_hun.ih_idseq.icd_seq = _htons(13)
                    let capacity = MemoryLayout<icmp>.size / MemoryLayout<ushort>.size
                    hdr.icmp_cksum = withUnsafePointer(to: &hdr) {
                        $0.withMemoryRebound(to: u_short.self, capacity: capacity) {
                            var sum : u_short = 0
                            for idx in 0..<capacity { sum = sum &+ $0[idx] }
                            sum ^= u_short.max
                            return sum
                        }
                    }
                    
                    let ret = withUnsafePointer(to: &hdr) { (bytes) -> Int in
                        address.toSockAddress()!.sockaddr.withUnsafeBytes { (sockaddr : UnsafePointer<sockaddr>) in
                            sendto(s, bytes, MemoryLayout<icmp>.size, 0, sockaddr, UInt32(MemoryLayout<sockaddr_in>.size))
                        }
                    }
                    if ret < 0 { GenericTools.perror("sendto") }
                }
                dispatchGroup.leave()
            }

            // Multicast ICMPv6
            dispatchGroup.enter()
            // wait .5 sec to let the recvfrom() start before sending ICMP packets
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
                for address in self.multicast_ipv6 {
                    var saddr = address.toSockAddress()!.sockaddr
                    print("ipv6 address:", address.toNumericString())
                    var msg_hdr = msghdr()
                    var hdr = icmp6_hdr()
                    var iov = iovec()
                    hdr.icmp6_type = UInt8(ICMP6_ECHO_REQUEST)
                    hdr.icmp6_code = 0
                    hdr.icmp6_dataun.icmp6_un_data16.0 = 55 // icmp6_id
                    hdr.icmp6_dataun.icmp6_un_data16.1 = _ntohs(0) // icmp6_seq
                    iov.iov_len = 8
                    msg_hdr.msg_namelen = UInt32(saddr.count)
                    let retlen = saddr.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<sockaddr_in6>) -> Int in
                        msg_hdr.msg_name = UnsafeMutableRawPointer(mutating: ptr)
                        return withUnsafeMutablePointer(to: &hdr) { (ptr) -> Int in
                            iov.iov_base = UnsafeMutableRawPointer(mutating: ptr)
                            return withUnsafeMutablePointer(to: &iov) { (ptr) -> Int in
                                msg_hdr.msg_iov = ptr
                                msg_hdr.msg_iovlen = 1
                                return sendmsg(s6, &msg_hdr, 0)
                            }
                        }
                    }
                    if retlen < 0 {
                        print("IPV6 sendmsg: retval=", retlen)
                        GenericTools.perror()
                    }
                }
                dispatchGroup.leave()
            }

            // Catch IPv4 replies
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                repeat {
                    let buf_size = 10000
                    var buf = [UInt8](repeating: 0, count: buf_size)
                    var from = Data(count: MemoryLayout<sockaddr_in>.size)
                    var from_len : socklen_t = UInt32(from.count)

                    let ret = withUnsafeMutablePointer(to: &from_len) { (from_len_p) -> Int in
                        from.withUnsafeMutableBytes { (from_p : UnsafeMutablePointer<sockaddr>) -> Int in
                            buf.withUnsafeMutableBytes { recvfrom(s, $0.baseAddress, buf_size, 0, from_p, from_len_p) }
                        }
                    }
                    if ret < 0 {
                        GenericTools.perror("recvfrom")
                        continue
                    }

                    self.manageAnswer(from: SockAddr4(from)?.getIPAddress() as! IPv4Address)
                    print("reply from IPv4", SockAddr.getSockAddr(from).toNumericString())
                    
                } while !self.isFinished()
                dispatchGroup.leave()
            }

            // Catch IPv6 replies
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                repeat {
                    let buf_size = 10000
                    var buf = [UInt8](repeating: 0, count: buf_size)
                    var from = Data(count: MemoryLayout<sockaddr_in6>.size)
                    var from_len : socklen_t = UInt32(from.count)
                    
                    let ret = withUnsafeMutablePointer(to: &from_len) { (from_len_p) -> Int in
                        from.withUnsafeMutableBytes { (from_p : UnsafeMutablePointer<sockaddr>) -> Int in
                            buf.withUnsafeMutableBytes { recvfrom(s6, $0.baseAddress, buf_size, 0, from_p, from_len_p) }
                        }
                    }
                    if ret < 0 {
                        GenericTools.perror("reply from IPv6")
                        continue
                    }
                    
//                    self.manageAnswer(from: SockAddr6(from)?.getIPAddress() as! IPv6Address)
                    print("reply from IPv6", SockAddr.getSockAddr(from).toNumericString())
                    
                } while !self.isFinished()
                dispatchGroup.leave()
            }

            
            dispatchGroup.wait()
  
            DispatchQueue.main.sync { self.browser_tcp.browse() }

        }
    }
}
