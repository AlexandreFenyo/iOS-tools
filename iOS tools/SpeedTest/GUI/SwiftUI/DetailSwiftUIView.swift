//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

// struct TagCloudView by Asperi@stackoverflow https://stackoverflow.com/questions/62102647/swiftui-hstack-with-wrap-and-dynamic-height/62103264#62103264
struct TagCloudView: View {
    var tags: [String]
    let master_view_controller: MasterViewController
    
    let font: Font
    let on_tap: (String) -> Void
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(self.tags, id: \.self) { tag in
                self.item(for: tag)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > g.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if tag == self.tags.last! {
                            width = 0 //last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if tag == self.tags.last! {
                            height = 0 // last item
                        }
                        return result
                    })
                    .onTapGesture {
                        on_tap(tag)
                    }
            }
        }.background(viewHeightReader($totalHeight))
    }
    
    // MAX_LEN doit permettre d'afficher en entier une adresse IPv6 link-local
    private static let MAX_LEN = 40
    private func item(for text: String) -> some View {
            Text(text.prefix(Self.MAX_LEN) + (text.count > Self.MAX_LEN ? "..." : ""))
            .padding(.all, 5)
            .font(font)
            .background(Color(COLORS.standard_background))
            .foregroundColor(Color.white)
        //            .background(Color.blue)
        //            .foregroundColor(Color.white)
            .cornerRadius(5)
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

public class DetailViewModel : ObservableObject {
    static let shared = DetailViewModel()
    
    @Published private(set) var family: Int32? = nil
    @Published private(set) var address: IPAddress? = nil
    @Published private(set) var v4address: IPv4Address? = nil
    @Published private(set) var v6address: IPv6Address? = nil
    @Published private(set) var address_str: String? = nil
    @Published private(set) var buttons_enabled = false
    @Published private(set) var stop_button_enabled = false
    @Published private(set) var text_addresses = [String]()
    @Published private(set) var text_names = [String]()
    @Published private(set) var text_tcp_ports = [String]()
    @Published private(set) var text_udp_ports = [String]()
    @Published private(set) var text_services = [String]()
    @Published private(set) var text_services_port = [String : String]()
    @Published private(set) var text_services_attr = [String : [String]]()

    @Published private(set) var stop_button_master_view_hidden = true
    @Published private(set) var stop_button_master_ip_view_hidden = true
    
    @Published private(set) var scroll_to_top = false
    
    public func setButtonMasterHiddenState(_ state: Bool) {
        stop_button_master_view_hidden = state
    }
    
    public func setButtonMasterIPHiddenState(_ state: Bool) {
        stop_button_master_ip_view_hidden = state
    }
    
    public func setButtonsEnabled(_ state: Bool) {
        buttons_enabled = address == nil ? false : state
    }
    
    public func setStopButtonEnabled(_ state: Bool) {
        DispatchQueue.main.async {
            Task {
                switch state {
                case true:
                    if self.stop_button_master_view_hidden && self.stop_button_master_ip_view_hidden {
                        self.stop_button_enabled = true
                    } else {
                        self.stop_button_enabled = false
                    }
                    
                case false:
                    self.stop_button_enabled = false
                    
                }
            }
        }
    }

    public func toggleScrollToTop() {
        scroll_to_top.toggle()
    }
    
    internal func clearDetails() {
        text_addresses.removeAll()
        text_names.removeAll()
        text_tcp_ports.removeAll()
        text_udp_ports.removeAll()
        text_services.removeAll()
        text_services_port.removeAll()
        text_services_attr.removeAll()
        family = nil
        address = nil
        v4address = nil
        v6address = nil
        address_str = nil
    }
    
    internal func updateDetails(_ node: Node, _ address: IPAddress, _ buttons_enabled: Bool) {
        text_addresses = node.v4_addresses.compactMap { $0.toNumericString() ?? nil } + node.v6_addresses.compactMap { $0.toNumericString() ?? nil }

        let _text_names = node.names.map { $0 } + node.mcast_dns_names.map { $0.toString() } + node.dns_names.map { $0.toString() }
        for name in _text_names {
            if !text_names.contains(name) {
                text_names.insert(name, at: text_names.endIndex)
            }
        }

        text_tcp_ports = node.tcp_ports.map { TCPPort2Service[$0] != nil ? (TCPPort2Service[$0]!.uppercased() + " (\($0))") : "\($0)" }
        text_udp_ports = node.udp_ports.map { TCPPort2Service[$0] != nil ? (TCPPort2Service[$0]!.uppercased() + " (\($0))") : "\($0)" }
        text_services = node.services.map({ $0.name })
        
        _ = node.services.map({ $0 }).map { svc in
            text_services_port[svc.name] = svc.port
            text_services_attr[svc.name] = svc.attr.map({ (key: String, value: String) in
                value == "THIS_IS_NOT_A_VALUE_AFAFAF" ? "\(key)" : "\(key): \(value)"
            })
        }

        var interfaces = [""]
        for addr in node.v6_addresses {
            if let substrings = addr.toNumericString()?.split(separator: "%") {
                if substrings.count > 1 && !interfaces.contains(String(substrings[1])) {
                    interfaces.append(String(substrings[1]))
                }
            }
        }
        
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
    
    @Namespace var topID
    
    @ObservedObject var model = DetailViewModel.shared
    @State var animated_width: CGFloat = 0
    //    @State private var showing_popover = true
    
    var body: some View {
        HStack {
            // Text("next target:").foregroundColor(Color(COLORS.chart_scale)).opacity(0.8)
            Text(model.address_str == nil ? NSLocalizedString("none", comment: "none") : model.address_str!).foregroundColor(Color(COLORS.chart_scale))
        }
        
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                Color.clear.frame(height: 0)
                    .id(topID).onChange(of: model.scroll_to_top) { _ in
                        withAnimation { scrollViewProxy.scrollTo(topID) }
                    }
                VStack {
                    VStack {
                        HStack(alignment: .top) {
                            Button {
                                if model.address != nil {
                                    master_view_controller.popUpHelp(.scan_TCP_ports, NSLocalizedString("Parallel TCP connections will be established to ", comment: "Parallel TCP connections will be established to ") + (model.address_str ?? "") + NSLocalizedString(" on TCP ports from 1 to 65535, to find open services. The new discovered services will be displayed on the bottom view. You can interrupt this task by pressing the STOP button.", comment: " on TCP ports from 1 to 65535, to find open services. The new discovered services will be displayed on the bottom view. You can interrupt this task by pressing the STOP button.")) {
                                        master_view_controller.scanTCP(model.address!)
                                    }
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "scanner").resizable().frame(width: 40, height: 30)
                                    Text("scan TCP ports").font(.footnote).frame(maxWidth: 200)
                                }
                            }
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200).disabled(!model.buttons_enabled || model.address_str == nil)
                            
                            Button {
                                if model.address != nil {
                                    master_view_controller.popUpHelp(.TCP_flood_discard, NSLocalizedString("A TCP connection to the Discard port (9/TCP) of ", comment: "A TCP connection to the Discard port (9/TCP) of ") + (model.address_str ?? "") + NSLocalizedString(" will be established. Data will then be sent on this connection at the maximum throughput available, by this device to this target host, to evaluate the maximum speed that can be reached in the outgoing direction. You can interrupt this task by pressing the STOP button.", comment: " will be established. Data will then be sent on this connection at the maximum throughput available, by this device to this target host, to evaluate the maximum speed that can be reached in the outgoing direction. You can interrupt this task by pressing the STOP button.")) {
                                        master_view_controller.floodTCP(model.address!)
                                    }
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "square.and.arrow.up.on.square").resizable().frame(width: 30, height: 30)
                                    Text("TCP flood discard").font(.footnote)
                                }
                            }
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200).disabled(!model.buttons_enabled || model.address_str == nil)
                            
                            Button {
                                if model.address != nil {
                                    master_view_controller.popUpHelp(.TCP_flood_chargen, NSLocalizedString("A TCP connection to the Chargen port (19/TCP) of ", comment: "A TCP connection to the Chargen port (19/TCP) of ") + (model.address_str ?? "") + NSLocalizedString(" will be established. Data will then be received on this connection at the maximum throughput available, by this device from this target host, to evaluate the maximum speed that can be reached in the incoming direction. You can interrupt this task by pressing the STOP button.", comment: " will be established. Data will then be received on this connection at the maximum throughput available, by this device from this target host, to evaluate the maximum speed that can be reached in the incoming direction. You can interrupt this task by pressing the STOP button.")) {
                                        master_view_controller.chargenTCP(model.address!)
                                    }
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "square.and.arrow.down.on.square").resizable().frame(width: 30, height: 30)
                                    Text("TCP flood chargen").font(.footnote)
                                }
                            }
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200).disabled(!model.buttons_enabled || model.address_str == nil)
                            
                            Button {
                                if model.address != nil {
                                    master_view_controller.floodUDP(model.address!)
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "dot.radiowaves.right").resizable().rotationEffect(.degrees(-90)).frame(width: 25, height: 30)
                                    Text("UDP flood").font(.footnote)
                                }
                            }
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200).disabled(!model.buttons_enabled || model.address_str == nil)
                            
                            Button {
                                if model.address != nil {
                                    master_view_controller.popUpHelp(.ICMP_ping, NSLocalizedString("ICMP packets of type ECHO_REQUEST will be sent to ", comment: "ICMP packets of type ECHO_REQUEST will be sent to ") + (model.address_str ?? "") + NSLocalizedString(" at a rate of one packet per second. The target should reply with an ICMP packet of type ECHO_REPLY. The round trip type is computed and displayed on the chart. You can interrupt this task by pressing the STOP button.", comment: " at a rate of one packet per second. The target should reply with an ICMP packet of type ECHO_REPLY. The round trip type is computed and displayed on the chart. You can interrupt this task by pressing the STOP button.")) {
                                        master_view_controller.loopICMP(model.address!)
                                    }
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "clock").resizable().frame(width: 30, height: 30)
                                    Text("ICMP ping").font(.footnote)
                                }
                            }
                            .accentColor(Color(COLORS.standard_background))
                            .frame(maxWidth: 200).disabled(!model.buttons_enabled || model.address_str == nil)
                            
                            if model.stop_button_enabled {
                                Button {
                                    master_view_controller.stop_pressed()
                                } label: {
                                    VStack {
                                        Image(systemName: "stop.circle").resizable().frame(width: 30, height: 30)
                                        Text("Stop").font(.footnote)
                                    }
                                }
                                .onAppear {
                                    animated_width = 200
                                }
                                .onDisappear {
                                    animated_width = 0
                                }
                                .accentColor(Color(COLORS.standard_background))
                                .frame(maxWidth: animated_width).disabled(model.buttons_enabled || model.address_str == nil)
                                .animation(.easeOut(duration: 0.5), value: animated_width)
                            }
                        }
                        
                        VStack {
                            if !model.text_names.isEmpty {
                                HStack {
                                    VStack { Divider() }
                                    Text("mDNS and DNS host names").foregroundColor(.gray.lighter().lighter()).font(.footnote)
                                }
                            }
                            
                            TagCloudView(tags: model.text_names, master_view_controller: master_view_controller, font: .body) { tag in
                                if !tag.contains(".") || tag.contains("(") || tag.contains(")") || tag.contains(" ") || tag.contains(".local") || tag == "localhost" {
                                    master_view_controller.popUpHelp(.no_dns, "This hostname has not any public DNS record. Select a host name with public DNS records to get those records.") {
                                        master_view_controller.popUp("Hostname", tag, "OK")
                                    }
                                    return
                                }
                                master_view_controller.popUp("Hostname", tag, "OK")
                                UIApplication.shared.open(URL(string: "https://dns.google/query?name=\(tag)&type=ALL&do=true")!)
                            }

                            if !model.text_tcp_ports.isEmpty {
                                HStack {
                                    VStack { Divider() }
                                    Text("TCP ports and associated service names").foregroundColor(.gray.lighter().lighter()).font(.footnote)
                                }
                            }
                            
                            TagCloudView(tags: model.text_tcp_ports, master_view_controller: master_view_controller, font: .body) { tag in
                                let _first = tag.firstIndex(of: "(")
                                let _last = tag.firstIndex(of: ")")
                                var port_str = ""
                                if let _first, let _last {
                                    let first = tag.index(_first, offsetBy: 1)
                                    let last = tag.index(_last, offsetBy: -1)
                                    port_str = String(tag[first...last])
                                } else {
                                    port_str = tag
                                }
                                UIApplication.shared.open(URL(string: "https://www.speedguide.net/port.php?port=\(port_str)")!)
                                
                                /* Affichage d'un texte explicatif du port récupéré dans le fichier de conf - supprimé au profit du décrochage sur un site web
                                 DispatchQueue.main.async {
                                 Task {
                                 let _first = tag.firstIndex(of: "(")
                                 let _last = tag.firstIndex(of: ")")
                                 var port_str = ""
                                 if let _first, let _last {
                                 let first = tag.index(_first, offsetBy: 1)
                                 let last = tag.index(_last, offsetBy: -1)
                                 port_str = String(tag[first...last])
                                 } else {
                                 port_str = tag
                                 }
                                 let port = UInt16(port_str)!
                                 
                                 var message = ""
                                 if let descr = TCPPort2Description[port] {
                                 message = descr
                                 } else {
                                 message = "The TCP port number \(port) has no description."
                                 }
                                 
                                 await master_view_controller.popUp(tag, message, "continue")
                                 }
                                 }
                                 */
                            }
                            
                            if !model.text_udp_ports.isEmpty {
                                HStack {
                                    VStack { Divider() }
                                    Text("UDP ports and associated service names").foregroundColor(.gray.lighter().lighter()).font(.footnote)
                                }
                            }
                            
                            TagCloudView(tags: model.text_udp_ports, master_view_controller: master_view_controller, font: .body) { tag in
                                let _first = tag.firstIndex(of: "(")
                                let _last = tag.firstIndex(of: ")")
                                var port_str = ""
                                if let _first, let _last {
                                    let first = tag.index(_first, offsetBy: 1)
                                    let last = tag.index(_last, offsetBy: -1)
                                    port_str = String(tag[first...last])
                                } else {
                                    port_str = tag
                                }
                                UIApplication.shared.open(URL(string: "https://www.speedguide.net/port.php?port=\(port_str)")!)
                            }
                            
                            if !model.text_addresses.isEmpty {
                                HStack {
                                    VStack { Divider() }
                                    Text("IPv4 and IPv6 addresses").foregroundColor(.gray.lighter().lighter()).font(.footnote)
                                }
                            }

                            TagCloudView(tags: model.text_addresses, master_view_controller: master_view_controller, font: .caption) { tag in
                                DispatchQueue.main.async {
                                    Task {
                                        if master_view_controller.master_ip_view_controller?.viewIfLoaded?.window != nil {
                                            master_view_controller.master_ip_view_controller?.auto_select = tag
                                            master_view_controller.master_ip_view_controller?.viewDidAppear(true)
                                        } else {
                                            master_view_controller.master_ip_view_controller?.auto_select = tag
                                            _ = master_view_controller.navigationController?.popViewController(animated: true)
                                        }
                                    }
                                }
                            }

                            

                            VStack {
                                HStack {
                                    VStack { Divider() }
                                    Text("mDNS/Bonjour services").foregroundColor(.gray.lighter().lighter()).font(.footnote)
                                }

                                Spacer().frame(height: 14)

                            }


                            ForEach(model.text_services, id: \.self) { service_name in
                                HStack(spacing: 2)  {
                                    
                                    VStack(alignment: .leading) {
                                        Spacer()
                                        
                                        Text(service_name + " on port " + model.text_services_port[service_name]!)
                                            .font(.body)
                                            .padding(.leading, 5)
                                            .padding(.trailing, 5)

                                        Text(service_names_descr[service_name] ?? "")
                                            .font(.footnote)
                                            .padding(.leading, 5)
                                            .padding(.trailing, 5)
                                        
                                        Spacer()
                                    }.background(Color(COLORS.toolbar_background))
                                    
                                    VStack {
                                        Spacer()
                                        
                                        /// https://developer.apple.com/bonjour/
                                        // https://developer.apple.com/bonjour/printing-specification/bonjourprinting-1.2.1.pdf
                                        TagCloudView(tags: model.text_services_attr[service_name]!,
                                                     master_view_controller: master_view_controller, font: .caption) { tag in
                                            master_view_controller.popUp("Service key content", tag, "OK")
                                        }
                                        Spacer()
                                    }.background(Color(COLORS.toolbar_background).lighter())
                                }

                                Spacer().frame(height: 2)
                            }

                            
                            
                            
                        }
                        
                        
                    }.padding(10).background(Color(COLORS.right_pannel_scroll_bg)) // VStack
                }//.id(topID)
                .cornerRadius(15).padding(7) // VStack
            }.background(Color(COLORS.right_pannel_bg)) // ScrollView
            //            .popover(isPresented: $showing_popover) { Text("SALUT")}
            
        }
        
        
        
    }
}
