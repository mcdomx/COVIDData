//
//  US_Confirmed+CoreDataProperties.swift
//  
//
//  Created by Mark on 12/9/20.
//
//

import Foundation
import CoreData


extension US_Confirmed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<US_Confirmed> {
        return NSFetchRequest<US_Confirmed>(entityName: "US_Confirmed")
    }


}
