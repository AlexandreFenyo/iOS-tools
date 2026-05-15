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

    // Node is not observable
    var node: Node
    
    @State private var hasChargen: Bool
    @State private var hasSnmp: Bool
    @State private var hasInternet: Bool

    @StateObject var target: SNMPTargetSimple

    @State var ipv4_addresses: [IPv4Address]
    @State var ipv6_addresses: [IPv6Address]

    @State private var new_ipv4 = ""
    @State private var new_ipv6 = ""
    @State private var new_name = ""

    @State private var showAlert = false
    @State private var msgAlert = ""

    init(add_view_controller: AddViewController?, isEdit: Bool, node: Node, target: SNMPTargetSimple, ipv4_addresses: [IPv4Address], ipv6_addresses: [IPv6Address]) {
        self.add_view_controller = add_view_controller
        self.isEdit = isEdit
        self.node = node
        _target = StateObject(wrappedValue: target)
        _ipv4_addresses = State(initialValue: ipv4_addresses)
        _ipv6_addresses = State(initialValue: ipv6_addresses)
        let types = node.getTypes()
        _hasChargen = State(initialValue: types.contains(.chargen))
        _hasSnmp = State(initialValue: types.contains(.snmp))
        _hasInternet = State(initialValue: types.contains(.internet))
    }

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image("Icon")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(20)
                Text(isEdit ? "Edit and persist target" : "Add new persistent target")
                    .font(.headline)
                if isEdit {
                    Text(node.getName())
                }
                
                ScrollView {
                    HStack(spacing: 12) {
                        TypeToggleButton(label: "Chargen", isOn: $hasChargen)
                        TypeToggleButton(label: "SNMP", isOn: $hasSnmp)
                        TypeToggleButton(label: "Internet", isOn: $hasInternet)
                    }
                    .padding()
                    if !isEdit {
                        VStack {
                            HStack {
                                Text("Name")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.leading, 5)
                                    .padding(.trailing, 5)
                                    .padding(.bottom, 5)
                            }
                            HStack {
                                HStack {
                                    TextField("new name", text: $new_name)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .autocorrectionDisabled(true)
                                        .padding(.horizontal, 5)
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
                    }
                    
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
                                TextField("new IPv4 address", text: $new_ipv4)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocorrectionDisabled(true)
                                    .padding(.horizontal, 5)
                                Spacer()
                            }
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .padding(.bottom, 10)
                            HStack {
                                Button(action: {
                                    msgAlert = "\(new_ipv4): must be a private, autoconfig or unicast IPv4 address"
                                    if let foo = IPv4Address(new_ipv4) {
                                        // See tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell for selection algorithm (section 'Multicast IPv4 addresses are not selected')
                                        if foo.isPrivate() || foo.isAutoConfig() || foo.isUnicast() {
                                            ipv4_addresses.append(foo)
                                        } else {
                                            showAlert = true
                                        }
                                    } else {
                                        showAlert = true
                                    }
                                    new_ipv4 = ""
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
                                TextField("new IPv6 address", text: $new_ipv6)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocorrectionDisabled(true)
                                    .padding(.horizontal, 5)
                                Spacer()
                            }
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .padding(.bottom, 10)
                            HStack {
                                Button(action: {
                                    msgAlert = "\(new_ipv6): must be a unicast public, ULA or LLA IPv6 address"
                                    if let foo = IPv6Address(new_ipv6) {
                                        // See tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell for selection algorithm (section 'Multicast IPv6 addresses, unspecified (::/128) and loopback (::1/128) addresses are not selected. Only unicast public, ULA and LLA addresses can be selected.')
                                        if foo.isUnicastPublic() || foo.isULA() || foo.isLLA()  {
                                         ipv6_addresses.append(foo)
                                        } else {
                                            showAlert = true
                                        }
                                    } else {
                                        showAlert = true
                                    }
                                    new_ipv6 = ""
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
                    
                    if hasSnmp {
                        SNMPTargetView(usage: isEdit ? .edit : .add, target: target, isTargetExpanded: Binding<Bool>(get: { true }, set: { _ in }))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled(true)
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                    }
                    
                    HStack {
                        Button(!new_ipv4.isEmpty || !new_ipv6.isEmpty ? "OK (click + to add the IP address)" : !hasChargen && !hasSnmp && !hasInternet ? "OK (select a type)" : isEdit ? ((ipv4_addresses.isEmpty && ipv6_addresses.isEmpty) ? "OK (add an IP address and click +)" : "OK") : (new_name.isEmpty ? "OK (add a name)" : ((ipv4_addresses.isEmpty && ipv6_addresses.isEmpty) ? "OK (add an IP address and click +)" : "OK"))) {
                            // Here, node is a copy of the selected Node
                            // In order to update this displayed node, we need to remove it and add it again. We must not update node before calling removeNode() since it would not be find anymore in the model.
                            // If the model has been updated and this node modified (for instance because we were browsing the network, or because of the receive of a multicast announcement), it will not be removed. Therefore, old properties will be merged with new properties when calling add_view_controller?.master_view_controller!.addNode(node) later.
                            // Therefore, we should forbid the model to be updated when this View is displayed => TO-DO-LIST
                            add_view_controller?.master_view_controller!.removeNode(node)

                            // We only set properties that we want to save.
                            let new_node = node.getCopy()
                            if !new_name.isEmpty { new_node.addName(new_name) }
                            new_node.setV4Addresses(Set<IPv4Address>(ipv4_addresses))
                            new_node.setV6Addresses(Set<IPv6Address>(ipv6_addresses))

                            // Remove TCP port list
                            new_node.setTcpPorts(Set<UInt16>())
                            // Remove UDP port list
                            new_node.setUdpPorts(Set<UInt16>())

                            if hasChargen {
                                new_node.addType(.chargen)
                            }
                            if hasSnmp {
                                new_node.addType(.snmp)
                                new_node.setSNMPTarget(SNMPTarget(target))
                            }
                            if hasInternet {
                                new_node.addType(.internet)
                            }

                            // Let the node be persistant after app restart.
                            DBMaster.shared.saveNode(new_node)
                            add_view_controller?.master_view_controller?.addTrace("Add/Edit node: node saved to persistent storage (\(node.fullDump()))", level: .INFO)
                            
                            // We update properties that we want to be kept in the GUI.
                            for type in node.getTypes() {
                                new_node.addType(type)
                            }
                            new_node.setTcpPorts(node.getTcpPorts())
                            new_node.setUdpPorts(node.getUdpPorts())
  
                            add_view_controller?.master_view_controller!.addNode(new_node)

                            add_view_controller?.dismiss(animated: true)
                        }
                        .disabled((isEdit == false && new_name.isEmpty) || (ipv4_addresses.isEmpty && ipv6_addresses.isEmpty) || (!hasChargen && !hasSnmp && !hasInternet) || !new_ipv4.isEmpty || !new_ipv6.isEmpty)
                        .padding(10)
                        .font(.headline)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(15)

                        Spacer()

                        Button("Cancel") {
                            add_view_controller?.dismiss(animated: true)
                        }
                        .padding(10)
                        .font(.headline)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(15)
                    }
                }
                .cornerRadius(15)
                .padding(10)
                .background(Color.gray.lighter().lighter().lighter().lighter().lighter())
                .cornerRadius(12)

                Spacer()
            }
            .padding(10)
            .alert("Error", isPresented: $showAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(msgAlert)
                    }
        }
    }
}

@MainActor
private struct TypeToggleButton: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                isOn.toggle()
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isOn ? Color.accentColor : Color.gray.opacity(0.3))
                .foregroundColor(isOn ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
