import XCTest
import SwiftUI
import CoreData
@testable import COVIDData

final class COVIDDataTests: XCTestCase {
    func testInit() {
		XCTAssertEqual(COVIDData(scope: Scope.us, dataType: DataType.confirmed).dataType, DataType.confirmed)
		XCTAssertEqual(COVIDData(scope: Scope.us, dataType: DataType.confirmed).scope, Scope.us)
    }
	
	func testURL() {
		var cd = COVIDData(scope: Scope.us, dataType: DataType.confirmed)
		var v_url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv"
		XCTAssertEqual(cd.url.absoluteString, v_url)
		
		cd = COVIDData(scope: Scope.us, dataType: DataType.deaths)
		v_url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"
		XCTAssertEqual(cd.url.absoluteString, v_url)
		
		cd = COVIDData(scope: Scope.global, dataType: DataType.confirmed)
		v_url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"
		XCTAssertEqual(cd.url.absoluteString, v_url)
		
		cd = COVIDData(scope: Scope.global, dataType: DataType.deaths)
		v_url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv"
		XCTAssertEqual(cd.url.absoluteString, v_url)
		
	}
	
	func testGetCSV() {
		for s in Scope.allCases {
			for d in DataType.allCases {
				let cd = COVIDData(scope: s, dataType: d)
				let csv = cd.getCSV()
				XCTAssertTrue(csv.count > 0)
			}
		}
	}
	
	func testDataSetup() {
		XCTAssertNotNil(persistentContainer)
	}
	
	func clearAllEntities() {
		for e in ["US_UID","US_Confirmed","US_Deaths", "Global_UID", "Global_Confirmed", "Global_Deaths"] {
			clearEntity(entityName: e, context: persistentContainer.viewContext)
		}
	}
	
	func testClearEntityData() {
		clearAllEntities()
	}
	
	func testTypeMap() throws {
		XCTAssertNoThrow(try getTypeMap(scope: Scope.global))
		XCTAssertNoThrow(try getTypeMap(scope: Scope.us))
	}
	
	func testCastGlobalUIDEntry() {
		let testEntry1: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222"]
		XCTAssertNoThrow(try castUIDEntry(entry: testEntry1, scope: Scope.global))
		
		let testEntry2: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222", "xxx": "yyy"]
		XCTAssertThrowsError(try castUIDEntry(entry: testEntry2, scope: Scope.global))
		
	}
	
	func testCastUSUIDEntry() {
		let testEntry1: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222", "admin2": "admin2Field", "code3": "123", "combined_key": "Eraseland_Deleteville", "fips": "IamFIPS", "iso2": "US", "iso3": "USA", "uid": "1000234"]
		XCTAssertNoThrow(try castUIDEntry(entry: testEntry1, scope: Scope.us))
		
		let testEntry2: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222", "admin2": "admin2Field", "code3": "123", "combined_key": "Eraseland_Deleteville", "fips": "IamFIPS", "iso2": "US", "iso3": "USA", "uid": "1000234", "unwantedField": "unwantedValue"]
		XCTAssertThrowsError(try castUIDEntry(entry: testEntry2, scope: Scope.us))
	}
	

	func testCastGlobalSTATSEntry() {
		let testEntry1:[String: String] = ["12/1/20": "123", "12/2/2020": "456"]
		XCTAssertNoThrow(try castDataEntry(entry: testEntry1))
		
		let testEntry2:[String: String] = ["2020/1/20": "123", "12/2/2020": "456"]
		XCTAssertThrowsError(try castDataEntry(entry: testEntry2))
	}
	
	func testCastUSSTATSEntry() {
		let testEntry1:[String: String] = ["12/1/20": "123", "12/2/2020": "456"]
		XCTAssertNoThrow(try castDataEntry(entry: testEntry1))
		
		let testEntry2:[String: String] = ["2020/1/20": "123", "12/2/2020": "456"]
		XCTAssertThrowsError(try castDataEntry(entry: testEntry2))
	}
	
	
	func makeAndGetTestGlobalUID(moc: NSManagedObjectContext) -> NSManagedObject {
		
		clearEntity(entityName: "Global_UID", context: persistentContainer.viewContext)
		
		let entry: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222"]
		
		let uidRecord = loadUIDEntry(entry: entry, scope: .global, context: moc)
		return uidRecord
	}
	
