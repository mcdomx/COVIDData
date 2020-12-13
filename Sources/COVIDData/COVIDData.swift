import Foundation
import SwiftCSV
import CoreData

public enum Scope: String {
	case us = "US"
	case global = "global"
	
	static let allCases = [us, global]
	
	func summarizationLevels(level: String?) -> [String] {
		// returns the levels in a data heirarchy down to the level provided
		var rv = [String]()
		let levels: [String]
		if level == nil { return rv }
		// preserve the prefix
		let prefix = level!.components(separatedBy: ".").dropLast().joined(separator: ".")
		
		switch self {
			case .global:
				levels = ["country_region", "province_state"]
			case .us:
				levels = ["country_region", "province_state", "admin2"]
		}
		
		for l in levels {
			rv.append(prefix+"."+l)
			if level!.hasSuffix(l) { break }
		}
		return rv
		
	}
		
	func proper() -> String {
		// Returns US or Global
		// if first letter is already capitalized, use the full rawValue
		var properCase = self.rawValue
		// otherwise; capitalize it
		if self.rawValue.first != self.rawValue.capitalized.first {
			properCase = self.rawValue.capitalized
		}
		return properCase
	}
	
	
	func uidEntityName() -> String {
		switch self {
			case .global: return "Global_UID"
			case .us: return "US_UID"
		}
	}
	
	func uidEntity() -> NSEntityDescription {
			return persistentContainer.managedObjectModel.entitiesByName[self.uidEntityName()]!
	}
	
}

public enum DataType: String {
	case deaths = "deaths"
	case confirmed = "confirmed"
	
	static let allCases = [deaths, confirmed]
	
	func proper() -> String {
		// Returns Deaths or Confirmed
		return self.rawValue.capitalized
	}
}

public enum AttributeType: UInt {
	case int16 = 100
	case int32 = 200
	case float = 600
	case string = 700
	case date = 900
	
	static func isDate(s: String) throws -> Bool {
		if type(of: try getDate(from: s)) == Date.self {
			return true
		}
		return false
	}
	
	static func getDate(from s: String) throws -> Date {
		let formatter = DateFormatter()
		formatter.dateFormat = "MM/dd/yy"
		//		formatter.timeStyle = .none
		guard let date = formatter.date(from: s) else {
			throw COVIDError.DateConversionError(key: "date", value: s)
		}
		return date
	}
	
	func from(_ s: String) -> Any? {
		switch self {
		case .int16:
			return Int(s) ?? 0
		case .int32:
			return Int32(s) ?? 0
		case .float:
			return Float(s) ?? 0.0
		case .string:
			return String(s)
		case .date:
			// set a date formatter
			let formatter = DateFormatter()
			formatter.dateFormat = "MM/dd/yy"
			guard let date = formatter.date(from: s) else {
				return nil
			}
			return date
		}
	}
	
}

public enum COVIDError: Error {
	case AttributeNotSupported(missingAttribute: String)
	case TypeNotDefined(rawValue: UInt)
	case TypeNotConvertable(value: Any, destinationType: AttributeType)
	case DateConversionError(key: Any, value: Any)
	case EntityDoesNotExist(name: String)
	case DownloadError(error: String)
}

struct DataURL {
// Provides the correct URL for a supplied scope and datatype
	let scope: Scope
	let dataType: DataType
	var URL: URL
	let url = {
		(s: Scope, d: DataType) in
		return ("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_\(d.rawValue)_\(s.rawValue).csv")
	}
	
	init(_ s:Scope, _ d:DataType) {
		self.scope = s
		self.dataType = d
		self.URL = NSURL(string: url(s, d))! as URL
	}
}

public class COVIDData {
	// Primary type for accessing Data
	// Requires initialization with appropriate scope and data type
	
	var scope: Scope
	var dataType: DataType
	var text: String
	var fileURL: URL = URL(fileURLWithPath: "")
	var url: URL {
		get { return  DataURL(scope, dataType).URL }
	}
	
