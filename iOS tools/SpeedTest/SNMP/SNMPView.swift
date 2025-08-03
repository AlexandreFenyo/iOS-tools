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
                                                        // snmptranslate -mall -Td $OID 2> /dev/null | read -d '' RESP
                                                        // echo $RESP | sed -n 1p | read XOID
                                                        // echo $RESP | grep '  -- FROM' | head -1 | sed 's/  -- FROM[ \t]*//' | sed 's/"/\\\\"/g' | read MIB
                                                        // echo $RESP | grep '  -- TEXTUAL CONVENTION' | head -1 | sed -E 's/  -- TEXTUAL CONVENTION[\t ]*//' | sed 's/"/\\\\"/g' | read TXT
                                                        // echo $RESP | grep '  SYNTAX' | head -1 | sed -E 's/  SYNTAX[\t ]*//' | sed 's/"/\\\\"/g' | read SYNTAX
                                                        // echo $RESP | grep '  DISPLAY-HINT' | head -1 | sed -E 's/  DISPLAY-HINT[\t ]*//' | sed 's/"/\\\\"/g' | read HINT
                                                        // echo $RESP | grep '  MAX-ACCESS' | head -1 | sed -E 's/  MAX-ACCESS[\t ]*//' | sed 's/"/\\\\"/g' | read ACCESS
                                                        // echo $RESP | grep '  STATUS' | head -1 | sed -E 's/  STATUS[\t ]*//' | sed 's/"/\\\\"/g' | read STATUS
                                                        // echo $RESP | grep '::= ' | head -1 | sed -E 's/::= //' | sed 's/"/\\\\"/g' | read LINE
                                                        // echo `echo $RESP | sed '0,/DESCRIPTION/ { /DESCRIPTION/!d }' | egrep -v '^::= '` | sed 's/^DESCRIPTION *//' | sed 's/^"//' | sed 's/"$//' | sed 's/"/\\\\"/g' | read DESCRIPTION
                                                        // echo "{ \"oid\": \"$XOID\", \"mib\": \"$MIB\", \"conv\": \"$TXT\", \"syntax\": \"$SYNTAX\", \"hint\": \"$HINT\", \"access\": \"$ACCESS\", \"status\": \"$STATUS\", \"line\": \"$LINE\", \"description\": \"$DESCRIPTION\" }"
                                                        // exit 0
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
                }
            }
        }
    }
}

struct SNMPTargetView: View {
    enum Usage { case add, edit, view }
    @State var usage: Usage
    
    @ObservedObject var target: SNMPTargetSimple
    @Binding var isTargetExpanded: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text(usage == .view ? "target (SNMP agent)" : "SNMP agent configuration")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                
                Spacer()
                
                if usage == .view {
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
            }
            
            if isTargetExpanded {
                if usage == .view {
                    TextField("hostname", text: $target.host)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                }
                
                HStack {
                    TextField("port (161)", text: $target.port)
                        .keyboardType(.numberPad)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                    
                    Picker("SNMP protocol", selection: $target.credentials) {
                        Text("SNMPv1").tag(SNMPTargetSimple.Credentials.v1)
                        Text("SNMPv2c").tag(SNMPTargetSimple.Credentials.v2c)
                        Text("SNMPv3").tag(SNMPTargetSimple.Credentials.v3)
                    }
                }
                
                HStack {
                    if target.credentials != .v3 {
                        TextField("community (public)", text: $target.community)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                    } else {
                        Picker("SNMP sec level", selection: $target.security_level) {
                            Text("NoAuth/NoPriv").tag(SNMPTargetSimple.SecurityLevel.noAuthNoPriv)
                            Text("Auth/NoPriv").tag(SNMPTargetSimple.SecurityLevel.authNoPriv)
                            Text("Auth/Priv").tag(SNMPTargetSimple.SecurityLevel.authPriv)
                        }
                        Spacer()
                    }
                    
                    Picker("SNMP transport protocol", selection: $target.transport_proto) {
                        Text("UDP").tag(SNMPTransportProto.UDP)
                        Text("TCP").tag(SNMPTransportProto.TCP)
                    }
                    
                    Picker("SNMP network protocol", selection: $target.ip_version) {
                        Text("IPv4").tag(SNMPNetworkProto.IPv4)
                        Text("IPv6").tag(SNMPNetworkProto.IPv6)
                    }
                }
                
                if target.credentials == .v3 {
                    HStack {
                        TextField("username", text: $target.username)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, target.security_level == .noAuthNoPriv ? 10 : 0)
                    }
                }
                
