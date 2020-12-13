//
//  File.swift
//  
//
//  Created by Mark on 12/9/20.
//

import Foundation
import CoreData

extension UID_Abstract {
	@objc(addDataObject:)
	public func addToData(_ value: Values_Abstract) {
		if let v = value as? Deaths_Abstract {
			self.addToDeaths(v)
		} else if let v = value as? Confirmed_Abstract {
			self.addToConfirmed(v)
		}
	}
	
	@objc(removeDataObject:)
	public func removeFromData(_ value: Values_Abstract) {
		if let v = value as? Deaths_Abstract {
			self.removeFromDeaths(v)
		} else if let v = value as? Confirmed_Abstract {
			self.removeFromConfirmed(v)
		}
	}
	
	@objc(addData:)
	public func addToData(_ values: NSSet) {
		if let _ = values.anyObject() as? Deaths_Abstract {
			self.addToDeaths(values)
		} else if let _ = values.anyObject() as? Confirmed_Abstract {
			self.addToConfirmed(values)
		}
	}
	
	@objc(removeData:)
	public func removeFromData(_ values: NSSet) {
		
	}
	
	class public func fetchRequest(country_region: String, province_state: String, admin2: String = "", scope s: Scope, context moc: NSManagedObjectContext) -> UID_Abstract? {
		
		let req: NSFetchRequest<UID_Abstract>
		switch s {
		case .global:
			req = NSFetchRequest<UID_Abstract>(entityName: "Global_UID")
			req.predicate = NSPredicate(format: "(country_region == %@) AND (province_state == %@)", country_region, province_state)
		case .us:
			req = NSFetchRequest<UID_Abstract>(entityName: "US_UID")
			req.predicate = NSPredicate(format: "(country_region == %@) AND (province_state == %@) AND (admin2 == %@)", country_region, province_state, admin2)
		}
		
		req.fetchLimit = 1
		
		guard let rv = try? moc.fetch(req) else {
			return nil
		}

		if rv.count == 0 { return nil }

		return rv[0]
	}
	
	class public func fetchRequest(recordWithKeyValuePairs dict: [String: String], scope s:Scope, context moc: NSManagedObjectContext) -> UID_Abstract? {
				
		switch s {
			case .global:
				let scopeKeys: Set = ["country_region", "province_state"]
				if scopeKeys.isSubset(of: dict.keys) {
					return fetchRequest(country_region: dict["country_region"]!, province_state: dict["province_state"]!, scope: s, context: moc)
				} else {
					return nil
				}
			case .us:
				let scopeKeys: Set = ["country_region", "province_state", "admin2"]
				if scopeKeys.isSubset(of: dict.keys) {
					return fetchRequest(country_region: dict["country_region"]!, province_state: dict["province_state"]!, admin2: dict["admin2"]!, scope: s, context: moc)
				} else {
					return nil
				}
		}
		
		
	}
	
	class public func fetchAll(scope s:Scope, context moc: NSManagedObjectContext) -> [UID_Abstract]? {
		
		var req: NSFetchRequest<UID_Abstract>
		
		switch s {
		case .global:
			req = NSFetchRequest<UID_Abstract>(entityName: "Global_UID")
		case .us:
			req = NSFetchRequest<UID_Abstract>(entityName: "US_UID")
		}
		
		req.sortDescriptors = [NSSortDescriptor(key: "country_region", ascending: true),
							   NSSortDescriptor(key: "province_state", ascending: true)]
		
		return try? moc.fetch(req)
		
	}
	
	public class func getLatestDate(scope s: Scope, dataType d: DataType, context moc: NSManagedObjectContext) -> Date? {
		let req = NSFetchRequest<Values_Abstract>(entityName: "\(s.proper())_\(d.proper())")
		req.predicate = NSPredicate(format: "date == date.@max")
		req.fetchLimit = 1
		req.propertiesToFetch = ["date"]

		return try? moc.fetch(req)[0].date!
	}
	
	public class func fetchCumulativeData(forDate: Date?, scope s: Scope, dataType d: DataType, context moc: NSManagedObjectContext) -> [Values_Abstract]? {
		
		var date: Date
		if forDate == nil {
			date = getLatestDate(scope: s, dataType: d, context: moc)!
		} else {
			date = forDate!
		}
		
		let req = NSFetchRequest<Values_Abstract>(entityName: "\(s.proper())_\(d.proper())")
		req.predicate = NSPredicate(format: "date = %@", date as CVarArg)
		req.sortDescriptors = [NSSortDescriptor(key: "uid.country_region", ascending: true),
							   NSSortDescriptor(key: "uid.province_state", ascending: true)]
		
		guard let results = try? moc.fetch(req), results.count > 0 else {
			return nil
		}
		
		return results
		
	}
	
	public class func fetchCumulativeDataSummarized(forDate: Date?, scope s: Scope, dataType d: DataType, summarizationLevel: String?, context moc: NSManagedObjectContext) -> [[String:Any]]? {
		
		// get the latest data
		var date: Date
		if forDate == nil {
			date = getLatestDate(scope: s, dataType: d, context: moc)!
		} else {
			date = forDate!
		}
		
		// create a fetch request with the selected date
		let req = NSFetchRequest<NSFetchRequestResult>(entityName: "\(s.proper())_\(d.proper())")
		req.predicate = NSPredicate(format: "date = %@", date as CVarArg)
		
		let levels = s.summarizationLevels(level: summarizationLevel)
		
		
		// Sort the request by the levels
		levels.forEach({ level in
			req.sortDescriptors?.append(NSSortDescriptor(key: "uid."+level, ascending: true))
		})
		
		req.returnsObjectsAsFaults = false
		
		req.resultType = .dictionaryResultType

		// Define the groupby summarization function
		let keyPathExp = NSExpression(forKeyPath: "value")
		// supports: sum, count, min, max, and average plus other basic statistical functions
		let expression = NSExpression(forFunction: "sum:", arguments: [keyPathExp])
		let sumDesc = NSExpressionDescription()
		sumDesc.expression = expression
		sumDesc.name = "sum"
		sumDesc.expressionResultType = .integer32AttributeType
		
		if summarizationLevel != nil {
			req.propertiesToGroupBy = levels
		}
		req.propertiesToFetch = levels + [sumDesc]
//		req.propertiesToFetch = [sumDesc]
		
		guard let results = try? moc.fetch(req), results.count > 0 else {
			return nil
		}
		
		return results as? [[String:Any]]
		
	}
	
	
	public class func fetchLatestData(scope s: Scope, dataType d: DataType, context moc: NSManagedObjectContext) -> [Values_Abstract]? {
		
		guard let date = self.getLatestDate(scope: s, dataType: d, context: moc) else {
			return nil
		}
		
		return fetchCumulativeData(forDate: date, scope: s, dataType: d, context: moc)
	}
	
	
}