	public init(scope: Scope, dataType: DataType) {
		// preferred initialization approach
		self.scope = scope
		self.dataType = dataType
		self.text = "Scope: \(self.scope) DataType: \(self.dataType)"
		downloadFile()
	}
	
	public func getCSV() -> [[String:String]] {
		
		do {
//			let csv:CSV = try CSV(url: self.url as URL)
			let csv:CSV = try CSV(url: fileURL)
			return csv.namedRows
		} catch {
			print(error)
			return [[:]]
		}
		
	}
	
	func downloadFile() {
		do {
			self.fileURL = try downloadCOVIDFile(scope: self.scope, dataType: self.dataType)
		} catch {
			print("Unable to download file:")
			print(error.localizedDescription)
		}
	}

}

public func clearEntity(entityName: String, context: NSManagedObjectContext) {
	
	let entities = persistentContainer.managedObjectModel.entities.map( {$0.name!} )
	
	if !entities.contains(entityName) {
		print("Entity: '\(entityName)' is not valid. (\(entities) ")
		return
	}
	
	let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
	let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
	
	do {
		try context.execute(deleteRequest)
		try context.save()
		print("Deleted entity: \(entityName)")
	} catch let e as NSException {
		print("could not delete DB \(e.description)")
		print("could not delete DB \(entityName)")
	} catch {
		print("could not delete DB \(entityName)")
	}
}

public func getTypeMap(scope: Scope) throws -> [String:AttributeType] {
	// returns a dict that includes each attribute name and its AttributeType
	
	let entityName = "\(scope.proper())_UID"
	guard let attributes = persistentContainer.managedObjectModel.entitiesByName[entityName]?.attributesByName.map({$0.value}) else {
		throw COVIDError.EntityDoesNotExist(name: entityName)
	}
	
	var rv = [String:AttributeType]()
	for a in attributes {
		guard let t = AttributeType(rawValue: a.attributeType.rawValue) else {
			throw COVIDError.TypeNotDefined(rawValue: a.attributeType.rawValue)
		}
		rv.updateValue(t, forKey: a.name)
	}
	
	return rv
}

public func castDataEntry(entry e: [String: String]) throws -> [[String: Any]] {
	var rv = [[String: Any]]()
	for (k, v) in e {
		if let date = AttributeType.date.from(k) as? Date, let value = AttributeType.int32.from(v) as? Int32 {
			rv.append(["date": date,
					   "value": value])
		} else {
			throw COVIDError.DateConversionError(key: k, value: v)
		}
	}
	return rv
	
}

public func castUIDEntry(entry e: [String: String], scope: Scope) throws -> [String:Any] {
	var rv = [String:Any]()
	
	let typeMap = try getTypeMap(scope: scope)
	
	for a in e.keys {
		if !typeMap.keys.contains(a) {
			throw COVIDError.AttributeNotSupported(missingAttribute: a)
		} else {
			rv[a] = typeMap[a]!.from(e[a]!)
		}
	}
		
	return rv
}

public func splitEntry(entry: [String:String], scope: Scope) throws -> ([String:String], [String:String]) {
	// Splits a full entry into the UID and STATS sequences based on the Scope (US or Global)
	
	let uidAttrs = try getTypeMap(scope: scope).keys
	return (entry.filter({uidAttrs.contains($0.key)}), entry.filter({!uidAttrs.contains($0.key)}))
}

//func getGlobalUID(uidEntry: [String:String], context moc: NSManagedObjectContext) -> NSManagedObject {
//	// will create new record if one doesn't already exist
//	var uidRecord: NSManagedObject?
//	do {
//		let req = NSFetchRequest<Global_UID>(entityName: "Global_UID")
//		req.predicate = NSPredicate(format: "(country_region = %@) AND (province_state = %@)", uidEntry["country_region"]!, uidEntry["province_state"]!)
//		let r = try moc.fetch(req)
//		if r.count > 0 {
//			uidRecord = r[0]
//		} else {
//			let newUIDEntry = try! castUIDEntry(entry: uidEntry, scope: .global)
//			uidRecord = loadUIDEntry(entityName: "Global_UID",
//									 entry: newUIDEntry,
//									 context: moc)
//		}
//	} catch {
//		print("Something bad happened when setting the Global UID record")
//		print(error)
//	}
//	
//	return uidRecord!
//	
//}

