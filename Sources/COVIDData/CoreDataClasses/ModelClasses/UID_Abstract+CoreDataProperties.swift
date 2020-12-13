//
//  UID_Abstract+CoreDataProperties.swift
//  COVIDData
//
//  Created by Mark on 12/11/20.
//
//

import Foundation
import CoreData


extension UID_Abstract {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UID_Abstract> {
        return NSFetchRequest<UID_Abstract>(entityName: "UID_Abstract")
    }

    @NSManaged public var country_region: String?
    @NSManaged public var lat: Float
    @NSManaged public var long_: Float
    @NSManaged public var province_state: String?
    @NSManaged public var admin2: String?
    @NSManaged public var confirmed: NSSet?
    @NSManaged public var deaths: NSSet?

}

// MARK: Generated accessors for confirmed
extension UID_Abstract {

    @objc(addConfirmedObject:)
    @NSManaged public func addToConfirmed(_ value: Confirmed_Abstract)

    @objc(removeConfirmedObject:)
    @NSManaged public func removeFromConfirmed(_ value: Confirmed_Abstract)

    @objc(addConfirmed:)
    @NSManaged public func addToConfirmed(_ values: NSSet)

    @objc(removeConfirmed:)
    @NSManaged public func removeFromConfirmed(_ values: NSSet)

}

// MARK: Generated accessors for deaths
extension UID_Abstract {

    @objc(addDeathsObject:)
    @NSManaged public func addToDeaths(_ value: Deaths_Abstract)

    @objc(removeDeathsObject:)
    @NSManaged public func removeFromDeaths(_ value: Deaths_Abstract)

    @objc(addDeaths:)
    @NSManaged public func addToDeaths(_ values: NSSet)

    @objc(removeDeaths:)
    @NSManaged public func removeFromDeaths(_ values: NSSet)

}
