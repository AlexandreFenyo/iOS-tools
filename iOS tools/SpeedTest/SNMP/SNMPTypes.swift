//
//  SNMPTypes.swift
//  SnmpGui
//
//  Created by Alexandre Fenyo on 23/04/2025.
//

import SwiftUI

enum OIDType {
    case root
    case mib
    case name
    case number
    case key
    case value
}

enum OIDParseError: Error {
    case invalidString
}

class OIDNodeDisplayable: Identifiable, ObservableObject {
    var line: String
    @Published var type: OIDType
    @Published var val: String
    // OutlineGroup impose que children soit nillable
    @Published var children: [OIDNodeDisplayable]?
    var children_backup: [OIDNodeDisplayable]?
    @Published var subnodes: [OIDNodeDisplayable]
    @Published var isExpanded: Bool = true
    @Published var isHidden: Bool = false

    weak var parent: OIDNodeDisplayable?
    
    init(type: OIDType, val: String, children: [OIDNodeDisplayable]? = nil, subnodes: [OIDNodeDisplayable] = [], parent: OIDNodeDisplayable? = nil, line: String = "") {
        self.type = type
        self.val = val
        self.children = children
        self.subnodes = subnodes
        self.line = line
    }
    
    func hide() {
        if isHidden { return }
        isHidden = true

        guard let parent else {
            return
        }
        
        if parent.children_backup == nil {
            parent.children_backup = parent.children
        }

        if let parent_children = parent.children {
            for i in 0..<parent_children.count {
                if parent_children[i] === self {
                    parent.children?.remove(at: i)
                    return
                }
            }
        }
    }

    func restore() {
        if !isHidden { return }
        isHidden = false

        guard let parent else {
            return
        }
        
        if parent.children_backup == nil {
            return
        }

        var new_parent_children = [OIDNodeDisplayable]()
        if let parent_children_backup = parent.children_backup {
            for parent_child in parent_children_backup {
                if parent_child.isHidden == false {
                    new_parent_children.append(parent_child)
                }
            }
        }
        parent.children = new_parent_children
    }

    // renvoie true si doit apparaître car lui ou un de ses descendants matche le filtre
    func filter(_ str: String) -> Bool {
        if str.isEmpty {
            restore()
            guard let children_backup else {
                return true
            }
            for child in children_backup {
                _ = child.filter(str)
            }
            return true
        } else {
            var should_appear = false
            
            if children_backup == nil {
                children_backup = children
            }
            
            if let children_backup, children_backup.isEmpty == false {
                // children exist
                for child in children_backup {
                    if child.filter(str) {
                        should_appear = true
                    }
                }
                if getDisplayValAndSubValues().lowercased().contains(str.lowercased()) {
                    should_appear = true
                }
            }
            else {
                // no child
                if getDisplayValAndSubValues().lowercased().contains(str.lowercased()) {
                    should_appear = true
                }
                if let foo = subnodes.last {
                    if foo.val.lowercased().contains(str.lowercased()) {
                        should_appear = true
                    }
                }
            }
            if should_appear {
                restore()
            } else {
                hide()
            }
            return should_appear
        }
    }
    
    func collapseAll() {
        isExpanded = false
        if let children {
            for child in children {
                child.collapseAll()
            }
        }
    }
    
    func expandAll() {
        isExpanded = true
        if let children {
            for child in children {
                child.expandAll()
            }
        }
    }
    
    func getDisplayVal() -> String {
        var description = ""
        
        switch type {
        case .root:
            description = NSLocalizedString("SNMP-OID-Tree", comment: "SNMP-OID-Tree")
        case .mib, .name, .number:
            description = val
        case .key:
            description = "[\(val)]"
        case .value:
            description = val
        }
        
        return description
    }
    
    func getDisplayValAndSubValues() -> String {
        var description = getDisplayVal()
        
        for i in 0..<subnodes.count {
            var subnode_descr: String
            let subnode = subnodes[i]
            if subnode.type != .key {
                subnode_descr = ".\(subnode.getDisplayVal())"
            } else {
                subnode_descr = "\(subnode.getDisplayVal())"
            }
            if subnode.type != .value {
                description = "\(description)\(subnode_descr)"
            }
        }
        
        return description
    }
    
    func getLevel() -> Int {
        if let parent = parent {
            return parent.getLevel() + 1
        }
        return 0
    }
}