//func getUSUID(uidEntry: [String:String], context moc: NSManagedObjectContext) -> NSManagedObject {
//	// will create new record if one doesn't already exist
//	var uidRecord: NSManagedObject?
//
//	do {
//		let req = NSFetchRequest<US_UID>(entityName: "US_UID")
//		req.predicate = NSPredicate(format: "(country_region = %@) AND (province_state = %@) AND (admin2 = %@)", uidEntry["country_region"]!, uidEntry["province_state"]!, uidEntry["admin2"]!)
//		let r = try moc.fetch(req)
//		if r.count > 0 {
//			uidRecord = r[0]
//		} else {
//			let newUIDEntry = try! castUIDEntry(entry: uidEntry, scope: .us)
//			uidRecord = loadUIDEntry(entityName: "US_UID",
//									 entry: newUIDEntry,
//									 context: moc)
//		}
//	} catch {
//		print("Something bad happened when setting the US UID record")
//		print(error)
//	}
//
//	return uidRecord!
//}




public func loadUIDEntry(entry: [String:String], scope s: Scope, context moc: NSManagedObjectContext) -> UID_Abstract {
	// Return existing UID record or create a new one if it doesn't already exist
	
	// see if the entity already exists
	if let record = UID_Abstract.fetchRequest(recordWithKeyValuePairs: entry, scope: s, context: moc) {
		return record
	} else {
		let newEntry = try! castUIDEntry(entry: entry, scope: s)
		let record: UID_Abstract =  NSManagedObject(entity: s.uidEntity(), insertInto: moc) as! UID_Abstract
		record.setValuesForKeys(newEntry)
		try! moc.save()
		return record
	}
}

//func getGlobalSTATSEntry(date: Date, uid: Global_UID, context moc: NSManagedObjectContext) -> Global_STATS {
//	// returns existing entry for a date or creates a new one
//
//	guard let statsRecord = Global_STATS.getStats(forDate: date, uid: uid, context: moc) else {
//		let entity = persistentContainer.managedObjectModel.entitiesByName["Global_STATS"]
//		return NSManagedObject(entity: entity!, insertInto: moc) as! Global_STATS
//	}
//
//	return statsRecord
//}


//func loadGlobalSTATS(statsEntry: [String:String], dataType: DataType, uidRecord: Global_UID, context moc: NSManagedObjectContext) {
////	let req = NSFetchRequest<Global_UID>(entityName: "Global_UID")
////	req.predicate = NSPredicate(format: "(country_region = %@) AND (province_state = %@)", uidEntry["country_region"]!, uidEntry["province_state"]!)
////	let uid = try! moc.fetch(req)[0]
//
//	let newSTATSEntry = try! castSTATSEntry(entry: statsEntry,
//											dataType: dataType)
//	
////	let entity = persistentContainer.managedObjectModel.entitiesByName["Global_STATS"]
//
//	for entry in newSTATSEntry {
////		let newEntry: Global_STATS =  NSManagedObject(entity: entity!, insertInto: moc) as! Global_STATS
//		let newEntry = getGlobalSTATSEntry(date: entry["date"] as! Date, uid: uidRecord, context: moc)
//		newEntry.setValuesForKeys(entry)
//		uidRecord.addToStats(newEntry)
//	}
//
//}