	func makeAndGetTestUSUID(moc: NSManagedObjectContext) -> UID_Abstract {
		
		clearEntity(entityName: "US_UID", context: persistentContainer.viewContext)
		
		let entry: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222", "admin2": "CountyName", "code3": "123", "combined_key": "Eraseland_Deleteville", "fips": "IamFIPS", "iso2": "US", "iso3": "USA", "uid": "1000234"]
		
		let uidRecord = loadUIDEntry(entry: entry, scope: .us, context: moc)
		try! moc.save()

		return uidRecord
	}
	
	
	func testSplitGlobalEntry() {
		let testEntry: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222", "12/1/20": "123", "12/2/20": "456"]
		
		XCTAssertNoThrow(try splitEntry(entry: testEntry, scope: Scope.global))
		
		let (uid, stats) = try! splitEntry(entry: testEntry, scope: Scope.global)
		XCTAssertEqual(uid.keys.map({$0}).sorted(), ["country_region", "province_state", "lat", "long_"].sorted())
		XCTAssertEqual(stats.keys.map({$0}).sorted(), ["12/1/20", "12/2/20"].sorted())
	}
	

	
	
	func testAddGlobalUIDEntry() {
		
		let globalUID: Global_UID = makeAndGetTestGlobalUID(moc: persistentContainer.viewContext) as! Global_UID
		
		XCTAssertEqual(globalUID.country_region, "Eraseland")
		XCTAssertEqual(globalUID.province_state, "Deleteville")
		XCTAssertEqual(globalUID.lat, 1.111)
		XCTAssertEqual(globalUID.long_, 2.222)
	}
	
	func testAddUSUIDEntry() {
		
		let USUID: US_UID = makeAndGetTestUSUID(moc: persistentContainer.viewContext) as! US_UID
		
		XCTAssertEqual(USUID.country_region, "Eraseland")
		XCTAssertEqual(USUID.province_state, "Deleteville")
		XCTAssertEqual(USUID.admin2, "CountyName")
		XCTAssertEqual(USUID.code3, 123)
		XCTAssertEqual(USUID.combined_key, "Eraseland_Deleteville")
		XCTAssertEqual(USUID.fips, "IamFIPS")
		XCTAssertEqual(USUID.iso2, "US")
		XCTAssertEqual(USUID.iso3, "USA")
		XCTAssertEqual(USUID.lat, 1.111)
		XCTAssertEqual(USUID.long_, 2.222)
	}
	
	func testSplitUSEntry() {
		let testEntry: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222", "admin2": "admin2Field", "code3": "123", "combined_key": "Eraseland_Deleteville", "fips": "IamFIPS", "iso2": "US", "iso3": "USA", "uid": "1000234", "12/1/20": "123", "12/2/20": "456"]
		
		XCTAssertNoThrow(try splitEntry(entry: testEntry, scope: Scope.us))
		
		let (uid, stats) = try! splitEntry(entry: testEntry, scope: Scope.us)
		XCTAssertEqual(uid.keys.map({$0}).sorted(), ["country_region", "province_state", "lat", "long_", "admin2", "code3", "combined_key", "fips", "iso2", "iso3", "uid"].sorted())
		XCTAssertEqual(stats.keys.map({$0}).sorted(), ["12/1/20", "12/2/20"].sorted())
	}
	
	func testGlobalAddLine() {
		let moc = persistentContainer.viewContext
		clearEntity(entityName: "Global_Deaths", context: persistentContainer.viewContext)
		clearEntity(entityName: "Global_Confirmed", context: persistentContainer.viewContext)
		clearEntity(entityName: "Global_UID", context: persistentContainer.viewContext)
		
		let testEntryConf: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222", "12/1/20": "123", "12/2/20": "456"]
		let testEntryDeaths: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "lat": "1.111", "long_": "2.222", "12/1/20": "12", "12/2/20": "45"]

		let (uidEntry1, confEntry) = try! splitEntry(entry: testEntryConf, scope: Scope.global)
		
		let uidRecord1 = loadUIDEntry(entry: uidEntry1, scope: .global, context: moc)

		XCTAssertEqual(uidRecord1.country_region, "Eraseland")
		XCTAssertEqual(uidRecord1.province_state, "Deleteville")
		XCTAssertEqual(uidRecord1.lat, 1.111)
		XCTAssertEqual(uidRecord1.long_, 2.222)

		loadDataEntry(dataEntry: confEntry, dataType: .confirmed, uidRecord: uidRecord1, context: moc)

		var newUID = UID_Abstract.fetchRequest(country_region: "Eraseland", province_state: "Deleteville", scope: .global ,context: moc)
		
		XCTAssertNotNil(newUID)
		XCTAssert(newUID?.confirmed?.count == 2)
		XCTAssert(newUID?.deaths?.count == 0)
		
		let (uidEntry2, deathEntry) = try! splitEntry(entry: testEntryDeaths, scope: Scope.global)
		let uidRecord2 = loadUIDEntry(entry: uidEntry2, scope: .global, context: moc)

