//
//  NetworkBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 27/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation
import iOSToolsMacros

// Only a single instance can work at a time, since ICMP replies are sent to any thread while calling recvfrom()
@MainActor
class NetworkBrowser {
    private let device_manager: DeviceManager
    private let browser_tcp: TCPPortBrowser?
    private var reply_ipv4: [IPv4Address: (Int, Date?)] = [:]
    private var broadcast_ipv4 = Set<IPv4Address>()
    private var multicast_ipv6 = Set<IPv6Address>()
    private var unicast_ipv4_finished = false
    private var broadcast_ipv4_finished = false
    private var multicast_ipv6_finished = false
    private var finished = false
    
    // Browse a set of networks
    // Any Thread
    init(networks: Set<IPNetwork>, device_manager: DeviceManager, browser_tcp: TCPPortBrowser? = nil) async {
        self.device_manager = device_manager
        self.browser_tcp = browser_tcp
        
        for network in networks {
            // IPv6 networks
            if let network_addr = network.ip_address as? IPv6Address {
                // question : comment ::1 peut arriver dans networks ? (c'est bien le cas)
                if network_addr == IPv6Address("::1") { continue }
                if network_addr.isLLA() {
                    let multicast = IPv6Address("ff02::1")!.changeScope(scope: network_addr.getScope())
                    device_manager.addTrace("network browsing: will send IPV6 multicast packet to \(multicast.toNumericString() ?? "")", level: .DEBUG)
                    multicast_ipv6.insert(multicast)
                }
            }
            
            // IPv4 networks
            // Either broadcast the entire network or ping each address, depending on the network size
            if let network_addr = network.ip_address as? IPv4Address {
                let netmask = IPv4Address(mask_len: network.mask_len)
                let broadcast = network_addr.or(netmask.xor(IPv4Address("255.255.255.255")!)) as! IPv4Address
                if network.mask_len < 22 {
                    device_manager.addTrace("network browsing: will send IPv4 broadcast packet to \(broadcast.toNumericString() ?? "")", level: .DEBUG)
                    broadcast_ipv4.insert(broadcast)
                } else {
                    if network.mask_len != 32 {
                        var current = network_addr.and(netmask).next() as! IPv4Address
                        repeat {
                            if (DBMaster.shared.nodes.filter { $0.getV4Addresses().contains(current) }).isEmpty {
                                device_manager.addTrace("network browsing: will send IPv4 unicast packet to \(current.toNumericString() ?? "")", level: .ALL)
                                reply_ipv4[current] = (NetworkDefaults.n_icmp_echo_reply, nil)
                            }
                            current = current.next() as! IPv4Address
                        } while current != broadcast
                    }
                }
            }
        }
    }
    
    private func getIPForTask() async -> IPv4Address? {
        // Collect one address among those left and used more than 3 secs ago
        guard let address = reply_ipv4.filter({
            guard let last_use = $0.value.1 else { return true }
            return Date().timeIntervalSince(last_use) > 3
        }).first?.key else { return nil }
        reply_ipv4[address]!.0 -= 1
        if let info = address.toNumericString() { device_manager.setInformation((reply_ipv4[address]!.0 == NetworkDefaults.n_icmp_echo_reply - 1 ? "" : "re") + NSLocalizedString("trying ", comment: "trying ") + info) }
        // Remove the address if used 3 times, but note that when the last one is removed, we should wait 3 secs before considering we have been able to wait for a reply from this last address
        if reply_ipv4[address]!.0 == 0 { reply_ipv4.removeValue(forKey: address) }
        else { reply_ipv4[address]!.1 = Date() }
        return address
    }
    
