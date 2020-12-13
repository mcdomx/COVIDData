//
//  Global_Deaths+CoreDataProperties.swift
//  
//
//  Created by Mark on 12/9/20.
//
//

import Foundation
import CoreData


extension Global_Deaths {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Global_Deaths> {
        return NSFetchRequest<Global_Deaths>(entityName: "Global_Deaths")
    }


}
