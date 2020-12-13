//
//  Global_UID+CoreDataProperties.swift
//  
//
//  Created by Mark on 12/9/20.
//
//

import Foundation
import CoreData


extension Global_UID {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Global_UID> {
        return NSFetchRequest<Global_UID>(entityName: "Global_UID")
    }


}
