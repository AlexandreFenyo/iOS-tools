//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit

@MainActor
struct AddSwiftUIView: View {
    weak var add_view_controller: AddViewController?

    @State private var scope: NodeType = .internet
    @State private var foo = 0

    @State private var isPermanent = true

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
                Text("Add new target or new IP to existing target")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                Spacer()
            }.background(Color(COLORS.toolbar_background))
            
            VStack {
                Form {
                    Section(header: Text("New node properties")) {
                        Picker("Section", selection: $scope) {
                            Text("iOS device").tag(NodeType.ios).disabled(false)
                            Text("Chargen Discard").tag(NodeType.chargen)
                            Text("Local gateway").tag(NodeType.gateway)
                            Text("Internet").tag(NodeType.internet)
                            Text("Other host").tag(NodeType.localhost)
                        }.pickerStyle(.segmented)

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
                        
                        TextField("Target IP", text: $target_ip)
                            .onChange(of: target_ip) { new_value in
                                let new_target_ip = validateIP(target_ip)
                                if let new_target_ip {
                                    target_ip = new_target_ip
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)

                        Button("Resolve target IPv4 from target name") {
                            target_ip = ""
                            Task.detached { @MainActor in
                                let numAddress = await resolveHostname(target_name, true)
                                if isIPv4(numAddress ?? "") { target_ip = numAddress! }
                            }
                        }

                        Button("Resolve target IPv6 from target name") {
                            target_ip = ""
                            Task.detached { @MainActor in
                                let numAddress = await resolveHostname(target_name, false)
                                if isIPv6(numAddress ?? "") { target_ip = numAddress! }
                            }
                        }
                    }

                    Button("Add this new target") {
                        DispatchQueue.main.async {
                            let node = Node()
                            node.addDnsName(DomainName(target_name)!)
                            if isIPv4(target_ip) {
                                if !node.getV4Addresses().contains(IPv4Address(target_ip)!) {
                                    node.addV4Address(IPv4Address(target_ip)!)
                                }
                            } else if isIPv6(target_ip) {
                                if !node.getV6Addresses().contains(IPv6Address(target_ip)!) {
                                    node.addV6Address(IPv6Address(target_ip)!)
                                }
                            }
                            if scope != .localhost {
                                node.setTypes([ scope ])
                            }
                            add_view_controller?.master_view_controller!.addNode(node)
                        }

                        if isPermanent {
                            var config = UserDefaults.standard.stringArray(forKey: "nodes") ?? [ ]
                            let str = target_name + ";" + target_ip
                            if Array().firstIndex(of: str) == nil {
                                config.append(target_name + ";" + target_ip + ";" + String(scope.rawValue))
                            }
                            UserDefaults.standard.set(config, forKey: "nodes")
                        }

                        add_view_controller?.dismiss(animated: true)
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
                         ...
                         */

                        add_view_controller?.dismiss(animated: true)
                    }
                }
            }.cornerRadius(15).padding(10)
          
        }.background(Color(COLORS.right_pannel_bg))
    }
}