func loadDataEntry(dataEntry: [String:String], dataType: DataType, uidRecord: UID_Abstract, context moc: NSManagedObjectContext) {
//	let req = NSFetchRequest<Global_UID>(entityName: "Global_UID")
//	req.predicate = NSPredicate(format: "(country_region = %@) AND (province_state = %@)", uidEntry["country_region"]!, uidEntry["province_state"]!)
//	let uid = try! moc.fetch(req)[0]

	let newSTATSEntry = try! castDataEntry(entry: dataEntry)

	//Global_Confirmed, Global_Deaths, US_Confirmed, US_Deaths
	var entityName: String? = nil
	if let _ = uidRecord as? Global_UID {
		switch dataType {
			case .confirmed:
				entityName = "Global_Confirmed"
			case .deaths:
				entityName = "Global_Deaths"
		}
	} else if let _ = uidRecord as? US_UID {
		switch dataType {
		case .confirmed:
			entityName = "US_Confirmed"
		case .deaths:
			entityName = "US_Deaths"
		}
	}
	
	let entity = persistentContainer.managedObjectModel.entitiesByName[entityName!]
	for entry in newSTATSEntry {
		let newEntry =  NSManagedObject(entity: entity!, insertInto: moc) as! Values_Abstract
		newEntry.setValuesForKeys(entry)
		uidRecord.addToData(newEntry)
	}
	try! moc.save()

}


//func getUSSTATSEntry(date: Date, uid: US_UID, context moc: NSManagedObjectContext) -> US_STATS {
//	// returns existing entry for a date or creates a new one
//
////	let d = AttributeType.getDate(from: date)
//
//	guard let statsRecord = US_STATS.getStats(forDate: date, uid: uid, context: moc) else {
//		let entity = persistentContainer.managedObjectModel.entitiesByName["Global_STATS"]
//		return NSManagedObject(entity: entity!, insertInto: moc) as! US_STATS
//	}
//
//	return statsRecord
//}

//func loadUSSSTATS(statsEntry: [String:String], dataType: DataType, uidRecord: US_UID, context moc: NSManagedObjectContext) {
////	let req = NSFetchRequest<US_UID>(entityName: "US_UID")
////	req.predicate = NSPredicate(format: "(country_region = %@) AND (province_state = %@) AND (admin2 = %@)", uidEntry["country_region"]!, uidEntry["province_state"]!, uidEntry["admin2"]!)
////	let uid = try! moc.fetch(req)[0]
//
//	let newSTATSEntry = try! castSTATSEntry(entry: statsEntry,
//											dataType: dataType)
//
////	let entity = persistentContainer.managedObjectModel.entitiesByName["US_STATS"]
//
//	for entry in newSTATSEntry {
//		// see if there is an entry for the date already; create one if there is not one
////		let newEntry: US_STATS =  NSManagedObject(entity: entity!, insertInto: moc) as! US_STATS
//		let newEntry = getUSSTATSEntry(date: entry["date"] as! Date, uid: uidRecord, context: moc)
//		newEntry.setValuesForKeys(entry)
//		uidRecord.addToStats(newEntry)
//	}
//}

func loadCSVLine(line: [String:String], scope s:Scope, dataType d:DataType, context moc: NSManagedObjectContext) throws {
	let (uidEntry, dataEntry) = try! splitEntry(entry: line, scope: s)
	let uidRecord = loadUIDEntry(entry: uidEntry, scope: s, context: moc)
	loadDataEntry(dataEntry: dataEntry, dataType: d, uidRecord: uidRecord, context: moc)
}

public func loadData(scope s: Scope, dataType d: DataType, context moc: NSManagedObjectContext) {
	
	let covidData = COVIDData(scope: s, dataType: d)
	
	do {
		let rows = covidData.getCSV()
		let numRows = rows.count
		for (i, entry) in rows.enumerated() {
			try loadCSVLine(line: entry, scope: s, dataType: d, context: moc)
			if i % 100 == 0 {
				print("\(i):\(numRows)", terminator: "\r")
			}
		}
		try! moc.save()
	} catch {
		print(error)
	}
	
}
