//
//  SnmpSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 06/04/2025.
//  Copyright © 2025 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import StoreKit

public class SnmpViewModel : ObservableObject {
    static let shared = SnmpViewModel()
    
    /*
     private let log_level_to_string: [LogLevel: String] = [
     LogLevel.INFO: "INFO",
     LogLevel.DEBUG: "DEBUG",
     LogLevel.ALL: "ALL"
     ]*/
    
    private let df: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()
    
    // Contrainte à respecter : il faut toujours au moins 1 chaîne dans traces
    // le 7 mars 2023 : Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates. => identifier pourquoi et corriger
    // Idem le 15 juin
    @Published private(set) var traces: [String] = {
        var arr = [String]()
        arr.append("")
        for i in 1...200 {
            //                arr.append("Speed Test - Traces zfeiopjf oifj o jefozi jeofjioj ei jozefij ezoi jezo ijezo ijezoi ejzfo jzeo jzefi oezfj ziefo jzeo ijzef oizejfoize jfezo ijzefo ijzef ozefj zieo jezio jzeoi jzeofi jezo ijzeoi jzeoi jzeoi jezo ijzeo ijzeo ijzeio jzeio j \(i)")
            //                arr.append("Speed Test - Traces \(i)")
        }
        return arr
    }()
    
    fileprivate func clear() {
        traces = [ "" ]
        Traces.deleteMessages()
    }
    
    /*
     public func append(_ str: String, level _level: LogLevel = .ALL, date _date: Date? = nil) {
     if _level.rawValue <= level.rawValue {
     let level = log_level_to_string[_level]!
     traces.append(df.string(from: _date ?? Date()) + " [" + level + "]: " + str)
     }
     }*/
    
    //    @Published private(set) var level: LogLevel = .ALL
    //    public func setLevel(_ val: LogLevel) { level = val }
}

/*
 public enum LogLevel : Int {
 case INFO = 0
 case DEBUG
 case ALL
 }*/

struct SnmpSwiftUIView: View {
    @ObservedObject var model = SnmpViewModel.shared
    
    @State public var locked = true
    @Namespace var topID
    @Namespace var bottomID
    
    private struct ScrollViewOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = .zero
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value += nextValue()
        }
    }
    
    @State private var timer: Timer?
    
    func getOIDNode() -> OIDNodeDisplayable {
        
        return OIDNodeDisplayable(type: .root, val: "")
        
        let filepath = Bundle.main.path(forResource: "snmpwalk", ofType: "txt")!
        
        var cnt = 0
        let oid_root: OIDNode = OIDNode(type: .root, val: "")
        if let fileHandle = FileHandle(forReadingAtPath: filepath) {
            let fileData = fileHandle.readDataToEndOfFile()
            if let fileContent = String(data: fileData, encoding: .isoLatin1) {
                fileContent.enumerateLines { line, _ in
                    print(line)
                    cnt += 1
                    oid_root.mergeSingleOID(OIDNode.parse(line))
                    /*
                     if cnt == 1200 /* pb à 907 */ {
                     print("FIN")
                     oid.dumpTree()
                     exit(0)
                     }*/
                }
            }
            fileHandle.closeFile()
        } else {
            print("Le fichier n'existe pas à l'emplacement spécifié.")
        }
        
        let oid_root_displayable = oid_root.getDisplayable()
        oid_root_displayable.val = "SNMP OID Tree"
        return oid_root_displayable
    }
    
    var body: some View {
        SNMPTreeView(rootNode: getOIDNode())
    }
}
