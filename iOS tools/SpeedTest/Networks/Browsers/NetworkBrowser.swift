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
                var address = self.getIPForTask()
                while address != nil {
                    print(idx, address?.getNumericAddress())

                    let s = socket(AF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
                    if s < 0 {
                        perror("socket")
                        fatalError("browse: socket")
                    }

                    var tv = timeval(tv_sec: 3, tv_usec: 0)
                    var ret = setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, UInt32(MemoryLayout<timeval>.size))
                    if ret < 0 {
                        perror("setsockopt")
                        fatalError("browse: setsockopt")
                    }

                    var hdr = icmp()
                    hdr.icmp_type = UInt8(ICMP_ECHO)
                    hdr.icmp_code = 0
                    hdr.icmp_hun.ih_idseq.icd_seq = _htons(13)

//                    [ushort].

//                    var buffer = [ushort](repeating: 0, count: MemoryLayout<icmp>.size / 2)
//                    buffer.withUnsafeBufferPointer {
//                        (bytes) -> Int in
//                        let x : UnsafeRawPointer = bytes
//                        let a = 2
//                        return a
//                    }
                    

                    withUnsafeBytes(of: &hdr) {
                        bytes in

                        var buffer = [ushort](repeating: 0, count: MemoryLayout<icmp>.size / 2)
                        
                        
                        bytes.map {
                            (UInt8) in
                            let x = 5
                        }


                        let x = 5
                    }
    
                    address = self.getIPForTask()
                }
                print("ITERATION \(idx) : fin")
            }
            print("après itérations")
        }

    }
}
