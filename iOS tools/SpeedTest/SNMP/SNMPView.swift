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
    
    var show_info_cb: (String) -> Void
    
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
                            
                            /*
                             Image(systemName: "questionmark.circle")
                             .foregroundColor(.orange)
                             .onTapGesture {
                             }
                             */
                        } else {
                            HighlightedTextView(node.getDisplayValAndSubValues(), highlight: highlight)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            HighlightedTextView(node.subnodes.last?.val ?? "", highlight: highlight)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.trailing)
                            
                            if !node.line.isEmpty {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.orange)
                                    .onTapGesture {
                                        if let foo = node.line.components(separatedBy: " = ").first {
                                            if let bar = foo.components(separatedBy: "[").first {
                                                Task {
                                                    do {
                                                        // We call the following web service:
                                                        // vps-225bc1f7# cat snmptranslate.cgi
                                                        // #!/bin/zsh
                                                        // echo Content-type: text/html
                                                        // echo
                                                        // OID=`echo $QUERY_STRING | sed 's/[^0-9a-zA-Z.:-]//g'`
                                                        // snmptranslate -mall -Td $OID 2> /dev/null
                                                        let data = try await URLSession.shared.data(from: URL(string: "http://ovh.fenyo.net/cgi-bin/snmptranslate.cgi?\(bar)")!).0
                                                        if let str = String(data: data, encoding: .utf8) {
                                                            show_info_cb(str)
                                                        } else {
                                                            #fatalError("snmptranslate encoding error")
                                                        }
                                                    } catch {
                                                        #fatalError("snmptranslate: \(error)")
                                                    }
                                                }
                                            }
                                        }
                                    }
                            }
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
                        OIDTreeView(node: child, highlight: $highlight, show_info_cb: show_info_cb)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.orange)
                    HighlightedTextView(node.getDisplayValAndSubValues(), highlight: highlight)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    /*
                     Image(systemName: "questionmark.circle")
                     .foregroundColor(.orange)
                     */
                }
            }
        }
    }
}

struct SNMPTargetView: View {
    @ObservedObject var target: SNMPTarget
    @Binding var isTargetExpanded: Bool
    
    @State private var SNMP_protocol = SNMPProto.SNMPv2c
    @State private var SNMP_transport_protocol = SNMPTransportProto.`default`
    @State private var SNMP_network_protocol = SNMPNetworkProto.`default`
    @State private var SNMP_sec_level = SNMPSecLevel.`default`
    
    @State private var SNMP_username = ""
    @State private var SNMP_auth_secret = ""
    @State private var SNMP_priv_secret = ""
    @State private var SNMP_community = ""
    
    @State private var v3_auth_proto = V3AuthProto.MD5
    @State private var v3_privacy_proto = V3PrivacyProto.DES
    
