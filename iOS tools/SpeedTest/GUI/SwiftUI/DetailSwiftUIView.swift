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

var delta: CGFloat?

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

    // trouver comment faire une modif de ce state depuis UIKit: cf TracesSwiftUIView.swift
    public class DetailViewModel : ObservableObject {
        @Published private(set) var node: Node? = nil
        @Published private(set) var family: Int32? = nil
        @Published private(set) var v4address: IPv4Address? = nil
        @Published private(set) var v6address: IPv6Address? = nil
        @Published private(set) var address_str: String? = nil
        public func setNodeAddress(_ val: Node, _ address: IPAddress) {
            node = val
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
                
                VStack {
                    GeometryReader { geom in
                        SpriteView(scene: {
                            
                            print("(re-)create scene")
                            let scene = SKScene()
                            scene.size = CGSize(width: geom.size.width, height: 300)
                            scene.scaleMode = .fill
                            
                            Task {
                                let chart_node = await SKChartNode(ts: ts, full_size: CGSize(width: geom.size.width, height: 300), grid_size: CGSize(width: 20, height: 20), subgrid_size: CGSize(width: 5, height: 5), line_width: 1, left_width: 120, bottom_height: 50, vertical_unit: "Kbit/s", grid_vertical_cost: 10, date: Date(), grid_time_interval: 2, background: .gray, max_horizontal_font_size: 10, max_vertical_font_size: 20, spline: true, vertical_auto_layout: true, debug: false, follow_view: nil)
                                scene.addChild(chart_node)
                                chart_node.registerGestureRecognizers(view: view, delta: 40)
                                chart_node.position = CGPoint(x: 0, y: 0)
                                await ts.add(TimeSeriesElement(date: Date(), value: 5.0))
                            }
                            
                            return scene
                        }())
                    }
                    .frame(minWidth: 0, idealWidth: UIScreen.main.bounds.size.width, maxWidth: .infinity, minHeight: 0, idealHeight: 300, maxHeight: .infinity, alignment: .center)
                    
                }
                
                Text("Séparation")
                Text(model.address_str == nil ? "none" : model.address_str!) // CONTINUER ICI

                HStack {
                    Button {
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
                        Text("127.0.0.1")
                    }
                    
                    HStack {
                        Text("names")
                        Spacer()
                        VStack {
                            Text("ipad.toto")
                            Text("localhost")
                        }
                    }
                }

                Group {
                    
                    HStack {
                        Text("ports")
                        Spacer()
                        VStack {
                            Text("TCP/22")
                            Text("TCP/80")
                        }
                    }
                
                    HStack {
                        Text("interface")
                        Spacer()
                        Text("en0")
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
