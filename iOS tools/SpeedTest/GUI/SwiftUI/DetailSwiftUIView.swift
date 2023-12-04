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
                self.item(for: tag, width: g.size.width)
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
    private func item(for text: String, width: CGFloat) -> some View {
        Text(text.prefix(width < 400 ? 20 : 40) + (text.count > (width < 400 ? 20 : 40) ? "..." : ""))
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
    @Published private(set) var animated_width_map: CGFloat = 0

    @Published private(set) var text_current_measurement_unit: String = ""
    @Published private(set) var measurement_value_prev: Double = 0
    @Published private(set) var measurement_value_next: Double = 0
    @Published private(set) var average_last_update = Date()

    public func setCurrentMeasurementUnit(_ str: String) {
        text_current_measurement_unit = str
        if (str.isEmpty) {
            measurement_value_prev = 0
            measurement_value_next = 0
        }
    }

    public func setMeasurementValue(_ val: Double) {
        measurement_value_prev = measurement_value_next
        measurement_value_next = val
        average_last_update = Date()
    }

    public func setButtonMapHiddenState(_ state: Bool) {
        animated_width_map = state ? 0 : 200
    }
    
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
        text_addresses = node.getV4Addresses().compactMap { $0.toNumericString() ?? nil } + node.getV6Addresses().compactMap { $0.toNumericString() ?? nil }
        
        let _text_names = node.getNames().map { $0 } + node.getMcastDnsNames().map { $0.toString() } + node.getDnsNames().map { $0.toString() }
        for name in _text_names {
            // Do not display duplicated names
            if !text_names.contains(name) {
                text_names.insert(name, at: text_names.endIndex)
            }
        }
        
        text_tcp_ports = node.getTcpPorts().map { TCPPort2Service[$0] != nil ? (TCPPort2Service[$0]!.uppercased() + " (\($0))") : "\($0)" }
        text_udp_ports = node.getUdpPorts().map { TCPPort2Service[$0] != nil ? (TCPPort2Service[$0]!.uppercased() + " (\($0))") : "\($0)" }
        text_services = node.getServices().map({ $0.name })
        
        _ = node.getServices().map({ $0 }).map { svc in
            text_services_port[svc.name] = svc.port
            text_services_attr[svc.name] = svc.attr.map({ (key: String, value: String) in
                value == "THIS_IS_NOT_A_VALUE_AFAFAF" ? "\(key)" : "\(key): \(value)"
            })
        }
        
        var interfaces = [""]
        for addr in node.getV6Addresses() {
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
    @State var animated_width_stop: CGFloat = 0

    let timer_set_speed = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var speed: Double = 0

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var delay = [/*"10 sec",*/ "5 sec", "4 sec", "3 sec", "2 sec", "1 sec", "500 ms", "250 ms", "100 ms"]
    var _delay : [String: useconds_t] = [/*"10 sec": 10000000,*/ "5 sec": 5000000, "4 sec": 4000000, "3 sec": 3000000, "2 sec": 2000000, "1 sec": 1000000, "500 ms": 500000, "250 ms": 250000, "100 ms": 100000]
    @State private var selected_delay = "1 sec"
    
    var body: some View {
        HStack {
            EmptyView().padding(0).onReceive(timer_set_speed) { _ in // 100 Hz
                // Manage measurements
                let interval_speed = Double(Date().timeIntervalSince(model.average_last_update))
                let UPDATE_SPEED_DELAY: Double = 1.0
                if interval_speed < UPDATE_SPEED_DELAY {
                    speed = model.measurement_value_prev * (UPDATE_SPEED_DELAY - interval_speed) / UPDATE_SPEED_DELAY + model.measurement_value_next * interval_speed / UPDATE_SPEED_DELAY
                } else {
                    speed = model.measurement_value_next
                }
            }

            ZStack(alignment: .top) {
                Text(model.address_str == nil ? NSLocalizedString("none", comment: "none") : model.address_str!).foregroundColor(Color(COLORS.chart_scale))

                HStack(spacing: 0) {
                    Menu {
                        Picker("Please choose a delay", selection: $selected_delay) {
                            ForEach(delay, id: \.self) { delay in
                                Text(delay).font(.caption)
                            }
                        }.tint(Color(COLORS.chart_scale))
                            .onChange(of: selected_delay) { new_delay in
                                Task {
                                    await master_view_controller.setDelay(_delay[new_delay]!)
                                }
                            }
                        
                    } label: {
                        Label(selected_delay, systemImage: "clock")
                            .foregroundColor(Color(COLORS.chart_scale)).opacity(0.8)
                    }
                    
                    
                    Spacer()
                    if (model.address_str != nil && !model.text_current_measurement_unit.isEmpty) {
                        Text("\(Int(speed)) \(model.text_current_measurement_unit)")
                            .foregroundColor(Color(COLORS.chart_scale)).opacity(0.8)
                    }
                }
            }
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
                                        model.setButtonMapHiddenState(false)
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
                                        model.setButtonMapHiddenState(false)
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
                                    animated_width_stop = 200
                                }
                                .onDisappear {
                                    animated_width_stop = 0
                                }
                                .accentColor(Color(COLORS.standard_background))
                                .frame(maxWidth: animated_width_stop).disabled(model.buttons_enabled || model.address_str == nil)
                                .animation(.easeOut(duration: 1.0), value: animated_width_stop)
                            }

                            if horizontalSizeClass == .compact {
                                Button {

                                    master_view_controller.launch_heatmap()

                                } label: {
                                    VStack {
                                        Image(systemName: "map")
                                            .resizable(resizingMode: .stretch).frame(width: 30 * model.animated_width_map / 200, height: 30)
                                        Text("heatmap").font(.footnote)
                                    }
                                }
                                .accentColor(Color(COLORS.standard_background))
                                .frame(maxWidth: model.animated_width_map, maxHeight: model.animated_width_map == 0 ? 0 : 200, alignment: .topLeading)
                            }
                            
                            if horizontalSizeClass != .compact {
                                Button {
                                    if let url = URL(string: model.family == AF_INET ? "http://\(model.address_str!)" : "http://[\(model.address_str!)]") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    VStack {
                                        Image(systemName: "globe").resizable().frame(width: 30, height: 30)
                                        Text("web access").font(.footnote)
                                    }
                                }
                                .accentColor(Color(COLORS.standard_background)).disabled(model.address_str == nil || model.address_str?.contains("%") == true || model.text_tcp_ports.contains("HTTP (80)") == false)
                                .frame(maxWidth: 200)
                                
                                Button {
                                    if let url = URL(string: model.family == AF_INET ? "https://\(model.address_str!)" : "https://[\(model.address_str!)]") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    VStack {
                                        Image(systemName: "key.icloud").resizable().frame(width: 40, height: 30)
                                        Text("SSL/TLS").font(.footnote)
                                    }
                                }
                                .accentColor(Color(COLORS.standard_background)).disabled(model.address_str == nil || model.address_str?.contains("%") == true || model.text_tcp_ports.contains("HTTPS (443)") == false)
                                .frame(maxWidth: 200)
                            }
                        }
//                        .animation(.easeOut(duration: 1.0), value: model.animated_width_map)
//                        .background(.red)
                        
                        VStack {
                            if horizontalSizeClass == .compact && (((model.address_str == nil || model.address_str?.contains("%") == true || model.text_tcp_ports.contains("HTTP (80)") == false)) == false || (model.address_str == nil || model.address_str?.contains("%") == true || model.text_tcp_ports.contains("HTTPS (443)") == false) == false) {
                                
                                HStack {
                                    Button {
                                        if let url = URL(string: model.family == AF_INET ? "http://\(model.address_str!)" : "http://[\(model.address_str!)]") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        VStack {
                                            Image(systemName: "globe").resizable().frame(width: 30, height: 30)
                                            Text("web access").font(.footnote)
                                        }
                                    }
                                    .accentColor(Color(COLORS.standard_background)).disabled(model.address_str == nil || model.address_str?.contains("%") == true || model.text_tcp_ports.contains("HTTP (80)") == false)
                                    .frame(maxWidth: 200)
                                    
                                    Button {
                                        if let url = URL(string: model.family == AF_INET ? "https://\(model.address_str!)" : "https://[\(model.address_str!)]") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        VStack {
                                            Image(systemName: "key.icloud").resizable().frame(width: 40, height: 30)
                                            Text("SSL/TLS").font(.footnote)
                                        }
                                    }
                                    .accentColor(Color(COLORS.standard_background)).disabled(model.address_str == nil || model.address_str?.contains("%") == true || model.text_tcp_ports.contains("HTTPS (443)") == false)
                                    .frame(maxWidth: 200)
                                }
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
                                    master_view_controller.popUpHelp(.no_dns, "This hostname does not have a public DNS record. Select a host name with public DNS records to get their values.") {
                                        master_view_controller.popUp(NSLocalizedString("Hostname", comment: "Hostname"), tag, "OK")
                                    }
                                    return
                                }
                                master_view_controller.popUp(NSLocalizedString("Hostname", comment: "Hostname"), tag, "OK")
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
                            
                            if !model.text_services.isEmpty {
                                VStack {
                                    HStack {
                                        VStack { Divider() }
                                        Text("mDNS/Bonjour services").foregroundColor(.gray.lighter().lighter()).font(.footnote)
                                    }
                                    
                                    Spacer().frame(height: 14)
                                    
                                }
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
                                            master_view_controller.popUp(NSLocalizedString("Service key content", comment: "Service key content"), tag, "OK")
                                        }
                                        Spacer()
                                    }.background(Color(COLORS.toolbar_background).lighter())
                                }
                                
                                Spacer().frame(height: 2)
                            }
                            
                        }
                        
                    }.padding(10).background(Color(COLORS.right_pannel_scroll_bg)) // VStack
                        .animation(.easeOut(duration: 1.0), value: model.animated_width_map)

                }//.id(topID)
                .cornerRadius(15).padding(7) // VStack

                    /* pour tester Interman dans la vue principale
                     Text("salut")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.red)
                
                     IntermanSwiftUIView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: 500)
                    .background(.blue)
                     */
                
            }.background(Color(COLORS.right_pannel_bg)) // ScrollView
            //            .popover(isPresented: $showing_popover) { Text("SALUT")}
        }
    }
}

