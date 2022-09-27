//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

public class DetailViewModel : ObservableObject {
    static let shared = DetailViewModel()
    
    @Published private(set) var family: Int32? = nil
    @Published private(set) var address: IPAddress? = nil
    @Published private(set) var v4address: IPv4Address? = nil
    @Published private(set) var v6address: IPv6Address? = nil
    @Published private(set) var address_str: String? = nil
    @Published private(set) var display_names = ""
    @Published private(set) var display_addresses = ""
    @Published private(set) var display_ports = ""
    @Published private(set) var display_interfaces = ""
    @Published private(set) var buttons_enabled = false
    @Published private(set) var stop_button_enabled = false

    public func setButtonsEnabled(_ state: Bool) {
        print("setButtonsEnabled(\(state)) - addresse=\(address)")
        buttons_enabled = address == nil ? false : state
    }

    public func setStopButtonEnabled(_ state: Bool) {
        stop_button_enabled = state
    }

    internal func updateDetails(_ node: Node, _ address: IPAddress, _ buttons_enabled: Bool) {
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
        
        setButtonsEnabled(buttons_enabled)
    }
}

@MainActor
struct DetailSwiftUIView: View {
    public let view: UIView
    public let master_view_controller: MasterViewController

    @ObservedObject var model = DetailViewModel.shared

    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    Text(model.address_str == nil ? "none" : model.address_str!)
                    let button_width: CGFloat = 120
                    HStack {
                        Button {
                            if model.address != nil {
                                master_view_controller.scanTCP(model.address!)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "scanner").resizable().frame(width: 40, height: 30)
                                Text("scan TCP ports").font(.footnote)
                            }
                        }.frame(width: button_width).disabled(!model.buttons_enabled)
                        
                        Spacer()
                        
                        Button {
                            if model.address != nil {
                                master_view_controller.floodUDP(model.address!)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "dot.radiowaves.right").resizable().rotationEffect(.degrees(-90)).frame(width: 25, height: 30)
                                Text("flood").font(.footnote)
                            }
                        }.frame(width: button_width).disabled(!model.buttons_enabled)
                        
                        Spacer()
                        
                        Button {
                            if model.address != nil {
                                master_view_controller.floodTCP(model.address!)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.up.on.square").resizable().frame(width: 30, height: 30)
                                Text("TCP flood").font(.footnote)
                            }
                        }.frame(width: button_width).disabled(!model.buttons_enabled)
                        
                        Spacer()
                        
                        Button {
                            if model.address != nil {
                                master_view_controller.chargenTCP(model.address!)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.down.on.square").resizable().frame(width: 30, height: 30)
                                Text("TCP chargen").font(.footnote)
                            }
                        }.frame(width: button_width).disabled(!model.buttons_enabled)
                        
                        Spacer()

                        Button {
                            if model.address != nil {
                                master_view_controller.loopICMP(model.address!)
                            }
                        } label: {
                            VStack {
                                Image(systemName: "clock").resizable().frame(width: 30, height: 30)
                                Text("ICMP (ping)").font(.footnote)
                            }
                        }.frame(width: button_width).disabled(!model.buttons_enabled)
                        
                        if model.stop_button_enabled {
                            Spacer()
                            Button {
                                master_view_controller.stop_pressed()
                            } label: {
                                Label("Stop", systemImage: "stop.circle").disabled(model.buttons_enabled)
                            }.disabled(model.buttons_enabled)
                        }
                    }
                    
                    Group {
                        /*
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
                         */
                        
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
                        
                        /*
                         HStack {
                         Text("interfaces")
                         Spacer()
                         Text(model.display_interfaces)
                         }
                         */
                    }
                }.padding(10).background(Color(COLORS.right_pannel_scroll_bg)) // VStack
            }.cornerRadius(15).padding(7) // .background(.red) // VStack
        }.background(Color(COLORS.right_pannel_bg)) // ScrollView
    }
}
