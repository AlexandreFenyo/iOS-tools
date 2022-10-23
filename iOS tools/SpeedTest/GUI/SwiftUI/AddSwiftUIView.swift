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
    public let view: UIView
//    public let master_view_controller: MasterViewController
    
    @ObservedObject var model = DetailViewModel.shared
    
    var body: some View {
        VStack {
            Spacer()
            Text("SALUT")
        }.background(.red)
    }
}