// Splits a raw SNMP line "<key> = <type>: <value>" or "<key> = <value>" into
// (key, full value after " = ", value without the leading "<type>: " prefix).
// Examples:
//   "IF-MIB::ifOutOctets[1] = Counter32: 12345" -> ("IF-MIB::ifOutOctets[1]", "Counter32: 12345", "12345")
//   "SNMPv2-MIB::sysDescr.0 = STRING: \"Linux\""  -> ("SNMPv2-MIB::sysDescr.0", "STRING: \"Linux\"", "\"Linux\"")
fileprivate func parseSNMPLine(_ line: String) -> (key: String, value: String, valueWithoutType: String)? {
    guard let sep = line.range(of: " = ") else { return nil }
    let key = String(line[..<sep.lowerBound])
    let value = String(line[sep.upperBound...])
    var valueWithoutType = value
    if let colon = value.range(of: ": ") {
        let typePart = value[..<colon.lowerBound]
        if !typePart.contains(" ") {
            valueWithoutType = String(value[colon.upperBound...])
        }
    }
    return (key, value, valueWithoutType)
}

struct OIDReading {
    let value: String  // full value with type prefix, e.g. "Counter32: 12345"
    let date: Date
}

fileprivate func stripSNMPType(_ value: String) -> String {
    if let colon = value.range(of: ": ") {
        let typePart = value[..<colon.lowerBound]
        if !typePart.contains(" ") {
            return String(value[colon.upperBound...])
        }
    }
    return value
}

fileprivate func formatBitrate(_ bps: Double) -> String {
    if bps >= 1_000_000_000 {
        return String(format: "%.1f Gbit/s", bps / 1_000_000_000)
    }
    if bps >= 1_000_000 {
        return String(format: "%.1f Mbit/s", bps / 1_000_000)
    }
    if bps >= 1_000 {
        return String(format: "%.1f kbit/s", bps / 1_000)
    }
    return "\(Int(bps.rounded())) bit/s"
}

@MainActor
class OIDTimeSeries: ObservableObject {
    // OID key (e.g. "IF-MIB::ifOutOctets[1]") -> first/last received readings
    @Published private(set) var firstReadings: [String: OIDReading] = [:]
    @Published private(set) var lastReadings: [String: OIDReading] = [:]

    func reset() {
        firstReadings = [:]
        lastReadings = [:]
    }

    func firstValueWithoutType(forLine line: String) -> String? {
        guard let parsed = parseSNMPLine(line) else { return nil }
        guard let first = firstReadings[parsed.key],
              let last = lastReadings[parsed.key] else { return nil }
        if first.value == last.value { return nil }
        return stripSNMPType(first.value)
    }

    // Bitrate in bit/s = (last - first) * 8 / (last_date - first_date).
    // Uses only stored readings, never `Date()` at call time, so the value stays
    // stable between walks and only changes when new data is recorded.
    func bitrate(forLine line: String) -> Double? {
        guard let parsed = parseSNMPLine(line) else { return nil }
        guard let first = firstReadings[parsed.key],
              let last = lastReadings[parsed.key] else { return nil }
        if first.value == last.value { return nil }
        guard let firstNum = Double(stripSNMPType(first.value).trimmingCharacters(in: .whitespaces)),
              let lastNum = Double(stripSNMPType(last.value).trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        let dt = last.date.timeIntervalSince(first.date)
        guard dt > 0 else { return nil }
        let octets = lastNum - firstNum
        guard octets >= 0 else { return nil }
        return octets * 8.0 / dt
    }

    func formattedBitrate(forLine line: String) -> String? {
        guard let bps = bitrate(forLine: line) else { return nil }
        return formatBitrate(bps)
    }

    func update(_ oid: OIDNode) {
        let now = Date()
        if !oid.line.isEmpty, let parsed = parseSNMPLine(oid.line) {
            let reading = OIDReading(value: parsed.value, date: now)
            if firstReadings[parsed.key] == nil {
                firstReadings[parsed.key] = reading
            }
            lastReadings[parsed.key] = reading
        }
        for child in oid.children {
            update(child)
        }
    }
}

class OIDNode {
    var line: String
    let type: OIDType
    let val: String
    var children: [OIDNode]

    init(type: OIDType, val: String, children: [OIDNode] = [], line: String = "") {
        self.type = type
        self.val = val
        self.children = children
        self.line = line
    }

    func getDisplayable() -> OIDNodeDisplayable {
        if children.isEmpty {
            return OIDNodeDisplayable(type: type, val: val, line: line)
        }
        
        let displayable_node = OIDNodeDisplayable(type: type, val: val, line: line)

        var displayable_subnodes = [OIDNodeDisplayable]()
        var current = self
        while current.children.count == 1 {
            displayable_subnodes.append(OIDNodeDisplayable(type: current.children.first!.type, val: current.children.first!.val, line: current.children.first!.line))
            current = current.children.first!
        }

        displayable_subnodes.first?.parent = displayable_node
        if displayable_subnodes.count > 1 {
            for id in 1..<displayable_subnodes.count {
                displayable_subnodes[id].parent = displayable_subnodes[id - 1]
            }
        }
        
        var displayable_children = [OIDNodeDisplayable]()
        for child in current.children {
            let displayable_child = child.getDisplayable()
            displayable_child.parent = displayable_node
            displayable_children.append(displayable_child)
        }
        
        displayable_node.children = displayable_children.isEmpty ? nil : displayable_children
        displayable_node.subnodes = displayable_subnodes

        return displayable_node
    }
    
