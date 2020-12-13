//
//  Global_Confirmed+CoreDataProperties.swift
//  
//
//  Created by Mark on 12/9/20.
//
//

import Foundation
import CoreData


extension Global_Confirmed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Global_Confirmed> {
        return NSFetchRequest<Global_Confirmed>(entityName: "Global_Confirmed")
    }


}
