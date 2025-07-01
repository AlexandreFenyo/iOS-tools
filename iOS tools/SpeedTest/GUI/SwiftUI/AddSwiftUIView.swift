//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

// la lecture et sauvegarde sur disque dans Model.swift : UserDefaults.standard.stringArray(forKey: "nodes") ?? [ ]

import SwiftUI
import SpriteKit
import iOSToolsMacros

@MainActor
struct AddSwiftUIView: View {
    weak var add_view_controller: AddViewController?
    
    var isEdit: Bool
    var node: Node
    
    @State private var scope: NodeType = .chargen
    @State private var new_scope: NodeType = .chargen
    
    @StateObject private var target = SNMPTarget()
    
    @State var ipv4_addresses: [IPv4Address]
    @State var ipv6_addresses: [IPv6Address]

    @State private var new_ip = ""

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
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image("Icon")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(20)
                Text(isEdit ? "Edit target" : "Add new target")
                    .font(.headline)
                if isEdit {
                    Text(node.getName())
                }
                
                ScrollView {
                    Picker("Section", selection: $scope) {
                        Text("Chargen").tag(NodeType.chargen).disabled(false)
                        Text("SNMP").tag(NodeType.snmp)
                        Text("Other host").tag(NodeType.localhost)
                    }.pickerStyle(.segmented)
                    
                        .onChange(of: scope) { newValue in
                            withAnimation(Animation.easeInOut(duration: 0.5)) {
                                new_scope = newValue
                            }
                        }
                        .padding()
                    
                    VStack {
                        HStack {
                            Text("IPv4 addresses")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.leading, 5)
                                .padding(.trailing, 5)
                                .padding(.bottom, 5)
                            
                            Spacer()
                        }
                        ForEach (ipv4_addresses, id: \.self) { addr in
                            HStack {
                                HStack {
                                    Text(addr.description)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.gray.darker())
                                        .padding(.leading, 5)
                                        .padding(.trailing, 5)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 5)
                                .padding(.trailing, 5)
                                .padding(.bottom, 5)

                                HStack {
                                    Button(action: {
                                        withAnimation(Animation.easeInOut(duration: 0.5)) {
                                            if let index = ipv4_addresses.firstIndex(of: addr) {
                                                ipv4_addresses.remove(at: index)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                }
                                .padding(.leading, 5)
                                .padding(.trailing, 5)
                                .padding(.bottom, 5)

                            }.background(.red.opacity(0.1))
                        }
                        HStack {
                            HStack {
                                TextField("new IPv4 address", text: $new_ip)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 5)
                                Spacer()
                            }
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .padding(.bottom, 10)
                            HStack {
                                Button(action: {
                                    if let foo = IPv4Address(new_ip) {
                                        ipv4_addresses.append(foo)
                                    }
                                    new_ip = ""
                                }) {
                                    Image(systemName: "plus")
                                }
                            }
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .padding(.bottom, 10)
                        }
                        
                    }
                    .background(Color(COLORS.toolbar_background)).opacity(0.9)
                    .cornerRadius(10)
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    
                    VStack {
                        HStack {
                            Text("IPv6 addresses")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.leading, 5)
                                .padding(.trailing, 5)
                                .padding(.bottom, 5)
                            
                            Spacer()
                        }
                        ForEach (ipv6_addresses, id: \.self) { addr in
                            HStack {
                                HStack {
                                    Text(addr.description)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.gray.darker())
                                        .padding(.leading, 5)
                                        .padding(.trailing, 5)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 5)
                                .padding(.trailing, 5)
                                .padding(.bottom, 5)

                                HStack {
                                    Button(action: {
                                        withAnimation(Animation.easeInOut(duration: 0.5)) {
                                            if let index = ipv6_addresses.firstIndex(of: addr) {
                                                ipv6_addresses.remove(at: index)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                }
                                .padding(.leading, 5)
                                .padding(.trailing, 5)
                                .padding(.bottom, 5)

                            }.background(.red.opacity(0.1))
                        }
                        HStack {
                            HStack {
                                TextField("new IPv6 address", text: $new_ip)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 5)
                                Spacer()
                            }
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .padding(.bottom, 10)
                            HStack {
                                Button(action: {
                                    if let foo = IPv6Address(new_ip) {
                                        ipv6_addresses.append(foo)
                                    }
                                    new_ip = ""
                                }) {
                                    Image(systemName: "plus")
                                }
                            }
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .padding(.bottom, 10)
                        }
                        
                    }
                    .background(Color(COLORS.toolbar_background)).opacity(0.9)
                    .cornerRadius(10)
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    
                    if new_scope == .snmp {
                        SNMPTargetView(target: target, isTargetExpanded: Binding<Bool>(get: { true }, set: { _ in }), adding_host: true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                    }
                    
                }
                .cornerRadius(15)
                .padding(10)
                .background(Color.gray.lighter().lighter().lighter().lighter().lighter())
                .cornerRadius(12)
                Spacer()
                
                HStack {
                    Button("OK") {
                        node.addV4Address(IPv4Address("2.3.5.6")!)
                        add_view_controller?.master_view_controller?.reloadData()
                        add_view_controller?.dismiss(animated: true)
                    }
                    .font(.headline)
                    .cornerRadius(15).padding(10)
                    .padding()
                    .background(Color.gray.lighter().lighter().lighter().lighter().lighter())
                    .cornerRadius(12)
                    Spacer()
                    Button("Cancel") {
                        add_view_controller?.dismiss(animated: true)
                    }
                    .font(.headline)
                    .cornerRadius(15).padding(10)
                    .padding()
                    .background(Color.gray.lighter().lighter().lighter().lighter().lighter())
                    .cornerRadius(12)
                }
            }
            .padding(10)
        }
    }
}
