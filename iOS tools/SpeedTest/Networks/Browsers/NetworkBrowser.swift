//
//  NetworkBrowser.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 27/08/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import Foundation

class NetworkBrowser {
    private let network : IPv4Address
    private let netmask : IPv4Address
    private let broadcast : IPAddress
    private var current : IPv4Address? = nil

    public init?(network: IPv4Address?, netmask: IPv4Address?) {
        if network == nil || netmask == nil { return nil }
        self.network = network!
        self.netmask = netmask!
        broadcast = self.network.or(self.netmask.xor(IPv4Address("255.255.255.255")!))
    }

    private func getIPForTask() -> IPv4Address? {
        return DispatchQueue.main.sync {
            () -> IPv4Address? in
            if current == nil { return nil }
            current = current!.next() as? IPv4Address
            if current != broadcast { return current }
            current = nil
            return nil
        }
    }
    
    public func browse() {
        current = network.and(netmask).next() as? IPv4Address

        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.concurrentPerform(iterations: NetworkDefaults.n_parallel_tasks) {
                idx in
                print("ITERATION \(idx) : début")
                while let address = self.getIPForTask() {
                    print(idx, address.getNumericAddress())

                    let s = socket(AF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
                    if s < 0 {
                        perror("socket")
                        fatalError("browse: socket")
                    }

                    var tv = timeval(tv_sec: 3, tv_usec: 0)
                    let ret = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
                    if ret < 0 {
                        perror("setsockopt")
                        fatalError("browse: setsockopt")
                    }

                    var hdr = icmp()
                    hdr.icmp_type = UInt8(ICMP_ECHO)
                    hdr.icmp_code = 0
                    hdr.icmp_hun.ih_idseq.icd_seq = _htons(13)
                    hdr.icmp_cksum = withUnsafePointer(to: &hdr) {
                        $0.withMemoryRebound(to: u_short.self, capacity: MemoryLayout<icmp>.size / 2) {
                            var sum : u_short = 0
                            for idx in 0..<(MemoryLayout<icmp>.size / 2) { sum += $0[idx] }
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

                    print("sendto retval:", ret2)

                }
                print("ITERATION \(idx) : fin")
            }
            print("après itérations")
        }

    }
}
