//
//  TCPPortBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 03/09/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

//import Foundation
//
//class NetworkBrowser {
//    private let network : IPv4Address
//    private let netmask : IPv4Address
//    private let broadcast : IPAddress
//    private var current : IPv4Address? = nil
//
//    public init?(network: IPv4Address?, netmask: IPv4Address?) {
//        if network == nil || netmask == nil { return nil }
//        self.network = network!
//        self.netmask = netmask!
//        broadcast = self.network.or(self.netmask.xor(IPv4Address("255.255.255.255")!))
//    }
//
//    private func getIPForTask() -> IPv4Address? {
//        return DispatchQueue.main.sync {
//            () -> IPv4Address? in
//            if current == nil { return nil }
//            current = current!.next() as? IPv4Address
//            if current != broadcast { return current }
//            current = nil
//            return nil
//        }
//    }
//
//    public func browse() {
//        current = network.and(netmask).next() as? IPv4Address
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            DispatchQueue.concurrentPerform(iterations: NetworkDefaults.n_parallel_tasks) {
//                idx in
//                print("ITERATION \(idx) : début")
//                while let address = self.getIPForTask() {
//                    print(idx, address.getNumericAddress())
//
//                    let s = socket(AF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
//                    if s < 0 {
//                        GenericTools.perror("socket")
//                        fatalError("browse: socket")
//                    }
//
//                    var tv = timeval(tv_sec: 3, tv_usec: 0)
//                    let ret = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
//                    if ret < 0 {
//                        GenericTools.perror("setsockopt")
//                        fatalError("browse: setsockopt")
//                    }
//
//                    var hdr = icmp()
//                    hdr.icmp_type = UInt8(ICMP_ECHO)
//                    hdr.icmp_code = 0
//                    hdr.icmp_hun.ih_idseq.icd_seq = _htons(13)
//                    let capacity = MemoryLayout<icmp>.size / MemoryLayout<ushort>.size
//                    hdr.icmp_cksum = withUnsafePointer(to: &hdr) {
//                        $0.withMemoryRebound(to: u_short.self, capacity: capacity) {
//                            var sum : u_short = 0
//                            for idx in 0..<capacity { sum += $0[idx] }
//                            sum ^= u_short.max
//                            return sum
//                        }
//                    }
//
//                    let ret2 = withUnsafePointer(to: &hdr) {
//                        (bytes) -> Int in
//                        address.toSockAddress()!.sockaddr.withUnsafeBytes {
//                            (sockaddr : UnsafePointer<sockaddr>) in
//                            return sendto(s, bytes, MemoryLayout<icmp>.size, 0, sockaddr, UInt32(MemoryLayout<sockaddr_in>.size))
//                        }
//                    }
//                    if ret2 < 0 {
//                        GenericTools.perror("sendto")
//                        continue
//                    }
//
//                    let buf_size = 10000
//                    var buf = [UInt8](repeating: 0, count: buf_size)
//                    var from = Data(count: MemoryLayout<sockaddr_in>.size)
//                    var from_len : socklen_t = UInt32(from.count)
//                    let ret3 = withUnsafeMutablePointer(to: &from_len) {
//                        (from_len_p) -> Int in
//                        from.withUnsafeMutableBytes {
//                            (from_p : UnsafeMutablePointer<sockaddr>) -> Int in
//                            buf.withUnsafeMutableBytes {
//                                recvfrom(s, $0.baseAddress, buf_size, 0, from_p, from_len_p)
//                            }
//                        }
//                    }
//                    if ret3 < 0 {
//                        GenericTools.perror("recvfrom")
//                        continue
//                    }
//
//                    print("REPLY: sending to", address.getNumericAddress(),
//                          ", reply from", SockAddr.getSockAddr(from).getNumericAddress())
//
//                }
//                print("ITERATION \(idx) : fin")
//            }
//            print("après itérations")
//        }
//
//    }
//}
