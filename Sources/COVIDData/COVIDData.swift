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
//		let prefix = level!.components(separatedBy: ".").dropLast().joined(separator: ".")
		
		switch self {
			case .global:
				levels = ["country_region", "province_state"]
			case .us:
				levels = ["country_region", "province_state", "admin2"]
		}
		
		for l in levels {
//			rv.append(prefix+"."+l)
			rv.append(l)
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
	var dataDate: Date? {
		let moc = persistentContainer.viewContext
		let req = NSFetchRequest<Values_Abstract>(entityName: "\(scope.proper())_\(dataType.proper())")
		req.predicate = NSPredicate(format: "date == date.@max")
		req.fetchLimit = 1
		req.propertiesToFetch = ["date"]
		guard let rv = try? moc.fetch(req), rv.count > 0 else { return nil }
		return rv[0].date
	}
	var latestData: Int32? {
		// create a fetch request with the selected date
		let req = NSFetchRequest<NSFetchRequestResult>(entityName: "\(scope.proper())_\(dataType.proper())")
		guard let date = dataDate else {
			return nil
		}
		req.predicate = NSPredicate(format: "date = %@", date as CVarArg)
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
		
		req.propertiesToFetch = [sumDesc]
		
		guard let results = try? persistentContainer.viewContext.fetch(req), results.count > 0 else {
			return nil
		}
		
		return (results[0] as? [String:Int32])?["sum"]
	}
	var text: String
	var fileURL: URL = URL(fileURLWithPath: "")
	var url: URL {
		get { return  DataURL(scope, dataType).URL }
	}
	
	public enum Frequency {
		case daily
		case cumulative
	}
	
	public enum LevelOfDetail: String {
		case country = "country_region"
		case state = "province_state"
		case county = "admin2"
	}
	
	public enum DateRange {
		case latest
		case all
	}
	
	public init(scope: Scope, dataType: DataType) {
		// If data does not exist, it will be loaded
		self.scope = scope
		self.dataType = dataType
		self.text = "Scope: \(self.scope) DataType: \(self.dataType)"
		
		// load data if there is none
		if dataDate == nil {
			loadData()
		}
			
	}
	
	public func data(frequency f: Frequency, levelOfDetail l: LevelOfDetail, dateRange d: DateRange, filter: String? = nil) -> ([String], [Date],[Int32])? {
				
		let req = NSFetchRequest<NSFetchRequestResult>(entityName: "\(scope.proper())_\(dataType.proper())")
		req.returnsObjectsAsFaults = false
		
		let levels = scope.summarizationLevels(level: l.rawValue).map({ "uid.\($0)"})
		levels.forEach({ level in
			req.sortDescriptors?.append(NSSortDescriptor(key: level, ascending: true))
		})
		
		// if a filter was provided, create a predicate for the request
		if filter != nil || d == .latest {
			
			var predicate = ""
			var filterArgs = [Any]()
			if filter != nil {
				filterArgs = filter!.components(separatedBy: ":")
				
				for (i, _) in filterArgs.enumerated() {
					if predicate.count > 0 { predicate.append(" AND ")}
					predicate.append("(\(levels[i])=%@)")
				}
			}
			if d == .latest {
				if predicate.count > 0 { predicate.append(" AND ")}
				predicate.append("(date=%@)")
				filterArgs.append(self.dataDate!)
				if f == .daily {
					print("WARNING: daily frequency is ignored when latest date is selected.  Response is a cumulative value.")
				}
			}
	
			req.predicate = NSPredicate(format: predicate, argumentArray: filterArgs)
			
		}
		
		// Define the groupby summarization function
		let keyPathExp = NSExpression(forKeyPath: "value")
		// supports: sum, count, min, max, and average plus other basic statistical functions
		let expression = NSExpression(forFunction: "sum:", arguments: [keyPathExp])
		let sumDesc = NSExpressionDescription()
		sumDesc.expression = expression
		sumDesc.name = "sum"
		sumDesc.expressionResultType = .integer32AttributeType
		
		req.resultType = .dictionaryResultType // required for grouping
//		if summarizationLevel != nil {
			req.propertiesToGroupBy = levels + ["date"]
//		}
		req.propertiesToFetch = levels + ["date"] + [sumDesc]
		
		guard let results = try? persistentContainer.viewContext.fetch(req), results.count > 0 else {
			return nil
		}
		
		
		
		// results is a list of dictionaries iwth "date", "sum" and the summarization levels
//		{
//			date = "2020-01-22 05:00:00 +0000";
//			sum = 0;
//			"uid.admin2" = Autauga;
//			"uid.country_region" = US;
//			"uid.province_state" = Alabama;
//		}
		
		// convert results into a tuple so they can be sorted by date
		var rvTuple = [(area: String, date: Date, value: Int32)]()
		(results as! [[String:Any]]).forEach({ record in
			var area = ""
			levels.forEach({ level in
				if area.count > 0 { area.append(":")}
				area.append(record[level] as! String)
			})
			
			rvTuple.append((area: area, date: record["date"]! as! Date, value: record["sum"]! as! Int32))
			
		})
		
		rvTuple.sort(by: { ($0.area, $0.date) < ($1.area, $1.date)})
		
		
		// create flat lists for areas, dates and values where the indexes match
		var areas = [String]()
		var dates = [Date]()
		var values = [Int32]()
		_ = rvTuple.map({ areas.append($0.area); dates.append($0.date); values.append($0.value)})
		
		// find the periodic values if the frequency is daily
		if f == .daily {
			var per_values = [Int32](repeating: 0, count: values.count)
			var current_area = ""
			for (i, a) in areas.enumerated() {
				if a == current_area {
					per_values[i] = values[i] - values[i-1]
				} else {
					current_area = a
					per_values[i] = values[i]
				}
			}
			values = per_values
		}
		
		
		return (areas, dates, values)
	}
	
	
	public func getCSV() -> [[String:String]] {
		do {
			self.fileURL = try downloadCOVIDFile(scope: self.scope, dataType: self.dataType)
			let csv:CSV = try CSV(url: self.fileURL)
			return csv.namedRows
		} catch {
			print(error)
			return [[:]]
		}
	}
	
	func loadData() {
		
		let moc = persistentContainer.viewContext
		
		do {
			let rows = self.getCSV()
			let numRows = rows.count
			for (i, entry) in rows.enumerated() {
				try loadCSVLine(line: entry, scope: scope, dataType: dataType, context: moc)
				if i % 100 == 0 {
					print("\(i):\(numRows)", terminator: "\r")
				}
			}
			try! moc.save()
		} catch {
			print(error)
		}
		
	}
	
	
	
//	func downloadFile() {
//		do {
//			self.fileURL = try downloadCOVIDFile(scope: self.scope, dataType: self.dataType)
//		} catch {
//			print("Unable to download file:")
//			print(error.localizedDescription)
//		}
//	}

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

func loadCSVLine(line: [String:String], scope s:Scope, dataType d:DataType, context moc: NSManagedObjectContext) throws {
	let (uidEntry, dataEntry) = try! splitEntry(entry: line, scope: s)
	let uidRecord = loadUIDEntry(entry: uidEntry, scope: s, context: moc)
	loadDataEntry(dataEntry: dataEntry, dataType: d, uidRecord: uidRecord, context: moc)
}

//public func loadData(scope s: Scope, dataType d: DataType) {
//
//	let covidData = COVIDData(scope: s, dataType: d)
//	let moc = persistentContainer.viewContext
//
//	do {
//		let rows = covidData.getCSV()
//		let numRows = rows.count
//		for (i, entry) in rows.enumerated() {
//			try loadCSVLine(line: entry, scope: s, dataType: d, context: moc)
//			if i % 100 == 0 {
//				print("\(i):\(numRows)", terminator: "\r")
//			}
//		}
//		try! moc.save()
//	} catch {
//		print(error)
//	}
//
//}

public func fetchLatestData(scope s:Scope, dataType d:DataType) -> Int32? {
	
	let covidData = COVIDData(scope: s, dataType: d)
	return covidData.latestData
	
}
