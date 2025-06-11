//
//  ContentView.swift
//  SnmpGui
//
//  Created by Alexandre Fenyo on 13/04/2025.
//

import SwiftUI
import WebKit
import iOSToolsMacros

let debug_snmp = true
let disable_request_reviews = true

// https://developer.apple.com/documentation/swiftui/outlinegroup
// fenyo@mac ~ % snmpwalk -v2c -OT -OX -c public 192.168.0.254 > /tmp/snmpwalk.res

extension String {
    func ranges(of searchString: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var startIndex = self.startIndex
        
        while startIndex < self.endIndex,
              let range = self.range(of: searchString, options: .caseInsensitive, range: startIndex..<self.endIndex) {
            ranges.append(range)
            startIndex = range.upperBound
        }
        return ranges
    }
}

struct HighlightedTextView: View {
    let fullText: String
    let highlight: String
    let highlightColor: Color = .blue
    let highlightBackgroundColor: Color = .yellow

    init(_ fullText: String, highlight: String) {
        self.fullText = fullText
        self.highlight = highlight
    }

    var body: some View {
        let lowercasedFullText = fullText.lowercased()
        let lowercasedHighlight = highlight.lowercased()
        
        let ranges = lowercasedFullText.ranges(of: lowercasedHighlight)
        
        var highlightedText = Text("")
        var currentIndex = fullText.startIndex
        
        for range in ranges {
            let beforeRange = fullText[currentIndex..<range.lowerBound]
            let highlightedRange = fullText[range]

            var foo = AttributedString(String(highlightedRange))
            foo.backgroundColor = highlightBackgroundColor
            
            highlightedText = highlightedText
                + Text(String(beforeRange))
                + Text(foo).foregroundColor(highlightColor)

            currentIndex = range.upperBound
        }
        
        highlightedText = highlightedText + Text(String(fullText[currentIndex...]))
        
        return highlightedText
    }
}

struct OIDTreeView: View {
    @ObservedObject var node: OIDNodeDisplayable
    @Binding var highlight: String

