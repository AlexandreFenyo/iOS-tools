//
//  PersistentTraces.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 14/01/2024.
//  Copyright © 2024 Alexandre Fenyo. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import OSLog

// https://www.guardsquare.com/blog/swift-native-method-swizzling

// DYLD_INSERT_LIBRARIES
// lister les breakpoints que Xcode met en place : on y retrouve _swift_runtime_on_report qui est appelé indirectement par _assertionFailure() (qui est définie dans libswiftCore.dylib)
// break list -i
// ...
// -5.1: where = libswiftCore.dylib`_swift_runtime_on_report, address = 0x00000001a338f374, resolved, hit count = 1
// libswiftCore.dylib`Swift._assertionFailure(_: Swift.StaticString, _: Swift.StaticString, file: Swift.StaticString, line: Swift.UInt, flags: Swift.UInt32) -> Swift.Never

// cd /Applications/Xcode.app
// find . | fgrep -i libswiftcore.
// on cherche dans les fichiers résultats : __swift_runtime_on_report

// exception est différent de runtime error
// runtime errors :
// - _assertionFailure() :
//   - unwrap de nil
//   - fatalError()
//   - division par 0
// - arithmetic overflow

// unwrap de nil :
//let x: Bool? = nil
//let y = x!

// fatal error :
// fatalError("salut")
// Swift._assertionFailure(_: Swift.StaticString, _: Swift.StaticString, file: Swift.StaticString, line: Swift.UInt, flags: Swift.UInt32) -> Swift.Never:
// @inlinable public func assertionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line)
// let x = self._x
// let y = 5 / x

/*
@freestanding(expression)
public macro OptionSet<RawType>() =
        #externalMacro(module: "SwiftMacros", type: "OptionSetMacro")
 */

class Traces {
//    static let shared = Traces()

    init() {
    }

    @discardableResult
    static func addMessage(_ msg: String) -> String {
        Task.detached { @MainActor in
            guard let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer?.viewContext else { return }
            let trace = Trace(context: context)
            trace.creation = .now
            trace.message = msg
            do {
                try context.save()
            } catch {
                print("error adding data")
            }
        }
        return msg
    }

    @discardableResult
    static func addMessage(_ msg: String, fct: String, path: String, line: Int) -> String {
        let filename = path.split(separator: "/").last!
        return addMessage("'\(msg)' at \(fct)@\(filename):\(line)")
    }
    
    // We decorate this function with @MainActor to avoid a compiler error while accessing AppDelegate.persistentContainer.viewContext, since this property is also managed by the main actor (AppDelegate is decorated with @MainActor)
    @MainActor
    static func getMessages(onSuccess: @escaping ([Trace]?) -> Void) {
        /*
        print("avant accès os log store")
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceLatestBoot: 1)
            let entries = try store
                .getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == Bundle.main.bundleIdentifier! }
                .map { "[\($0.date.formatted())] [\($0.category)] \($0.composedMessage)" }
            for entry in entries {
                print("XXXX: \(entry)")
            }
        } catch {
            print("error fetching OS log store")
        }*/
        
        // The viewContext property contains a reference to the NSManagedObjectContext that is created and owned by the persistent container which is associated with the main queue of the application.
        guard let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer?.viewContext else { return }

        do {
            let items = try context.fetch(Trace.fetchRequest()) as? [Trace]
            onSuccess(items)
        } catch {
            print("error fetching data")
        }
    }

    static func deleteMessages() {
        Task.detached { @MainActor in
            guard let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer?.viewContext else { return }
            do {
                let items = try context.fetch(Trace.fetchRequest()) as? [Trace]
                guard let items else { return }
                for item in items {
                    context.delete(item)
                }
                try context.save()
            } catch {
                print("error deleting data")
            }
        }
    }
}
