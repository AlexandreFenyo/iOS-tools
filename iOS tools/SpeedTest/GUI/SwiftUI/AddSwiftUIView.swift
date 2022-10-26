//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

public class AddViewModel : ObservableObject {
    static let shared = DetailViewModel()
    
    @Published private(set) var family: Int32? = nil
    @Published private(set) var address: IPAddress? = nil
    @Published private(set) var v4address: IPv4Address? = nil
    @Published private(set) var v6address: IPv6Address? = nil
    @Published private(set) var address_str: String? = nil
    @Published private(set) var buttons_enabled = false
    @Published private(set) var stop_button_enabled = false
    @Published private(set) var text_addresses: [String] = [String]()
    @Published private(set) var text_names: [String] = [String]()
    @Published private(set) var text_ports: [String] = [String]()
    
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
        text_ports.removeAll()
        family = nil
        address = nil
        v4address = nil
        v6address = nil
        address_str = nil
    }
    
    internal func updateDetails(_ node: Node, _ address: IPAddress, _ buttons_enabled: Bool) {
        text_addresses = node.v4_addresses.compactMap { $0.toNumericString() ?? nil } + node.v6_addresses.compactMap { $0.toNumericString() ?? nil }
        text_names = node.dns_names.map { $0.toString() }
        text_ports = node.tcp_ports.map { TCPPort2Service[$0] != nil ? (TCPPort2Service[$0]!.uppercased() + " (\($0))") : "\($0)" }
        
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
struct AddSwiftUIView: View {
    //    public let view: UIView
    //    public let master_view_controller: MasterViewController
    //    @ObservedObject var model = DetailViewModel.shared
    let add_view_controller: AddViewController

    /*
    enum NodeSection {
        case ios_devices
        case chargen_discard_devices
        case local_gateway
        case internet
        case other
    }*/
    @State private var scope: NodeType = .localhost
    
    @State private var isPermanent = true
//    @State private var need_resolve = true

    @State private var target_name: String = ""
    @State private var target_ip: String = ""
    
    private func validateHostname(_ name: String) -> String? {
        var new_name = name.lowercased()
        var new_name2 = ""
        for c in new_name.unicodeScalars {
            if CharacterSet.letters.contains(c) || CharacterSet.decimalDigits.contains(c) || c.escaped(asASCII: true) == "." {
                new_name2.append(String(c))
            }
        }
        new_name = new_name2
        return new_name
    }

    private func validateIP(_ name: String) -> String? {
        let new_name = name.lowercased()
        var new_name2 = ""
        for c in new_name {
            if "abcdef0123456789:.".contains(c) {
                new_name2.append(c)
            }
        }
        return new_name2
    }

    var body: some View {
        /* SANS FORM :
         ScrollView {
         VStack {
         }
         }.background(Color(COLORS.right_pannel_scroll_bg))
         .cornerRadius(15).padding(10)
         }.background(Color(COLORS.right_pannel_bg))
         */
        
        VStack {
            HStack {
                Spacer()
                Text("Add New Node")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                Spacer()
            }.background(Color(COLORS.toolbar_background))
            
            VStack {
                Form {
                    Section(header: Text("New node properties")) {
                        Picker("Section", selection: $scope) {
                            Text("IOS devices").tag(NodeType.ios)
                            Text("Chargen Discard services").tag(NodeType.chargen)
                            Text("Local gateway").tag(NodeType.gateway)
                            Text("Internet").tag(NodeType.internet)
                            Text("Other hosts").tag(NodeType.localhost)
                        }
                        
                        Toggle(isOn: $isPermanent) {
                            Text("Add permanently")
                        }
                        
                        TextField("Target name", text: $target_name)
                            .onChange(of: target_name) { new_value in
                                let new_target_name = validateHostname(target_name)
                                if let new_target_name {
                                    target_name = new_target_name
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)

                        /*
                        Toggle(isOn: $need_resolve) {
                            Text("Resolve host name")
                        }
                         */
                        
                        TextField("Target IP", text: $target_ip)
                            .onChange(of: target_ip) { new_value in
                                let new_target_ip = validateIP(target_ip)
                                if let new_target_ip {
                                    target_ip = new_target_ip
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    
                    Button("Add this new node") {
                        DispatchQueue.main.async {
                            let node = Node()
                            node.dns_names.insert(DomainName(target_name)!)
                            if isIPv4(target_ip) {
                                node.v4_addresses.insert(IPv4Address(target_ip)!)
                            } else if isIPv6(target_ip) {
                                node.v6_addresses.insert(IPv6Address(target_ip)!)
                            }
                            if scope != .localhost {
                                node.types = [ scope ]
                            }
                            add_view_controller.master_view_controller!.addNode(node)
                        }

                        if isPermanent {
                            var config = UserDefaults.standard.stringArray(forKey: "nodes") ?? [ ]
                            let str = target_name + ";" + target_ip
                            if Array().firstIndex(of: str) == nil {
                                config.append(target_name + ";" + target_ip)
                            }
                            UserDefaults.standard.set(config, forKey: "nodes")
                        }

                        add_view_controller.dismiss(animated: true)
                    }
                    .disabled(target_name == "" || (isIPv4(target_ip) == false && isIPv6(target_ip) == false))
                    
                    Button("Dismiss") {
                        /* debug rapide de addNode()
                        DispatchQueue.main.async {
                            let node = Node()
                            node.dns_names.insert(DomainName("a string")!)
                            node.v4_addresses.insert(IPv4Address("55.33.22.11")!)
                            if scope != .localhost {
                                node.types = [ scope ]
                            }
                            add_view_controller.master_view_controller!.addNode(node)
                        }
                         */

                        add_view_controller.dismiss(animated: true)
                    }
                }
            }.cornerRadius(15).padding(10)
            
        }.background(Color(COLORS.right_pannel_bg))
    }
}
