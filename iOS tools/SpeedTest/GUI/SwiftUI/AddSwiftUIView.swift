//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import SpriteKit
import iOSToolsMacros

@MainActor
struct AddSwiftUIView: View {
    weak var add_view_controller: AddViewController?
    var isEdit: Bool
    var node: Node?

    @State private var scope: NodeType = .chargen
    @State private var foo = 0

    @State private var isPermanent = true

    @State private var target_name: String = ""
    @State private var target_ip: String = ""

    @State private var isTargetExpanded = true
    @StateObject private var target = SNMPTarget()

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
                
                if let node {
                    Text(node.getName())
                }
                
                
                
                Text(isEdit ? "Edit target" : "Add new target or new IP to existing target")
                    .foregroundColor(Color(COLORS.leftpannel_ip_text))
                    .padding()
                Spacer()
            }.background(Color(COLORS.toolbar_background))

            Spacer()
            
            VStack {
                Form {
                    Section(header: Text(isEdit ? "Node properties" : "New node properties")) {
                        Picker("Section", selection: $scope) {
//                            Text("iOS device").tag(NodeType.ios).disabled(false)
//                            Text("Chargen Discard").tag(NodeType.chargen)
                            Text("Chargen").tag(NodeType.chargen).disabled(false)
//                            Text("Local gateway").tag(NodeType.gateway)
//                            Text("Internet").tag(NodeType.internet)
                            Text("SNMP").tag(NodeType.snmp)
                            Text("Other host").tag(NodeType.localhost)
                        }.pickerStyle(.segmented)

                        /*
                        Toggle(isOn: $isPermanent) {
                            Text("Add permanently")
                        }
                         */
                        
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

                        /*
                        Button("Resolve target IPv6 from target name") {
                            target_ip = ""
                            Task.detached { @MainActor in
                                let numAddress = await resolveHostname(target_name, false)
                                if isIPv6(numAddress ?? "") { target_ip = numAddress! }
                            }
                        }
                         */
                    }

                    Button("Add this new target") {
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
                        
                        if scope == .snmp {
                            node.setSNMPTarget(target)
                        }
                        
                        add_view_controller?.master_view_controller!.addNode(node)

                        if isPermanent {
                            let base64String: String
                            do {
                                let encoder = JSONEncoder()
                                let jsonData = try encoder.encode(target)
                                base64String = jsonData.base64EncodedString()
                                print(base64String)
                            } catch {
                                #fatalError("Base64/JSON encoding failed")
                                add_view_controller?.dismiss(animated: true)
                                base64String = ""
                            }
                            
                            var config = UserDefaults.standard.stringArray(forKey: "nodes") ?? [ ]
                            let str = target_name + ";" + target_ip
                            if !config.contains(str) {
                                config.append(target_name + ";" + target_ip + ";" + String(scope.rawValue) + ";" + base64String)
                            }
                            UserDefaults.standard.set(config, forKey: "nodes")
                        }

                        add_view_controller?.dismiss(animated: true)
                    }
                    .disabled(target_name == "" || (isIPv4(target_ip) == false && isIPv6(target_ip) == false))
                    
                    Button("Dismiss") {
                        /* debug rapide de addNode()
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
                
                if scope == .snmp {
                    SNMPTargetView(target: target, isTargetExpanded: $isTargetExpanded, adding_host: true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 15)
                        .padding(.trailing, 15)
                }
               
            }.cornerRadius(15).padding(10)
          
        }.background(Color(COLORS.right_pannel_bg))
    }
}
