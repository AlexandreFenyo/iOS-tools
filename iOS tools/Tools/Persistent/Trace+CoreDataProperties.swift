//
//  Trace+CoreDataProperties.swift
//  
//
//  Created by Alexandre Fenyo on 14/01/2024.
//
//

import Foundation
import CoreData


extension Trace {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trace> {
        return NSFetchRequest<Trace>(entityName: "Trace")
    }

    @NSManaged public var creation: Date?
    @NSManaged public var message: String?

}
