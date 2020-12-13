////
////  File.swift
////  
////
////  Created by Mark on 12/8/20.
////
//
//import Foundation
//import CoreData
//
//extension Global_STATS {
//
//	@nonobjc public class func getLatestDate(context moc: NSManagedObjectContext) -> Date? {
//		let req = NSFetchRequest<Global_STATS>(entityName: "Global_STATS")
//		req.predicate = NSPredicate(format: "date == date.@max")
//		req.fetchLimit = 1
//		req.propertiesToFetch = ["date"]
//		
//
//		return try? moc.fetch(req)[0].date!
//	}
//	
//	@nonobjc public class func getStats(forDate date:Date, context moc: NSManagedObjectContext) -> [Global_STATS]? {
//		let req = NSFetchRequest<Global_STATS>(entityName: "Global_STATS")
//		req.sortDescriptors = [NSSortDescriptor(key: "uid.country_region", ascending: true),
//							   NSSortDescriptor(key: "uid.province_state", ascending: true)]
//		req.predicate = NSPredicate(format: "date == %@", date as CVarArg)
//		
//		return try? moc.fetch(req)
//			
//	}
//	
//	@nonobjc public class func getStats(forDate date:Date, uid: Global_UID, context moc: NSManagedObjectContext) -> Global_STATS? {
//		let req = NSFetchRequest<Global_STATS>(entityName: "Global_STATS")
//		req.sortDescriptors = [NSSortDescriptor(key: "uid.country_region", ascending: true),
//							   NSSortDescriptor(key: "uid.province_state", ascending: true)]
//		req.predicate = NSPredicate(format: "(date == %@) AND (uid = %@)", date as CVarArg, uid)
//		req.fetchLimit = 1
//		
//		
//		guard let rv = try? moc.fetch(req) else {
//			return nil
//		}
//		
//		if rv.count == 0 { return nil }
//		
//		return rv[0]
//		
//	}
//	
//
//}
