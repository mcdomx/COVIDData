//
//  Confirmed_Abstract+CoreDataProperties.swift
//  
//
//  Created by Mark on 12/9/20.
//
//

import Foundation
import CoreData


extension Confirmed_Abstract {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Confirmed_Abstract> {
        return NSFetchRequest<Confirmed_Abstract>(entityName: "Confirmed_Abstract")
    }

    @NSManaged public var uid: UID_Abstract?

}