    private func updateTargetV3Cred(level: SNMPSecLevel? = nil, username: String? = nil, auth_secret: String? = nil, priv_secret: String? = nil, auth_proto: V3AuthProto? = nil, priv_proto: V3PrivacyProto? = nil) {
        let v3cred = SNMPTarget.SNMPv3Credentials()
        v3cred.username = username ?? SNMP_username
        switch level ?? SNMP_sec_level {
        case .noAuthNoPriv:
            v3cred.security_level = .noAuthNoPriv
        case .authNoPriv:
            v3cred.security_level = .authNoPriv(auth_proto ?? v3_auth_proto == .MD5 ? .MD5(auth_secret ?? SNMP_auth_secret) : .SHA1(auth_secret ?? SNMP_auth_secret))
        case .authPriv:
            v3cred.security_level = .authPriv(auth_proto ?? v3_auth_proto == .MD5 ? .MD5(auth_secret ?? SNMP_auth_secret) : .SHA1(auth_secret ?? SNMP_auth_secret), priv_proto ?? v3_privacy_proto == .DES ? .DES(priv_secret ?? SNMP_priv_secret) : .AES(priv_secret ?? SNMP_priv_secret))
        }
        target.credentials = .v3(v3cred)
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
                    .onAppear {
                        if let str = SNMPManager.manager.getCurrentSelectedIP()?.toNumericString() {
                            target.host = str
                            SNMPManager.manager.setCurrentSelectedIP(nil)
                        }
                    }
                
                HStack {
                    TextField("port (161)", text: $target.port)
                        .keyboardType(.numberPad)
                        .font(.subheadline)
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
                            updateTargetV3Cred()
                        }
                    }
                }
                
                HStack {
                    if SNMP_protocol != .SNMPv3 {
                        TextField("community (public)", text: $SNMP_community)
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
                            updateTargetV3Cred(level: newValue)
                        }
                        
                        Spacer()
                    }
                    
                    Picker("SNMP transport protocol", selection: $SNMP_transport_protocol) {
                        Text("UDP").tag(SNMPTransportProto.UDP)
                        Text("TCP").tag(SNMPTransportProto.TCP)
                    }.onChange(of: SNMP_transport_protocol) { newValue in
                        target.transport_proto = newValue == .UDP ? .UDP : .TCP
                    }
                    
                    Picker("SNMP network protocol", selection: $SNMP_network_protocol) {
                        Text("IPv4").tag(SNMPNetworkProto.IPv4)
                        Text("IPv6").tag(SNMPNetworkProto.IPv6)
                    }.onChange(of: SNMP_network_protocol) { newValue in
                        target.ip_version = newValue == .IPv4 ? .IPv4 : .IPv6
                    }
                }
                
                if SNMP_protocol == .SNMPv3 {
                    HStack {
                        TextField("username", text: $SNMP_username)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, SNMP_sec_level == .noAuthNoPriv ? 10 : 0)
                            .onChange(of: SNMP_username) { newValue in
                                updateTargetV3Cred(username: newValue)
                            }
                    }
                }
                
                if SNMP_protocol == .SNMPv3 && SNMP_sec_level == .authNoPriv {
                    HStack {
                        TextField("authentication secret", text: $SNMP_auth_secret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                            .onChange(of: SNMP_auth_secret) { newValue in
                                updateTargetV3Cred(auth_secret: newValue)
                            }
                        
                        Picker("v3 auth proto", selection: $v3_auth_proto) {
                            Text("MD5").tag(V3AuthProto.MD5)
                            Text("SHA1").tag(V3AuthProto.SHA1)
                        }
                        .padding(.bottom, 10)
                        .onChange(of: v3_auth_proto) { newValue in
                            updateTargetV3Cred(auth_proto: newValue)
                        }
                    }
                }
                
                if SNMP_protocol == .SNMPv3 && SNMP_sec_level == .authPriv {
                    HStack {
                        TextField("authentication secret", text: $SNMP_auth_secret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .onChange(of: SNMP_auth_secret) { newValue in
                                updateTargetV3Cred(auth_secret: newValue)
                            }
                        
                        Picker("v3 auth algo", selection: $v3_auth_proto) {
                            Text("MD5").tag(V3AuthProto.MD5)
                            Text("SHA1").tag(V3AuthProto.SHA1)
                        }
                        .padding(.bottom, 10)
                        .onChange(of: v3_auth_proto) { newValue in
                            updateTargetV3Cred(auth_proto: newValue)
                        }
                    }
                    
                    HStack {
                        TextField("privacy secret", text: $SNMP_priv_secret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                            .onChange(of: SNMP_priv_secret) { newValue in
                                updateTargetV3Cred(priv_secret: newValue)
                            }
                        
                        Picker("v3 privacy algo", selection: $v3_privacy_proto) {
                            Text("DES").tag(V3PrivacyProto.DES)
                            Text("AES").tag(V3PrivacyProto.AES)
                        }
                        .padding(.bottom, 10)
                        .onChange(of: v3_privacy_proto) { newValue in
                            updateTargetV3Cred(priv_proto: newValue)
                        }
                    }
                }
            }
        }
        .background((Color(COLORS.toolbar_background)))
        .cornerRadius(10)
    }
}

struct CommonButtonModifier: ViewModifier {
    let isManagerAvailable: Bool
    let isHostEmpty: Bool

