//
//  US_UID+CoreDataProperties.swift
//  COVIDData
//
//  Created by Mark on 12/11/20.
//
//

import Foundation
import CoreData


extension US_UID {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<US_UID> {
        return NSFetchRequest<US_UID>(entityName: "US_UID")
    }

    @NSManaged public var code3: Int32
    @NSManaged public var combined_key: String?
    @NSManaged public var fips: String?
    @NSManaged public var iso2: String?
    @NSManaged public var iso3: String?
    @NSManaged public var population: Int32
    @NSManaged public var uid: String?

}