    var body: some View {
        if node.children == nil || node.children?.isEmpty == true {
            // no child
            HStack(alignment: .top) {
                VStack {
                    if node.children_backup?.isEmpty == false {
                        Image(systemName: "folder")
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "doc.text")
                            .padding(.trailing, 6)
                            .foregroundColor(.blue)
                    }
                }
                VStack {
                    HStack(alignment: .top) {
                        if node.children_backup?.isEmpty == false {
                            HighlightedTextView(node.getDisplayValAndSubValues(), highlight: highlight)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            HighlightedTextView(node.subnodes.last?.val ?? "", highlight: highlight)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.trailing)
                        } else {
                            HighlightedTextView(node.getDisplayValAndSubValues(), highlight: highlight)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            HighlightedTextView(node.subnodes.last?.val ?? "", highlight: highlight)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .onTapGesture {
                print(node.line)
            }
        }
        else {
            // children exist
            DisclosureGroup(isExpanded: $node.isExpanded, content: {
                if let children = node.children {
                    ForEach(children) { child in
                        OIDTreeView(node: child, highlight: $highlight)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.orange)
                    HighlightedTextView(node.getDisplayValAndSubValues(), highlight: highlight)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct SNMPTargetView: View {
    @ObservedObject var target: SNMPTarget
    @Binding var isTargetExpanded: Bool

    enum SNMPProto: String, CaseIterable, Identifiable {
        case SNMPv1, SNMPv2c, SNMPv3
        var id: Self { self }
    }
    @State private var SNMP_protocol = SNMPProto.SNMPv2c

    enum SNMPTransportProto: String, CaseIterable, Identifiable {
        case TCP, UDP
        var id: Self { self }
    }
    @State private var SNMP_transport_protocol = SNMPTransportProto.TCP

    enum SNMPNetworkProto: String, CaseIterable, Identifiable {
        case IPv4, IPv6
        var id: Self { self }
    }
    @State private var SNMP_network_protocol = SNMPNetworkProto.IPv4

    enum SNMPSecLevel: String, CaseIterable, Identifiable {
        case noAuthNoPriv, authNoPriv, authPriv
        var id: Self { self }
    }
    @State private var SNMP_sec_level = SNMPSecLevel.authNoPriv

    @State private var SNMP_auth_secret = ""
    @State private var SNMP_priv_secret = ""

    @State private var SNMP_community = ""

    enum V3AuthProto {
        case MD5
        case SHA1
    }
    @State private var v3_auth_proto = V3AuthProto.MD5

    enum V3PrivacyProto {
        case DES
        case AES
    }
    @State private var v3_privacy_proto = V3PrivacyProto.DES

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = NSNumber(value: UInt16.max)
        return formatter
    }

    var body: some View {
        VStack {
            HStack {
                Text("target (SNMP agent)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)

                Spacer()

                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.5)) {
                        isTargetExpanded.toggle()
                    }
                }, label: {
                    Image(systemName: isTargetExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                })
            }
            
            if isTargetExpanded {
                TextField("hostname", text: $target.host)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                
                HStack {
                    TextField("port", value: $target.port, formatter: numberFormatter).keyboardType(.numberPad)
                        .font(.subheadline)
                        .onChange(of: target.port) { newValue in
                            // Filtrer les caractères non numériques
                            let filtered = String(newValue).filter { "0123456789".contains($0) }
                            if filtered != String(newValue) {
                                target.port = UInt16(filtered) ?? 0
                            }
                        }
                        .padding(.horizontal, 10)
                    
                    Picker("SNMP protocol", selection: $SNMP_protocol) {
                        Text("SNMPv1").tag(SNMPProto.SNMPv1)
                        Text("SNMPv2c").tag(SNMPProto.SNMPv2c)
                        Text("SNMPv3").tag(SNMPProto.SNMPv3)
                    }.onChange(of: SNMP_protocol) { newValue in
                        switch newValue {
                        case .SNMPv1:
                            target.credentials = .v1(SNMP_community)

                        case .SNMPv2c:
                            target.credentials = .v2c(SNMP_community)

                        case .SNMPv3:
                            let v3cred = SNMPTarget.SNMPv3Credentials()
                            switch SNMP_sec_level {
                            case .noAuthNoPriv:
                                v3cred.security_level = .noAuthNoPriv
                            case .authNoPriv:
                                v3cred.security_level = .authNoPriv(v3_auth_proto == .MD5 ? .MD5(SNMP_auth_secret) : .SHA1(SNMP_auth_secret))
                            case .authPriv:
                                v3cred.security_level = .authPriv(v3_auth_proto == .MD5 ? .MD5(SNMP_auth_secret) : .SHA1(SNMP_auth_secret), v3_privacy_proto == .DES ? .DES(SNMP_priv_secret) : .AES(SNMP_priv_secret))
                            }
                            target.credentials = .v3(v3cred)
                        }
                    }
                }

                HStack {
                    if SNMP_protocol != .SNMPv3 {
                        TextField("community", text: $SNMP_community)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                            .onChange(of: SNMP_community) { newValue in
                                switch target.credentials {
                                    case .v1(_):
                                    target.credentials = .v1(newValue)
                                    case .v2c(_):
                                    target.credentials = .v2c(newValue)
                                case .v3(_):
                                    break
                                }
                            }
                    } else {
                        Picker("SNMP sec level", selection: $SNMP_sec_level) {
                            Text("NoAuth/NoPriv").tag(SNMPSecLevel.noAuthNoPriv)
                            Text("Auth/NoPriv").tag(SNMPSecLevel.authNoPriv)
                            Text("Auth/Priv").tag(SNMPSecLevel.authPriv)
                        }.onChange(of: SNMP_sec_level) { newValue in
                            let v3cred = SNMPTarget.SNMPv3Credentials()
                            switch newValue {
                            case .noAuthNoPriv:
                                v3cred.security_level = .noAuthNoPriv
                            case .authNoPriv:
                                v3cred.security_level = .authNoPriv(v3_auth_proto == .MD5 ? .MD5(SNMP_auth_secret) : .SHA1(SNMP_auth_secret))
                            case .authPriv:
                                v3cred.security_level = .authPriv(v3_auth_proto == .MD5 ? .MD5(SNMP_auth_secret) : .SHA1(SNMP_auth_secret), v3_privacy_proto == .DES ? .DES(SNMP_priv_secret) : .AES(SNMP_priv_secret))
                            }
                            target.credentials = .v3(v3cred)
                        }
                        
                        Spacer()
                    }

                    Picker("SNMP transport protocol", selection: $SNMP_transport_protocol) {
                        Text("UDP").tag(SNMPTransportProto.UDP)
                        Text("TCP").tag(SNMPTransportProto.TCP)
                    }.onChange(of: SNMP_transport_protocol) { newValue in
                        target.ip_proto = newValue == .UDP ? .UDP : .TCP
                    }

                    Picker("SNMP network protocol", selection: $SNMP_network_protocol) {
                        Text("IPv4").tag(SNMPNetworkProto.IPv4)
                        Text("IPv6").tag(SNMPNetworkProto.IPv6)
                    }.onChange(of: SNMP_network_protocol) { newValue in
                        target.ip_version = newValue == .IPv4 ? .IPv4 : .IPv6
                    }
               }

                if SNMP_protocol == .SNMPv3 && SNMP_sec_level == .authNoPriv {
                    HStack {
                        TextField("authentication secret", text: $SNMP_auth_secret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                            .onChange(of: SNMP_auth_secret) { newValue in
                                let v3cred = SNMPTarget.SNMPv3Credentials()
                                switch SNMP_sec_level {
                                case .noAuthNoPriv:
                                    v3cred.security_level = .noAuthNoPriv
                                case .authNoPriv:
                                    v3cred.security_level = .authNoPriv(v3_auth_proto == .MD5 ? .MD5(newValue) : .SHA1(newValue))
                                case .authPriv:
                                    v3cred.security_level = .authPriv(v3_auth_proto == .MD5 ? .MD5(newValue) : .SHA1(newValue), v3_privacy_proto == .DES ? .DES(SNMP_priv_secret) : .AES(SNMP_priv_secret))
                                }
                                target.credentials = .v3(v3cred)
                            }
                        
                        Picker("v3 auth proto", selection: $v3_auth_proto) {
                            Text("MD5").tag(V3AuthProto.MD5)
                            Text("SHA1").tag(V3AuthProto.SHA1)
                        }
                        .padding(.bottom, 10)
                        .onChange(of: v3_auth_proto) { newValue in
                            let v3cred = SNMPTarget.SNMPv3Credentials()
                            switch SNMP_sec_level {
                            case .noAuthNoPriv:
                                v3cred.security_level = .noAuthNoPriv
                            case .authNoPriv:
                                v3cred.security_level = .authNoPriv(newValue == .MD5 ? .MD5(SNMP_auth_secret) : .SHA1(SNMP_auth_secret))
                            case .authPriv:
                                v3cred.security_level = .authPriv(newValue == .MD5 ? .MD5(SNMP_auth_secret) : .SHA1(SNMP_auth_secret), v3_privacy_proto == .DES ? .DES(SNMP_priv_secret) : .AES(SNMP_priv_secret))
                            }
                            target.credentials = .v3(v3cred)
                        }
                    }
                }

                if SNMP_protocol == .SNMPv3 && SNMP_sec_level == .authPriv {
                    HStack {
                        TextField("authentication secret", text: $SNMP_auth_secret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                        CONTIUNUER ICI
                        
                        
                        Picker("v3 auth algo", selection: $v3_auth_proto) {
                            Text("MD5").tag(V3AuthProto.MD5)
                            Text("SHA1").tag(V3AuthProto.SHA1)
                        }
                        .padding(.bottom, 10)
                        .onChange(of: SNMP_auth_secret) { newValue in
                            let v3cred = SNMPTarget.SNMPv3Credentials()
                            switch SNMP_sec_level {
                            case .noAuthNoPriv:
                                v3cred.security_level = .noAuthNoPriv
                            case .authNoPriv:
                                v3cred.security_level = .authNoPriv(v3_auth_proto == .MD5 ? .MD5(newValue) : .SHA1(newValue))
                            case .authPriv:
                                v3cred.security_level = .authPriv(v3_auth_proto == .MD5 ? .MD5(newValue) : .SHA1(newValue), v3_privacy_proto == .DES ? .DES(SNMP_priv_secret) : .AES(SNMP_priv_secret))
                            }
                            target.credentials = .v3(v3cred)
                        }
                    }

                    HStack {
                        TextField("privacy secret", text: $SNMP_priv_secret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        CONTINUER ICI
                        
                        Picker("v3 privacy algo", selection: $v3_privacy_proto) {
                            Text("DES").tag(V3PrivacyProto.DES)
                            Text("AES").tag(V3PrivacyProto.AES)
                        }
                        .padding(.bottom, 10)
                        COPNTINNUER ICI
                        
                        avec ce templace :
                        let v3cred = SNMPTarget.SNMPv3Credentials()
                        switch SNMP_sec_level {
                        case .noAuthNoPriv:
                            v3cred.security_level = .noAuthNoPriv
                        case .authNoPriv:
                            v3cred.security_level = .authNoPriv(v3_auth_proto == .MD5 ? .MD5(SNMP_auth_secret) : .SHA1(SNMP_auth_secret))
                        case .authPriv:
                            v3cred.security_level = .authPriv(v3_auth_proto == .MD5 ? .MD5(SNMP_auth_secret) : .SHA1(SNMP_auth_secret), v3_privacy_proto == .DES ? .DES(SNMP_priv_secret) : .AES(SNMP_priv_secret))
                        }
                        target.credentials = .v3(v3cred)
                        
                    }
                }
            }
        }
        .background((Color(COLORS.toolbar_background)))
        .cornerRadius(10)
    }
}

struct SNMPTreeView: View {
    @StateObject var rootNode: OIDNodeDisplayable = OIDNodeDisplayable(type: .root, val: "")
    @State private var highlight: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var is_manager_available: Bool = true
    @State private var isTargetExpanded = true
    
    @StateObject private var target = SNMPTarget()
 
    var body: some View {
        VStack {
            SNMPTargetView(target: target, isTargetExpanded: $isTargetExpanded)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading, 15)
                .padding(.trailing, 15)

            if isTargetExpanded == true {
                HStack {
                    /*
                     Button("translate") {
                     do {
                     let foo = try SNMPManager.manager.translate("IF-MIB::ifNumber")
                     print(foo)
                     } catch {
                     #fatalError("Translate SNMP Error: \(error)")
                     }
                     }*/
                    
                    Button(action: {
                        //                    let str_array = [ "snmpwalk", "-r3", "-t1", "-OX", "-OT", "-v2c", "-c", "public", "192.168.0.254"/*, "1.3.6.1.2.1.1.1"*/, "IF-MIB::ifInOctets" ]

                        //                        let str_array = SNMPManager.manager.getWalkCommandeLine(host: target.host)
                        let str_array = SNMPManager.manager.getWalkCommandeLineFromTarget(target: target)
                        
                        do {
                            try SNMPManager.manager.pushArray(str_array)
                            
                            is_manager_available = false
                            try SNMPManager.manager.walk() { oid_root in
                                let oid_root_displayable = oid_root.getDisplayable()
                                withAnimation(Animation.easeInOut(duration: 0.5)) {
                                    rootNode.type = oid_root_displayable.type
                                    rootNode.val = oid_root_displayable.val
                                    rootNode.children = oid_root_displayable.children
                                    rootNode.children_backup = oid_root_displayable.children_backup
                                    rootNode.subnodes = oid_root_displayable.subnodes
                                    is_manager_available = true
                                }
                            }
                        } catch {
                            #fatalError("Explore SNMP Error: \(error)")
                        }
                    })
                    {
                        Image(systemName: "list.dash.header.rectangle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(COLORS.standard_background))
                        Text("run full scan")
                            .font(.custom("Arial Narrow", size: 14))
                            .foregroundColor(Color(COLORS.standard_background))
                    }
                    .disabled(!is_manager_available)
                    .opacity(is_manager_available ? 1.0 : 0.5)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                    .padding(.trailing, 15)
                    .padding(.leading, 15)
                    
                    Spacer()
                    
                    Button(action: {
                        //                    let str_array = [ "snmpwalk", "-r3", "-t1", "-OX", "-OT", "-v2c", "-c", "public",
                    })
                    {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(COLORS.standard_background))
                        Text("scan interfaces speed")
                            .font(.custom("Arial Narrow", size: 14))
                            .foregroundColor(Color(COLORS.standard_background))
                    }
                    .disabled(!is_manager_available)
                    .opacity(is_manager_available ? 1.0 : 0.5)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                    .padding(.trailing, 15)
                    .padding(.leading, 15)
                }
                .background(Color(COLORS.toolbar_background)).opacity(0.9)
                .cornerRadius(10)
                .padding(.leading, 15)
                .padding(.trailing, 15)
                .padding(.bottom, 10)
            }

            if !is_manager_available {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding(.bottom, 15)
            }
            
            HStack {
                if #available(iOS 17.0, *) {
                    Image(systemName: "magnifyingglass")
                    TextField("Saisissez un filtre ici...", text: $highlight)
                        .autocorrectionDisabled(true)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: highlight) { _, newValue in
                            rootNode.expandAll()
                            _ = rootNode.filter(newValue)
                        }
                } else {
                    Image(systemName: "magnifyingglass")
                    TextField("Saisissez un filtre ici...", text: $highlight)
                        .autocorrectionDisabled(true)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: highlight) { newValue in
                            rootNode.expandAll()
                            _ = rootNode.filter(newValue)
                        }
                }
                
                Button(action: {
                    isTextFieldFocused = false
                    highlight = ""
                }, label: {
                    Image(systemName: "delete.left")
                })
                .disabled(highlight.isEmpty)
                
                Spacer(minLength: 40)
                
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.5)) {
                        rootNode.expandAll()
                    }
                }, label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                })
                
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.5)) {
                        rootNode.collapseAll()
                        rootNode.isExpanded = true
                    }
                }, label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                })
                
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.bottom, 5)
            
            List {
                OIDTreeView(node: rootNode, highlight: $highlight)
            }
            .scrollContentBackground(.hidden)
            .background(Color(COLORS.right_pannel_bg))
        }
        .background(Color(COLORS.right_pannel_bg))
    }
}
