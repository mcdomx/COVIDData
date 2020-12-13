//
//  Deaths_Abstract+CoreDataProperties.swift
//  
//
//  Created by Mark on 12/9/20.
//
//

import Foundation
import CoreData


extension Deaths_Abstract {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Deaths_Abstract> {
        return NSFetchRequest<Deaths_Abstract>(entityName: "Deaths_Abstract")
    }

    @NSManaged public var uid: UID_Abstract?

}
