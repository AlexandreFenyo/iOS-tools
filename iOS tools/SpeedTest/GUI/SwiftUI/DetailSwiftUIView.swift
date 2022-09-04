//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit
//import Foundation

public actor PingLoop {
    private var address: IPAddress?
    private var nthreads = 0
    
    init() {}
    
    public func start(ts: TimeSeries, address: IPAddress) async throws {
        print("PingLoop.start()")
        if let address = address as? IPv4Address {
            let address: IPv4Address = address.copy() as! IPv4Address
            let s = socket(PF_INET, SOCK_DGRAM, getprotobyname("icmp").pointee.p_proto)
            if s < 0 {
                GenericTools.perror("socket")
                fatalError("chart: socket")
            }
            
            nthreads += 1
            repeat {
                if  address.getFamily() == AF_INET {
                    await ts.add(TimeSeriesElement(date: Date(), value: 50))
                    
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
                try await Task.sleep(nanoseconds: 1_000_000_000)
                //                try await Task.sleep(nanoseconds: 1_000_000_0)
            } while nthreads == 1
            close(s)
            nthreads -= 1
        }
    }
}

public let pingLoop = PingLoop()

@MainActor
struct DetailSwiftUIView: View {
    public let ts = TimeSeries()
    
    public let view: UIView
    public let master_view_controller: MasterViewController
    
    // trouver comment faire une modif de ce state depuis UIKit: cf TracesSwiftUIView.swift
    public class DetailViewModel : ObservableObject {
        @Published private(set) var family: Int32? = nil
        @Published private(set) var address: IPAddress? = nil
        @Published private(set) var v4address: IPv4Address? = nil
        @Published private(set) var v6address: IPv6Address? = nil
        @Published private(set) var address_str: String? = nil

        @Published private(set) var display_names: String = ""
        @Published private(set) var display_addresses: String = ""
        @Published private(set) var display_ports: String = ""
        @Published private(set) var display_interfaces: String = ""

        public func updateDetails(_ node: Node, _ address: IPAddress) {
            let sep = "\n"

            display_names = node.dns_names.map { $0.toString() }.joined(separator: sep)
            display_addresses = (node.v4_addresses.map { $0.toNumericString() ?? "" } + node.v6_addresses.map { $0.toNumericString() ?? "" }).joined(separator: sep)
            display_ports = node.tcp_ports.map { "TCP/\($0)" }.joined(separator: sep)

            var interfaces = [""]
            for addr in node.v6_addresses {
                if let substrings = addr.toNumericString()?.split(separator: "%") {
                    if substrings.count > 1 && !interfaces.contains(String(substrings[1])) {
                        interfaces.append(String(substrings[1]))
                    }
                }
            }
            display_interfaces = interfaces.joined(separator: sep)
            
            self.address = address
            family = address.getFamily()
            address_str = address.toNumericString()
            if family == AF_INET {
                v4address = address as? IPv4Address
                v6address = nil
            } else {
                v6address = address as? IPv6Address
                v4address = nil
            }
        }
    }
    
    @ObservedObject var model = DetailViewModel()
    
    var body: some View {
        ScrollView {
            
            VStack {
                Text(model.address_str == nil ? "none" : model.address_str!)
                
                HStack {
                    Button {
                        if model.address != nil {
                            master_view_controller.scanTCP(model.address!)
                        }
                    } label: {
                        Label("scan TCP ports", systemImage: "rectangle.split.2x2")
                    }
                    
                    Spacer()
                    
                    Button {
                    } label: {
                        Label("UDP flood", systemImage: "rectangle.split.2x2")
                    }
                    
                    Spacer()
                    
                    Button {
                    } label: {
                        Label("TCP flood", systemImage: "rectangle.split.2x2")
                    }
                    
                    Spacer()
                    
                    Button {
                    } label: {
                        Label("connect to TCP chargen service", systemImage: "rectangle.split.2x2")
                    }
                    
                    Button {
                    } label: {
                        Label("ICMP (ping)", systemImage: "rectangle.split.2x2")
                    }
                }
                
                Group {
                    HStack {
                        Text("UDP sent throughput")
                        Spacer()
                        Text("20 Mbit/s")
                    }
                    
                    HStack {
                        Text("UDP packets sent throughput")
                        Spacer()
                        Text("10 pkt/s")
                    }
                    
                    HStack {
                        Text("TCP bits received throughput")
                        Spacer()
                        Text("20 Mbit/s")
                    }
                    
                    HStack {
                        Text("TCP bits sent throughput")
                        Spacer()
                        Text("10 Mbit/s")
                    }
                    
                    HStack {
                        Text("ICMP latency")
                        Spacer()
                        Text("12 ms")
                    }
                    
                    HStack {
                        Text("IP address")
                        Spacer()
                        Text(model.display_addresses)
                    }
                    
                    HStack {
                        Text("names")
                        Spacer()
                        Text(model.display_names)
                    }
                }
                
                Group {
                    
                    HStack {
                        Text("ports")
                        Spacer()
                        Text(model.display_ports)
                    }
                    
                    HStack {
                        Text("interfaces")
                        Spacer()
                        Text(model.display_interfaces)
                    }
                    
                }
                
                // boutons : pour envoyer ICMP, pour se connecter au chargen, pour faire un scan TCP
                
            }
            
        } // ScrollView
        
    }
}

/*
 struct DetailSwiftUIView_Previews: PreviewProvider {
 static var previews: some View {
 DetailSwiftUIView(nil)
 }
 }
 */