		// Make sure we didn't add a new UID record
		XCTAssertEqual(uidRecord1, uidRecord2)
		
		// Load the death data
		loadDataEntry(dataEntry: deathEntry, dataType: .deaths, uidRecord: uidRecord2, context: moc)
		
		// Get refershed instance of the UID
		newUID = UID_Abstract.fetchRequest(country_region: "Eraseland", province_state: "Deleteville", scope: .global ,context: moc)
		
		XCTAssert(newUID?.confirmed?.count == 2)
		XCTAssert(newUID?.deaths?.count == 2)
		
		// Test, again, to make sure that we only have one Global_UID in the db
		let req = NSFetchRequest<Global_UID>(entityName: "Global_UID")
		req.predicate = NSPredicate(format: "(country_region == %@) AND (province_state == %@)", "Eraseland", "Deleteville")
		let response = try! moc.fetch(req)
		XCTAssert(response.count == 1)

	}

	func testUSAddLine() {
		let moc = persistentContainer.viewContext
		clearEntity(entityName: "US_Deaths", context: persistentContainer.viewContext)
		clearEntity(entityName: "US_Confirmed", context: persistentContainer.viewContext)
		clearEntity(entityName: "US_UID", context: persistentContainer.viewContext)
		
		let testEntryConf: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "admin2": "CowardCounty", "lat": "1.111", "long_": "2.222", "12/1/20": "123", "12/2/20": "456"]
		let testEntryDeaths: [String:String] = ["country_region": "Eraseland", "province_state": "Deleteville", "admin2": "CowardCounty", "lat": "1.111", "long_": "2.222", "12/1/20": "12", "12/2/20": "45"]
		
		let (uidEntry1, confEntry) = try! splitEntry(entry: testEntryConf, scope: .us)
		
		let uidRecord1 = loadUIDEntry(entry: uidEntry1, scope: .us, context: moc) as! US_UID
		
		XCTAssertEqual(uidRecord1.country_region, "Eraseland")
		XCTAssertEqual(uidRecord1.province_state, "Deleteville")
		XCTAssertEqual(uidRecord1.admin2, "CowardCounty")
		XCTAssertEqual(uidRecord1.lat, 1.111)
		XCTAssertEqual(uidRecord1.long_, 2.222)
		
		loadDataEntry(dataEntry: confEntry, dataType: .confirmed, uidRecord: uidRecord1, context: moc)
		
		var newUID = UID_Abstract.fetchRequest(country_region: "Eraseland", province_state: "Deleteville", admin2: "CowardCounty", scope: .us ,context: moc)
		
		XCTAssertNotNil(newUID)
		XCTAssert(newUID?.confirmed?.count == 2)
		XCTAssert(newUID?.deaths?.count == 0)
		
		let (uidEntry2, deathEntry) = try! splitEntry(entry: testEntryDeaths, scope: Scope.us)
		let uidRecord2 = loadUIDEntry(entry: uidEntry2, scope: .us, context: moc)
		
		// Make sure we didn't add a new UID record
		XCTAssertEqual(uidRecord1, uidRecord2)
		
		// Load the death data
		loadDataEntry(dataEntry: deathEntry, dataType: .deaths, uidRecord: uidRecord2, context: moc)
		
		// Get refershed instance of the UID
		newUID = UID_Abstract.fetchRequest(country_region: "Eraseland", province_state: "Deleteville", admin2: "CowardCounty",  scope: .us ,context: moc)
		
		XCTAssert(newUID?.confirmed?.count == 2)
		XCTAssert(newUID?.deaths?.count == 2)
		
		// Test, again, to make sure that we only have one Global_UID in the db
		let req = NSFetchRequest<US_UID>(entityName: "US_UID")
		req.predicate = NSPredicate(format: "(country_region == %@) AND (province_state == %@) AND (admin2 == %@)", "Eraseland", "Deleteville", "CowardCounty")
		let response = try! moc.fetch(req)
		XCTAssert(response.count == 1)
		
	}

	func testDownload() {
		for s in Scope.allCases {
			for d in DataType.allCases {
				do {
					let downloadedFile = try downloadCOVIDFile(scope: s, dataType: d)
					XCTAssertTrue(try downloadedFile.checkResourceIsReachable())
					try FileManager.default.removeItem(at: downloadedFile)
				} catch COVIDError.DownloadError(let error) {
					print(error)
				} catch {
					print("Some unknown error handled")
					print(error.localizedDescription)
				}
			}
		}
	}

	func testHeaderMap() {
		let headerMap = [
			"Province/State": "province_state",
			"Country/Region": "country_region",
			"Lat": "lat",
			"Long": "long_",
			"Long_": "long_",
			"UID": "uid",
			"iso2": "iso2",
			"iso3": "iso3",
			"code3": "code3",
			"Admin2": "admin2",
			"Population": "population",
			"Province_State": "province_state",
			"Country_Region": "country_region",
			"Combined_Key": "combined_key",
		]

		let newHeader = mapHeader(line: headerMap.map({$0.key}).joined(separator: ","))

		XCTAssertEqual(headerMap.map({$0.value}).joined(separator: ","), newHeader)
	}