    func body(content: Content) -> some View {
        content
            .disabled(!isManagerAvailable || isHostEmpty)
            .opacity((isManagerAvailable && !isHostEmpty) ? 1.0 : 0.5)
            .padding(.top, 5)
            .padding(.bottom, 5)
            .padding(.trailing, 15)
            .padding(.leading, 15)
    }
}

extension View {
    func commonButtonStyle(isManagerAvailable: Bool, isHostEmpty: Bool) -> some View {
        self.modifier(CommonButtonModifier(isManagerAvailable: isManagerAvailable, isHostEmpty: isHostEmpty))
    }
}

struct SNMPView: View {
    @StateObject var rootNode: OIDNodeDisplayable = OIDNodeDisplayable(type: .root, val: "")
    @State private var highlight: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var is_manager_available: Bool = true
    @State private var isTargetExpanded = true
    
    @State private var show_alert = false
    @State private var alert = ""
    
    @State private var show_info = false
    @State private var info = ""
    
    @StateObject private var target = SNMPTarget()
    
    func showInfo(info: String) {
        self.info = info
        show_info = true
    }
    
    func walk(_ str_array: [String]) {
        do {
            try SNMPManager.manager.pushArray(str_array)
            
            is_manager_available = false
            try SNMPManager.manager.walk() { oid_root, errbuf in
                if !errbuf.isEmpty {
                    if errbuf.starts(with: "Timeout: No Response from udp:") {
                        if oid_root.children.count == 0 {
                            alert = errbuf
                            show_alert = true
                        }
                    } else {
                        alert = errbuf
                        show_alert = true
                    }
                }
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
    }
    
    var body: some View {
        VStack {
            SNMPTargetView(target: target, isTargetExpanded: $isTargetExpanded)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading, 15)
                .padding(.trailing, 15)
                .alert("SNMP Warning", isPresented: $show_alert, actions: {
                    Button("OK", role: .cancel) { }
                }, message: {
                    Text(alert)
                })
                .alert("SNMP", isPresented: $show_info, actions: {
                    Button("OK", role: .cancel) { }
                }, message: {
                    Text(info)
                })
            
            if isTargetExpanded == true {
                HStack {
                    Button(action: {
                        let str_array = SNMPManager.manager.getWalkCommandeLineFromTarget(target: target)
                        walk(str_array)
                    })
                    {
                        Image(systemName: "list.bullet.rectangle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(COLORS.standard_background))
                        Text("run full scan")
                            .font(.custom("Arial Narrow", size: 14))
                            .foregroundColor(Color(COLORS.standard_background))
                    }
                    .commonButtonStyle(isManagerAvailable: is_manager_available, isHostEmpty: target.host.isEmpty)

                    Spacer()
                    
                    Button(action: {
                        var str_array = SNMPManager.manager.getWalkCommandeLineFromTarget(target: target)
                        str_array.append(".1.3.6.1.2.1.1")
                        walk(str_array)
                    })
                    {
                        Image(systemName: "list.dash.header.rectangle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(COLORS.standard_background))
                        Text("run fast scan")
                            .font(.custom("Arial Narrow", size: 14))
                            .foregroundColor(Color(COLORS.standard_background))
                    }
                    .commonButtonStyle(isManagerAvailable: is_manager_available, isHostEmpty: target.host.isEmpty)

                    Spacer()
                    
                    Button(action: {
                        var str_array = SNMPManager.manager.getWalkCommandeLineFromTarget(target: target)
                        str_array.append(".1.3.6.1.2.1.2")
                        walk(str_array)
                    })
                    {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(COLORS.standard_background))
                        Text("scan interfaces speed")
                            .font(.custom("Arial Narrow", size: 14))
                            .foregroundColor(Color(COLORS.standard_background))
                    }
                    .commonButtonStyle(isManagerAvailable: is_manager_available, isHostEmpty: target.host.isEmpty)
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
                OIDTreeView(node: rootNode, highlight: $highlight, show_info_cb: showInfo)
            }
            .scrollContentBackground(.hidden)
            .background(Color(COLORS.right_pannel_bg))
        }
        .background(Color(COLORS.right_pannel_bg))
    }
}
