//
//  NetworkBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 27/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class NetworkBrowser {
    private let device_manager : DeviceManager
    private let network : IPv4Address
    private let netmask : IPv4Address
    private let broadcast : IPAddress
    private var reply : [IPv4Address: (Int, Date?)] = [:]
    private var finished : Bool = false

    public init?(network: IPv4Address?, netmask: IPv4Address?, device_manager: DeviceManager) {
        guard let network = network, let netmask = netmask else {
            return nil
        }
        
        self.device_manager = device_manager
        self.network = network
        self.netmask = netmask
        broadcast = self.network.or(self.netmask.xor(IPv4Address("255.255.255.255")!))

        var current = network.and(netmask).next() as! IPv4Address
        repeat {
            reply[current] = (NetworkDefaults.n_icmp_echo_reply, nil)
            current = current.next() as! IPv4Address
        } while current != broadcast
    }

    private func getIPForTask() -> IPv4Address? {
        return DispatchQueue.main.sync {
            guard let address = reply.filter({
                guard let last_use = $0.value.1 else { return true }
                return Date().timeIntervalSince(last_use) > 3
            }).first?.key else { return nil }
            reply[address]!.0 -= 1
            if reply[address]!.0 == 0 { reply.removeValue(forKey: address) }
            else { reply[address]!.1 = Date() }
            return address
        }
    }

    private func manageAnswer(from: IPv4Address) {
        DispatchQueue.main.sync {
            device_manager.addDevice(name: "unnamed \(from.toNumericString())", addresses: [from])
            reply.removeValue(forKey: from)
        }
    }
    
    private func isFinished() -> Bool {
        return DispatchQueue.main.sync { finished || reply.isEmpty }
    }
    
    public func browse() {
        DispatchQueue.global(qos: .userInitiated).async {
            let s = socket(AF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
            if s < 0 {
                GenericTools.perror("socket")
                fatalError("browse: socket")
            }
            
            var tv = timeval(tv_sec: 3, tv_usec: 0)
            let ret = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
            if ret < 0 {
                GenericTools.perror("setsockopt")
                fatalError("browse: setsockopt")
            }

            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                repeat {
                    let address = self.getIPForTask()
                    if let address = address {
                        print("sending icmp to", address.toNumericString())

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
                } while !self.isFinished()
                
                dispatchGroup.leave()
            }

            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                repeat {
                    let buf_size = 10000
                    var buf = [UInt8](repeating: 0, count: buf_size)
                    var from = Data(count: MemoryLayout<sockaddr_in>.size)
                    var from_len : socklen_t = UInt32(from.count)
                    let ret = withUnsafeMutablePointer(to: &from_len) { (from_len_p) -> Int in
                        from.withUnsafeMutableBytes { (from_p : UnsafeMutablePointer<sockaddr>) -> Int in
                            buf.withUnsafeMutableBytes {
                                recvfrom(s, $0.baseAddress, buf_size, 0, from_p, from_len_p)
                            }
                        }
                    }
                    if ret < 0 {
                        GenericTools.perror("recvfrom")
                        continue
                    }

                    self.manageAnswer(from: SockAddr4(from)?.getIPAddress() as! IPv4Address)

                    print("reply from", SockAddr.getSockAddr(from).toNumericString())
                    
                } while true
                    
                dispatchGroup.leave()
            }
            dispatchGroup.wait()
            print("FIN FIN FIN FIN")
        }
        
        return
        ;
        
//        current = network.and(netmask).next() as? IPv4Address

        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.concurrentPerform(iterations: 3 /*NetworkDefaults.n_parallel_tasks*/ ) {
                idx in
                print("ITERATION \(idx) : début")
                while let address = self.getIPForTask() {
                    print(idx, address.toNumericString())

                    let s = socket(AF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
                    if s < 0 {
                        GenericTools.perror("socket")
                        fatalError("browse: socket")
                    }

                    var tv = timeval(tv_sec: 3, tv_usec: 0)
                    let ret = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
                    if ret < 0 {
                        GenericTools.perror("setsockopt")
                        fatalError("browse: setsockopt")
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

                    let ret2 = withUnsafePointer(to: &hdr) {
                        (bytes) -> Int in
                        address.toSockAddress()!.sockaddr.withUnsafeBytes {
                            (sockaddr : UnsafePointer<sockaddr>) in
                            return sendto(s, bytes, MemoryLayout<icmp>.size, 0, sockaddr, UInt32(MemoryLayout<sockaddr_in>.size))
                        }
                    }
                    if ret2 < 0 {
                        GenericTools.perror("sendto")
                        continue
                    }

                    let buf_size = 10000
                    var buf = [UInt8](repeating: 0, count: buf_size)
                    var from = Data(count: MemoryLayout<sockaddr_in>.size)
                    var from_len : socklen_t = UInt32(from.count)
                    let ret3 = withUnsafeMutablePointer(to: &from_len) {
                        (from_len_p) -> Int in
                        from.withUnsafeMutableBytes {
                            (from_p : UnsafeMutablePointer<sockaddr>) -> Int in
                            buf.withUnsafeMutableBytes {
                                recvfrom(s, $0.baseAddress, buf_size, 0, from_p, from_len_p)
                            }
                        }
                    }
                    if ret3 < 0 {
                        GenericTools.perror("recvfrom")
                        continue
                    }

                    print("REPLY: sending to", address.toNumericString(),
                          ", reply from", SockAddr.getSockAddr(from).toNumericString())

                }
                print("ITERATION \(idx) : fin")
            }
            print("après itérations")
        }

    }
}
