//
//  Values_Abstract+CoreDataProperties.swift
//  
//
//  Created by Mark on 12/9/20.
//
//

import Foundation
import CoreData


extension Values_Abstract {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Values_Abstract> {
        return NSFetchRequest<Values_Abstract>(entityName: "Values_Abstract")
    }

    @NSManaged public var date: Date?
    @NSManaged public var value: Int32

}
