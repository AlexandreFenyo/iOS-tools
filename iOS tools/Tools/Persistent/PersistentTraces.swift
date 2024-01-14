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

class Traces {
//    static let shared = Traces()

    init() {
    }

    static func addMessage(_ msg: String) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let trace = Trace(context: context)
        trace.creation = .now
        trace.message = msg
        do {
            try context.save()
        } catch {
            print("error adding data")
        }
    }

    static func getMessages(onSuccess: @escaping ([Trace]?) -> Void) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        do {
            let items = try context.fetch(Trace.fetchRequest()) as? [Trace]
            onSuccess(items)
        } catch {
            print("error fetching data")
        }
    }

    static func deleteMessages() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

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

    func fatal(_ msg: String) {
    }
    
}
