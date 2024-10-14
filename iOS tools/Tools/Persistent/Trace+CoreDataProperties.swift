//
//  Trace+CoreDataProperties.swift
//  
//
//  Created by Alexandre Fenyo on 14/01/2024.
//
//

import Foundation
import CoreData

extension XTrace {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<XTrace> {
        return NSFetchRequest<XTrace>(entityName: "XTrace")
    }

    @NSManaged public var creation: Date?
    @NSManaged public var message: String?
}
