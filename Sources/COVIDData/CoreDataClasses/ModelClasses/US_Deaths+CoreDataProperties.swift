//
//  US_Deaths+CoreDataProperties.swift
//  
//
//  Created by Mark on 12/9/20.
//
//

import Foundation
import CoreData


extension US_Deaths {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<US_Deaths> {
        return NSFetchRequest<US_Deaths>(entityName: "US_Deaths")
    }


}