    func findDirectChild(type: OIDType, val: String) -> OIDNode? {
        for child in children {
            if child.type == type && child.val == val {
                return child
            }
        }
        return nil
    }

    // les deux doivent avoir la même racine
    func mergeSingleOID(_ new_oid: OIDNode) {
        if new_oid.type != type || new_oid.val != val {
            print("ERROR")
            exit(0)
        }
        
        guard let new_oid_child = new_oid.children.first else {
            return
        }
        if let tree_child = findDirectChild(type: new_oid_child.type, val: new_oid_child.val) {
            tree_child.mergeSingleOID(new_oid_child)
        } else {
            children.append(new_oid_child)
        }
    }

    static func parse(_ str: String) -> OIDNode {
        do {
            return OIDNode(type: .root, val: "", children: [try _parse(str, full_str: str)], line: str)
        } catch {
            print("ERROR")
            return OIDNode(type: .root, val: "")
        }
    }

    static func _parse(_ str: String, full_str: String) throws(OIDParseError) -> OIDNode {
        let charactersToFind: Set<Character> = [":", "[", ".", " "]

        if let idx = str.firstIndex(where: { charactersToFind.contains($0) }) {
            if str[idx] == ":" {
                let next_index = str.index(idx, offsetBy: 2)
                let next_str = str[next_index...]
                let val = str[..<idx]
                return OIDNode(type: .mib, val: String(val), children: [try _parse(String(next_str), full_str: full_str)], line: full_str)
            }
            if str[idx] == "[" {
                let idx_1 = str.index(after: idx)
                let key_str_to_end = str[idx_1...]
                guard let key_last_index = key_str_to_end.firstIndex(of: "]") else {
                    throw .invalidString
                }
                let key_last_index_1 = key_str_to_end.index(after: key_last_index)
                let val = key_str_to_end[..<key_last_index]
                let next_str = key_str_to_end[key_last_index_1...]
                if idx == str.startIndex {
                    return OIDNode(type: .key, val: String(val), children: [try _parse(String(next_str), full_str: full_str)], line: full_str)
                } else {
                    let is_number = NumberFormatter().number(from: String(str[..<idx])) != nil
                    return OIDNode(type: is_number ? .number : .name, val: String(str[..<idx]), children: [OIDNode(type: .key, val: String(val), children: [try _parse(String(next_str), full_str: full_str)], line: full_str)], line: full_str)
                }
            }
            if str[idx] == "." {
                let next_index = str.index(after: idx)
                let next_str = str[next_index...]
                let val = str[..<idx]
                let is_number = NumberFormatter().number(from: String(val)) != nil
                return OIDNode(type: is_number ? .number : .name, val: String(val), children: [try _parse(String(next_str), full_str: full_str)], line: full_str)
            }
            if str[idx] == " " {
                let next_index = str.index(idx, offsetBy: 3)
                let next_str = str[next_index...]
                let val = next_str
                if idx == str.startIndex {
                    return OIDNode(type: .value, val: String(val), line: full_str)
                } else {
                    let is_number = NumberFormatter().number(from: String(str[..<idx])) != nil
                    return OIDNode(type: is_number ? .number : .name, val: String(str[..<idx]), children: [OIDNode(type: .value, val: String(val), line: full_str)], line: full_str)
                }
            }
        }

        throw .invalidString
    }
    
    func dumpTree(_ level: Int = 0) {
        print("\(String.init(repeating: "-", count: level))\(type == .root ? "ROOT" : val)")
        for child in children {
            child.dumpTree(level + 1)
        }
    }
    
    func getSingleLevelDescription() -> String {
        switch type {
        case .root:
            return "ROOT"
        case .mib, .name, .number:
            return val
        case .key:
            return "[\(val)]"
        case .value:
            return val
        }
    }

    func getSingleLineDescription() -> String {
        switch type {
        case .root:
            return children.first?.getSingleLineDescription() ?? ""
        case .mib:
            return "\(val)::\(children.first?.getSingleLineDescription() ?? "")"
        case .name, .number:
            if children.first?.type == .name || children.first?.type == .number {
                return "\(val).\(children.first?.getSingleLineDescription() ?? "")"
            } else {
                return "\(val)\(children.first?.getSingleLineDescription() ?? "")"
            }
        case .key:
            return "[\(val)]\(children.first?.getSingleLineDescription() ?? "")"
        case .value:
            return " = \(val)"
        }
    }
}