//
//	func testLoadGlobalData() {
//		let moc = persistentContainer.viewContext
//		clearEntity(entityName: "Global_Deaths", context: moc)
//		clearEntity(entityName: "Global_Confirmed", context: moc)
//		clearEntity(entityName: "Global_UID", context: moc)
//
//		loadData(scope: .global, dataType: .confirmed)
//		loadData(scope: .global, dataType: .deaths)
//
//		let req1 = NSFetchRequest<Global_UID>(entityName: "Global_UID")
//		let uidRecords = try! moc.fetch(req1)
//		print("UID Records Loaded: \(uidRecords.count)")
//		XCTAssertTrue(uidRecords.count>1)
//
//		let req2 = NSFetchRequest<Global_Confirmed>(entityName: "Global_Confirmed")
//		let confRecords = try! moc.fetch(req2)
//		print("Confrimed Data Records Loaded: \(confRecords.count)")
//		XCTAssertTrue(confRecords.count>1)
//
//		let req3 = NSFetchRequest<Global_Deaths>(entityName: "Global_Deaths")
//		let deathRecords = try! moc.fetch(req3)
//		print("Deaths Data Records Loaded: \(deathRecords.count)")
//		XCTAssertTrue(deathRecords.count>1)
//
//	}
	
//	func testLoadUSData() {
//		let moc = persistentContainer.viewContext
//		clearEntity(entityName: "US_Deaths", context: moc)
//		clearEntity(entityName: "US_Confirmed", context: moc)
//		clearEntity(entityName: "US_UID", context: moc)
//
//		loadData(scope: .us, dataType: .confirmed)
//		loadData(scope: .us, dataType: .deaths)
//
//		let req1 = NSFetchRequest<US_UID>(entityName: "US_UID")
//		let uidRecords = try! moc.fetch(req1)
//		print("UID Records Loaded: \(uidRecords.count)")
//		XCTAssertTrue(uidRecords.count>1)
//
//		let req2 = NSFetchRequest<US_Confirmed>(entityName: "US_Confirmed")
//		let confRecords = try! moc.fetch(req2)
//		print("Confrimed Data Records Loaded: \(confRecords.count)")
//		XCTAssertTrue(confRecords.count>1)
//
//		let req3 = NSFetchRequest<US_Deaths>(entityName: "US_Deaths")
//		let deathRecords = try! moc.fetch(req3)
//		print("Deaths Data Records Loaded: \(deathRecords.count)")
//		XCTAssertTrue(deathRecords.count>1)
//	}
	

	func testFetchAllGlobal() {
		let moc = persistentContainer.viewContext
		let uidRecords = UID_Abstract.fetchAll(scope: .global, context: moc)
		
		print("Number of Global Records: \(uidRecords!.count)")
		XCTAssertNotNil(uidRecords)
		XCTAssertTrue(uidRecords!.count > 0)
	}
	
	func testFetchAllUS() {
		let moc = persistentContainer.viewContext
		let uidRecords = UID_Abstract.fetchAll(scope: .us, context: moc)
		
		print("Number of US Records: \(uidRecords!.count)")
		XCTAssertNotNil(uidRecords)
		XCTAssertTrue(uidRecords!.count > 0)
	}
	
	func testGetLatestDate() {
		let moc = persistentContainer.viewContext
		let date1 = UID_Abstract.getLatestDate(scope: .global, dataType: .confirmed, context: moc)
		let date2 = UID_Abstract.getLatestDate(scope: .us, dataType: .confirmed, context: moc)
		let date3 = UID_Abstract.getLatestDate(scope: .global, dataType: .deaths, context: moc)
		let date4 = UID_Abstract.getLatestDate(scope: .us, dataType: .deaths, context: moc)
		
		XCTAssertNotNil(date1)
		XCTAssertNotNil(date2)
		XCTAssertNotNil(date3)
		XCTAssertNotNil(date4)
		
		print(date1!.description)
		print(date2!.description)
		print(date3!.description)
		print(date4!.description)

	}
	
	func testFetchLatestGlobalData() {
		let moc = persistentContainer.viewContext
		let allConf = UID_Abstract.fetchLatestData(scope: .global, dataType: .confirmed, context: moc) as! [Confirmed_Abstract]
		let allDeaths = UID_Abstract.fetchLatestData(scope: .global, dataType: .deaths, context: moc) as! [Deaths_Abstract]
		var confData = [UID_Abstract:Int32]()
		var deathData = [UID_Abstract:Int32]()
		
		let uidRecords = UID_Abstract.fetchAll(scope: .global, context: moc)!
		
		allConf.forEach({ e in confData.updateValue(e.value, forKey: e.uid!) })
		allDeaths.forEach({ e in deathData.updateValue(e.value, forKey: e.uid!) })

		for uid in uidRecords {
			print("Country: \(uid.country_region!):\(uid.province_state ?? "n/a") Confirmed: \(confData[uid]!)  Deaths: \(deathData[uid]!)")
		}

	}

	func testFetchLatestUSData() {
		let moc = persistentContainer.viewContext
		let allConf = UID_Abstract.fetchLatestData(scope: .us, dataType: .confirmed, context: moc) as! [Confirmed_Abstract]
		let allDeaths = UID_Abstract.fetchLatestData(scope: .us, dataType: .deaths, context: moc) as! [Deaths_Abstract]
		var confData = [UID_Abstract:Int32]()
		var deathData = [UID_Abstract:Int32]()
		
		let uidRecords = UID_Abstract.fetchAll(scope: .us, context: moc)! as! [US_UID]
		
		allConf.forEach({ e in confData.updateValue(e.value, forKey: e.uid!) })
		allDeaths.forEach({ e in deathData.updateValue(e.value, forKey: e.uid!) })
		
		for uid in uidRecords {
			print("Country: \(uid.country_region!):\(uid.province_state ?? "n/a"):\(uid.admin2!) Confirmed: \(confData[uid]!)  Deaths: \(deathData[uid]!)")
		}
		
	}
	
	func testFetchGroupedData() {
		let moc = persistentContainer.viewContext
		let summarizationLevel: String? = "uid.country_region"
		let scope = Scope.global
		let dataType = DataType.confirmed
		let results = UID_Abstract.fetchCumulativeDataSummarized(forDate: nil, scope: scope, dataType: dataType, summarizationLevel: summarizationLevel, context: moc)
		
		let levels = scope.summarizationLevels(level: summarizationLevel)
		
		XCTAssertNotNil(results)
		XCTAssertTrue(results!.count > 0 || summarizationLevel == nil)
		
		for r in results! {
			var output: [String] = []
			for l in levels {
				output.append(r[l] as! String)
			}
			output.append("\(r["sum"]!)")

			print(output.joined(separator: ":"))

		}
	}
	
	func testfetchScopeLatestData() {
		
		for s in Scope.allCases {
			for d in DataType.allCases {
				let rv = fetchLatestData(scope: s, dataType: d)
				XCTAssertNotNil(rv)
				if rv != nil {
					print("\(s):\(d) = \(rv!)")
				} else {
					print("\(s):\(d) = FAILED")
				}
			}
		}
	}
	
	func testFetchScopeData() {
		
		let covidData = COVIDData(scope: .us, dataType: .confirmed)
		let (areas, dates, values) = covidData.data(frequency: .daily, levelOfDetail: .county, dateRange: .latest, filter: "US:Iowa:Scott")!
		
		for (i, a) in areas.enumerated() {
			print(a, dates[i], values[i])
		}
		
		
	}
	
	
    static var allTests = [
        ("testInit", testInit),
		("testURL", testURL),
		("testGetCSV", testGetCSV),
		("testDataSetup", testDataSetup),
		("testClearEntityData", testClearEntityData),
		("testTypeMap", testTypeMap),
		("testCastGlobalUIDEntry", testCastGlobalUIDEntry),
		("testCastUSUIDEntry", testCastUSUIDEntry),
		("testCastGlobalSTATSEntry", testCastGlobalSTATSEntry),
		("testCastUSSTATSEntry", testCastUSSTATSEntry),
		("testSplitGlobalEntry", testSplitGlobalEntry),
		("testSplitUSEntry", testSplitUSEntry),
		("testAddGlobalUIDEntry", testAddGlobalUIDEntry),
		("testAddUSUIDEntry", testAddUSUIDEntry),
//		("testGlobalAddLine", testGlobalAddLine),
//		("testUSAddLine", testUSAddLine),
//		("testHeaderMap", testHeaderMap),
//		("testDownload", testDownload),
    ]
}