                if target.credentials == .v3 && target.security_level == .authNoPriv {
                    HStack {
                        TextField("authentication secret", text: $target.authProtoSecret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        
                        Picker("v3 auth proto", selection: $target.auth_proto) {
                            Text("MD5").tag(V3AuthProto.MD5)
                            Text("SHA1").tag(V3AuthProto.SHA1)
                        }
                        .padding(.bottom, 10)
                    }
                }
                
                if target.credentials == .v3 && target.security_level == .authPriv {
                    HStack {
                        TextField("authentication secret", text: $target.authProtoSecret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                        
                        Picker("v3 auth algo", selection: $target.auth_proto) {
                            Text("MD5").tag(V3AuthProto.MD5)
                            Text("SHA1").tag(V3AuthProto.SHA1)
                        }
                        .padding(.bottom, 10)
                    }
                    
                    HStack {
                        TextField("privacy secret", text: $target.privProtoSecret)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        
                        Picker("v3 privacy algo", selection: $target.privacy_proto) {
                            Text("DES").tag(V3PrivacyProto.DES)
                            Text("AES").tag(V3PrivacyProto.AES)
                        }
                        .padding(.bottom, 10)
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

struct OIDInfoView: View {
    @State var name: String
    @State var value: String
    
    var body: some View {
        VStack {
            HStack {
                Text("\(name)")
                    .font(.subheadline)
                Spacer()
            }
            HStack {
                Text("\(value)")
                    .font(.headline)
                Spacer()
            }
        }.padding(10)
            .background(name != "description" ? Color(COLORS.toolbar_background) : Color(COLORS.toolbar_background.withAlphaComponent(0.5)))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 2)
                    .shadow(color: .gray, radius: 10, x: 2, y: 2)
            )
    }
}

struct CustomPopupView: View {
    @Binding var show_popup: Bool
    @Binding var oid_info: OIDInfos?
    
    var body: some View {
        
        GeometryReader { geometry in
            let maxWidth: CGFloat = geometry.size.width * 3 / 4

            HStack {
                Spacer()
                VStack(spacing: 16) {
                    Image("Icon")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    ScrollView {
                        VStack {
                            Text("SNMP Object Identifier Help")
                                .font(.headline)
                            
                            if let oid_info {
                                OIDInfoView(name: "object identifier (symbolic format)", value: oid_info.oid)
                                if let value = oid_info.line {
                                    OIDInfoView(name: "object identifier (numeric format)", value: value)
                                }
                                OIDInfoView(name: "MIB module(s) on which the object is defined", value: oid_info.mib)
                                /*
                                 if let value = oid_info.conv {
                                 OIDInfoView(name: "textual convention", value: value)
                                 }
                                 if let value = oid_info.hint {
                                 OIDInfoView(name: "display hint", value: value)
                                 }
                                 */
                                if let value = oid_info.syntax {
                                    OIDInfoView(name: "value syntax", value: value)
                                }
                                if let value = oid_info.status {
                                    OIDInfoView(name: "status (current, obsolete or deprecated)", value: value)
                                }
                                if let value = oid_info.access {
                                    OIDInfoView(name: "access mode (read-only, read-write or not-accessible)", value: value)
                                }
                                if let value = oid_info.description {
                                    OIDInfoView(name: "description", value: value)
                                        .padding(.bottom, 10)
                                }
                            } else {
                                Text("Error: no description received")
                            }
                        }.padding(.horizontal)
                            .frame(maxWidth: maxWidth)
                    }
                    
                    Button(action: {
                        withAnimation(Animation.easeInOut(duration: 0.5)) {
                            show_popup = false
                        }
                    }, label: {
                        Text("OK")
                            .font(.headline)
                            .foregroundColor(Color.black.lighter().lighter())
                    })
                    .padding()
                    .frame(maxWidth: maxWidth)
                    .background(Color.gray.lighter().lighter().lighter())
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.lighter().lighter().lighter().lighter().lighter())
                .cornerRadius(12)
                .shadow(radius: 8)
                Spacer()
            }
            .padding(10)
        }
    }
}

class SNMPAvailability: ObservableObject {
    static var shared = SNMPAvailability()
    @Published fileprivate var available = true
    @Published private var message: String?
    
    func setAvailability(_ available: Bool, message: String? = nil) {
        // SNMPAvailability(condition: .onQueue(.main)) would stop the app, we use #fatalError instead
        if !Thread.isMainThread {
            #fatalError("SNMPAvailability: setAvailability: bad thread")
        }
        withAnimation(Animation.easeInOut(duration: 0.5)) {
            self.available = available
            self.message = message
        }
    }
    
    func getAvailability() -> Bool {
        // SNMPAvailability(condition: .onQueue(.main)) would stop the app, we use #fatalError instead
        if !Thread.isMainThread {
            #fatalError("SNMPAvailability: getAvailability: bad thread")
        }
        
        return available
    }

    func getMessage() -> String? {
        // SNMPAvailability(condition: .onQueue(.main)) would stop the app, we use #fatalError instead
        if !Thread.isMainThread {
            #fatalError("SNMPAvailability: getMessage: bad thread")
        }

        return message
    }
}

@MainActor
struct SNMPView: View {
    let master_view_controller: MasterViewController

    @StateObject var rootNode: OIDNodeDisplayable = OIDNodeDisplayable(type: .root, val: "")
    @State private var highlight: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var isTargetExpanded = true
    @StateObject private var is_manager_available_obj = SNMPAvailability.shared
    @State private var show_alert = false
    @State private var alert = ""
    
    @State private var show_popup = false
    @State private var oid_info: OIDInfos?

    @State private var interface_loop = false

    @EnvironmentObject var current_selected_target_simple: SNMPTargetSimple
    
    var oid_time_series = OIDTimeSeries()
    
    func showInfo(info: String) {
        if let jsonData = info.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                oid_info = try decoder.decode(OIDInfos.self, from: jsonData)
                /*
                print("oid: \(String(describing: oid_info?.oid))")
                print("mib: \(String(describing: oid_info?.mib))")
                print("textual_convention: \(String(describing: oid_info?.conv))")
                print("syntax: \(String(describing: oid_info?.syntax))")
                print("display_hint: \(String(describing: oid_info?.hint))")
                print("status: \(String(describing: oid_info?.status))")
                print("line: \(String(describing: oid_info?.line))")
                print("description: \(String(describing: oid_info?.description))")
                */
            } catch {
                #fatalError("JSON parser error: \(error.localizedDescription)")
            }
        }
        
        show_popup = true
    }
    
    private func onEndLoop(_ oid_node: OIDNode?) -> Void {
        guard let oid_node = oid_node else { return }

        oid_time_series.update(oid_node)
        
    }
    
    private func doLoop(command: [String], message: String) {
        walk(command, message: message, onEnd: onEndLoop)
        Task { @MainActor in
            while (interface_loop) {
                walk(command, message: message, onEnd: onEndLoop)
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
    
    // onEnd will be called on MainActor
    func walk(_ str_array: [String], message: String? = nil, onEnd: ((OIDNode?) -> Void)? = nil) {
        do {
            try SNMPManager.manager.pushArray(str_array)
            is_manager_available_obj.setAvailability(false, message: message)
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
                    is_manager_available_obj.setAvailability(true)

                    rootNode.expandAll()
                    _ = rootNode.filter(highlight)
                }
                
                if let onEnd {
                    onEnd(oid_root)
                }
            }
        } catch {
            #fatalError("Explore SNMP Error: \(error)")
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                SNMPTargetView(usage: .view, target: current_selected_target_simple, isTargetExpanded: $isTargetExpanded)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    .alert("SNMP Warning", isPresented: $show_alert, actions: {
                        Button("OK", role: .cancel) { }
                    }, message: {
                        Text(alert)
                    })
                    .onChange(of: show_alert) { value in
                        if value && interface_loop {
                            // Remove the alert automatically when looping on a SNMP subtree
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                show_alert = false
                            }
                        }
                    }
                
                if isTargetExpanded == true {
                    HStack {
                        Button(action: {
                            var str_array = SNMPManager.manager.getWalkCommandLineFromTarget(target: SNMPTarget(current_selected_target_simple))
                            str_array.append(".1.3.6.1.2.1.1")
                            walk(str_array, message: "SNMP walk for \(current_selected_target_simple.host)\(current_selected_target_simple.transport_proto == .TCP ? " - TCP timeout: 75s" : "")")
                            master_view_controller.addTrace("SNMP: simple scan for \(current_selected_target_simple.host)")
                        })
                        {
                            Image(systemName: "list.dash.header.rectangle")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(COLORS.standard_background))
                            if !interface_loop {
                                Text("fast scan")
                                    .font(.custom("Arial Narrow", size: 14))
                                    .foregroundColor(Color(COLORS.standard_background))
                            }
                        }
                        .commonButtonStyle(isManagerAvailable: is_manager_available_obj.available && !interface_loop, isHostEmpty: current_selected_target_simple.host.isEmpty)

                        Spacer()
                        
                        Button(action: {
                            let str_array = SNMPManager.manager.getWalkCommandLineFromTarget(target: SNMPTarget(current_selected_target_simple))
                            walk(str_array, message: "SNMP walk for \(current_selected_target_simple.host)\(current_selected_target_simple.transport_proto == .TCP ? " - TCP timeout: 75s" : "")")
                            master_view_controller.addTrace("SNMP: full scan for \(current_selected_target_simple.host)")
                        })
                        {
                            Image(systemName: "list.bullet.rectangle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(COLORS.standard_background))
                            if !interface_loop {
                                Text("full scan")
                                    .font(.custom("Arial Narrow", size: 14))
                                    .foregroundColor(Color(COLORS.standard_background))
                            }
                        }
                        .commonButtonStyle(isManagerAvailable: is_manager_available_obj.available && !interface_loop, isHostEmpty: current_selected_target_simple.host.isEmpty)

                        Spacer()
                        
                        Button(action: {
                            withAnimation(Animation.easeInOut(duration: 0.5)) {
                                interface_loop = true
                            }
                            
                            var str_array = SNMPManager.manager.getWalkCommandLineFromTarget(target: SNMPTarget(current_selected_target_simple))
                            str_array.append(".1.3.6.1.2.1.2.2")
                            doLoop(command: str_array, message: "SNMP walk for \(current_selected_target_simple.host)\(current_selected_target_simple.transport_proto == .TCP ? " - TCP timeout: 75s" : "")")

                            master_view_controller.addTrace("SNMP: scan interfaces for \(current_selected_target_simple.host)")
                        })
                        {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(COLORS.standard_background))
                            if !interface_loop {
                                Text("scan interfaces speed")
                                    .font(.custom("Arial Narrow", size: 14))
                                    .foregroundColor(Color(COLORS.standard_background))
                            }
                        }
                        .commonButtonStyle(isManagerAvailable: is_manager_available_obj.available && !interface_loop, isHostEmpty: current_selected_target_simple.host.isEmpty)
                        
                        if interface_loop {
                            Button(action: {
                                withAnimation(Animation.easeInOut(duration: 0.5)) {
                                    interface_loop = false


                                }
                                master_view_controller.addTrace("SNMP: stopped interfaces scan")
                            })
                            {
                                Image(systemName: "stop.circle")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(COLORS.standard_background))
                                Text("stop interfaces scan")
                                    .font(.custom("Arial Narrow", size: 14))
                                    .foregroundColor(Color(COLORS.standard_background))
                            }
                            .commonButtonStyle(isManagerAvailable: true, isHostEmpty: false)
                        }
                    }
                    .background(Color(COLORS.toolbar_background)).opacity(0.9)
                    .cornerRadius(10)
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    .padding(.bottom, 10)
                }
                
                if !is_manager_available_obj.available {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding(.bottom, 15)
                    
                    if let msg = SNMPAvailability.shared.getMessage() {
                        Text(msg)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                    }
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                    if #available(iOS 17.0, *) {
                        TextField("Set a filter...", text: $highlight)
                            .autocorrectionDisabled(true)
                            .focused($isTextFieldFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: highlight) { _, newValue in
                                rootNode.expandAll()
                                _ = rootNode.filter(newValue)
                            }
                    } else {
                        TextField("Set a filter...", text: $highlight)
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
                            //                        rootNode.isExpanded = true
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
            
            if show_popup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            show_popup = false
                        }
                    }
                    CustomPopupView(show_popup: $show_popup, oid_info: $oid_info)
                        .transition(.scale)
            }
        }
        .animation(.easeInOut, value: show_popup)
        .onAppear() {
            if debug_snmp {
                current_selected_target_simple.host = "192.168.1.164"
            }
        }
    }
}