    private func manageAnswer(from: IPAddress) async {
        let node = Node()
        switch from.getFamily() {
        case AF_INET:
            node.addV4Address(from as! IPv4Address)
            // We want to increase the probability to get a name for this address, so try to resolve every addresses of this node, because this could have not worked previously
            device_manager.addNode(node, resolve_ipv4_addresses: node.getV4Addresses())
            if let info = from.toNumericString() {
                self.device_manager.addTrace("network browsing: answer from IPv4 address: \(info)", level: .INFO)
                device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + info)
            }
            // Do not try to reach this address with unicast anymore
            reply_ipv4.removeValue(forKey: from as! IPv4Address)
            
        case AF_INET6:
            node.addV6Address(from as! IPv6Address)
            // We want to increase the probability to get a name for this address, so try to resolve every addresses of this node, because this could have not worked previously
            device_manager.addNode(node, resolve_ipv6_addresses: node.getV6Addresses())
            if let info = from.toNumericString() {
                self.device_manager.addTrace("network browsing: answer from IPv6 address: \(info)", level: .INFO)
                device_manager.setInformation(NSLocalizedString("found ", comment: "found ") + info)
            }
            
        default:
            print("manageAnswer(): invalid family", from.getFamily())
        }
    }
    
    func stop() async {
        await browser_tcp?.stop()
        finished = true
    }
    
    private func isFinished() -> Bool {
        return finished
    }
    
    private func isFinishedOrUnicastEmpty() -> Bool {
        return finished || reply_ipv4.isEmpty
    }
    
    private func isFinishedOrEverythingDone() -> Bool {
        return finished || (unicast_ipv4_finished && broadcast_ipv4_finished && multicast_ipv6_finished)
    }

    func browseAsync(_ doAtEnd: @escaping () async -> Void = {}) async {
        Task.detached {
            let s = socket(PF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
            if s < 0 {
                GenericTools.perror("socket")
                #fatalError("browse: socket")
                return
            }
            
            // Set timeout for no answer
            var tv = timeval(tv_sec: 3, tv_usec: 0)
            var ret = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
            if ret < 0 {
                GenericTools.perror("setsockopt")
                close(s)
                #fatalError("browse: setsockopt")
                return
            }
            
            let s6 = socket(PF_INET6, SOCK_DGRAM, getprotobyname("icmp6").pointee.p_proto)
            if s6 < 0 {
                GenericTools.perror("socket6")
                close(s)
                #fatalError("browse: socket6")
                return
            }
            
            // Set timeout for no answer
            ret = setsockopt(s6, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
            if ret < 0 {
                GenericTools.perror("setsockopt")
                close(s)
                close(s6)
                #fatalError("browse: setsockopt")
                return
            }
            
            await MainActor.run {
                self.device_manager.addTrace("network browsing: sending ICMPv4 unicast packets", level: .INFO)
                // Add torus
                DBMaster.shared.notifyBroadcast()
            }
            
            await withTaskGroup(of: Void.self) { group in
                // Send unicast ICMPv4
                group.addTask {
                    // wait .5 sec to let the recvfrom() start before sending ICMP packets // is it necessary?
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    repeat {
                        let address = await self.getIPForTask()
                        if let address = address {
                            await MainActor.run {
                                self.device_manager.addTrace("network browsing: sending ICMPv4 unicast packet to \(address.toNumericString() ?? "")", level: .ALL)
                            }
                            
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
                                address.toSockAddress()!.getData().withUnsafeBytes {
                                    sendto(s, bytes, MemoryLayout<icmp>.size, 0, $0.bindMemory(to: sockaddr.self).baseAddress, UInt32(MemoryLayout<sockaddr_in>.size))
                                }
                            }
                            if ret < 0 { GenericTools.perror("sendto") }
                        } else {
                            // Do not overload the proc
                            try? await Task.sleep(nanoseconds: 250_000_000)
                        }
                    } while await !self.isFinishedOrUnicastEmpty()
                    
                    // Wait .5 sec between the last unicast packet sent and toggling the finished flag
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        self.unicast_ipv4_finished = true
                        self.device_manager.addTrace("network browsing: finished sending ICMPv4 unicast packets", level: .INFO)
                    }
                }
                
                // Send broadcast ICMPv4
                group.addTask {
                    await MainActor.run {
                        self.device_manager.addTrace("network browsing: sending ICMPv4 broadcast packets", level: .INFO)
                    }

                    // wait .5 sec to let the recvfrom() start before sending ICMP packets
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    for _ in 1...3 {
                        for address in await self.broadcast_ipv4 {
                            await MainActor.run {
                                self.device_manager.addTrace("network browsing: sending ICMPv4 broadcast packet to \(address.toNumericString() ?? "")", level: .ALL)
                            }
                            
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
                                address.toSockAddress()!.getData().withUnsafeBytes {
                                    sendto(s, bytes, MemoryLayout<icmp>.size, 0, $0.bindMemory(to: sockaddr.self).baseAddress, UInt32(MemoryLayout<sockaddr_in>.size))
                                }
                            }
                            if ret < 0 { GenericTools.perror("sendto") }
                        }
                        
                        if await self.isFinished() { break }
                        // wait some delay before sending another broadcast packet
                        try? await Task.sleep(nanoseconds: 250_000_000)
                    }
                    
                    // Wait .5 sec between the last broadcast packet sent and toggling the finished flag
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        self.broadcast_ipv4_finished = true
                        self.device_manager.addTrace("network browsing: finished sending ICMPv4 broadcast packets", level: .INFO)
                    }

                }

                // Send multicast ICMPv6
                group.addTask {
                    await MainActor.run {
                        self.device_manager.addTrace("network browsing: sending ICMPv6 multicast packets", level: .INFO)
                    }
                    // wait .5 sec to let the recvfrom() start before sending ICMP packets
                    try? await Task.sleep(nanoseconds: 500_000_000)

                    for _ in 1...3 {
                        for address in await self.multicast_ipv6 {
                            await MainActor.run {
                                self.device_manager.addTrace("network browsing: sending ICMPv6 multicast packet to \(address.toNumericString() ?? "")", level: .ALL)
                            }
                            
                            var saddr = address.toSockAddress()!.getData()
                            var msg_hdr = msghdr()
                            var hdr = icmp6_hdr()
                            var iov = iovec()
                            hdr.icmp6_type = UInt8(ICMP6_ECHO_REQUEST)
                            hdr.icmp6_code = 0
                            hdr.icmp6_dataun.icmp6_un_data16.0 = 55 // icmp6_id
                            hdr.icmp6_dataun.icmp6_un_data16.1 = _ntohs(0) // icmp6_seq
                            iov.iov_len = 8
                            msg_hdr.msg_namelen = UInt32(saddr.count)
                            let retlen = saddr.withUnsafeMutableBytes { (ptr) -> Int in
                                msg_hdr.msg_name = UnsafeMutableRawPointer(mutating: ptr.bindMemory(to: sockaddr_in6.self).baseAddress)
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
                                //                            print("IPV6 sendmsg: retval=", retlen)
                                //                            GenericTools.perror()
                            }
                        }
                        
                        if await self.isFinished() { break }
                        // wait some delay before sending another broadcast packet
                        try? await Task.sleep(nanoseconds: 250_000_000)
                    }
                    
                    
                    // Wait .5 sec between the last multicast packet sent and toggling the finished flag
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        self.multicast_ipv6_finished = true
                        self.device_manager.addTrace("network browsing: finished sending ICMPv6 multicast packets", level: .INFO)
                    }
                }

                // Catch IPv4 replies
                group.addTask {
                    await MainActor.run {
                        self.device_manager.addTrace("network browsing: waiting for IPv4 replies", level: .INFO)
                    }

                    repeat {
                        let buf_size = 10000
                        var buf = [UInt8](repeating: 0, count: buf_size)
                        var from = Data(count: MemoryLayout<sockaddr_in>.size)
                        var from_len : socklen_t = UInt32(from.count)
                        
                        let ret = withUnsafeMutablePointer(to: &from_len) { (from_len_p) -> Int in
                            from.withUnsafeMutableBytes { (from_p : UnsafeMutableRawBufferPointer) -> Int in
                                buf.withUnsafeMutableBytes { recvfrom(s, $0.baseAddress, buf_size, 0, from_p.bindMemory(to: sockaddr.self).baseAddress, from_len_p) }
                            }
                        }
                        if ret < 0 {
                            GenericTools.perror("recvfrom")
                            continue
                        }
                        
                        await self.manageAnswer(from: SockAddr4(from)?.getIPAddress() as! IPv4Address)
                    } while await !self.isFinishedOrEverythingDone()
                    
                    await MainActor.run {
                        self.device_manager.addTrace("network browsing: finished waiting for IPv4 replies", level: .INFO)
                    }
                }
                
                // Catch IPv6 replies
                group.addTask {
                    await MainActor.run {
                        self.device_manager.addTrace("network browsing: waiting for IPv6 replies", level: .INFO)
                    }

                    repeat {
                        let buf_size = 10000
                        var buf = [UInt8](repeating: 0, count: buf_size)
                        var from = Data(count: MemoryLayout<sockaddr_in6>.size)
                        var from_len : socklen_t = UInt32(from.count)
                        
                        let ret = withUnsafeMutablePointer(to: &from_len) { (from_len_p) -> Int in
                            from.withUnsafeMutableBytes { (from_p : UnsafeMutableRawBufferPointer) -> Int in
                                buf.withUnsafeMutableBytes { recvfrom(s6, $0.baseAddress, buf_size, 0, from_p.bindMemory(to: sockaddr.self).baseAddress, from_len_p) }
                            }
                        }
                        if ret < 0 {
                            GenericTools.perror("reply from IPv6")
                            continue
                        }
                        
                        await self.manageAnswer(from: SockAddr6(from)?.getIPAddress() as! IPv6Address)
                    } while await !self.isFinishedOrEverythingDone()
                 
                    await MainActor.run {
                        self.device_manager.addTrace("network browsing: finished waiting for IPv6 replies", level: .INFO)
                    }
                }
            }
            
            close(s)
            close(s6)
            
            await MainActor.run {
                self.device_manager.addTrace("network browsing: finished", level: .INFO)
                DBMaster.shared.notifyBroadcastFinished()
            }
            
            if let browser_tcp = self.browser_tcp {
                await browser_tcp.browseAsync(doAtEnd: doAtEnd)
            }
        }
    }

}
