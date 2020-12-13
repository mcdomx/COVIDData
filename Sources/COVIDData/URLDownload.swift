//
//  File.swift
//  
//
//  Created by Mark on 12/6/20.
//

import Foundation

func mapHeader(line: String) -> String {
	var components = line.components(separatedBy: ",")
	
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
		"FIPS": "fips",
		"Population": "population",
		"Province_State": "province_state",
		"Country_Region": "country_region",
		"Combined_Key": "combined_key",
	]
	
	for (i, c) in components.enumerated() {
		if let newText = headerMap[c] {
			components[i] = newText
		}
	}
	
	return components.joined(separator: ",")
	
}

func formatFileHeader(fileURL: URL) throws {
	if try fileURL.checkResourceIsReachable() {
		// map the header row
		var lines = try String(contentsOf: fileURL, encoding: .utf8).components(separatedBy: "\n")
		
		// first line is the header
		lines[0] = mapHeader(line: lines[0])
		
		// repalce the file
		try lines.joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)
		
	} else {
		throw COVIDError.DownloadError(error: "File is not reachable: \(fileURL)")
	}
	
}


public func downloadCOVIDFile(scope: Scope, dataType: DataType) throws -> URL {
	let sourceURL = DataURL(scope, dataType).URL
//	let filename = url.lastPathComponent
//	let targetLocationURL = Bundle.module.resourceURL
	let destinationURL = Bundle.module.resourceURL!.appendingPathComponent(sourceURL.lastPathComponent)
	
	let sessionConfig = URLSessionConfiguration.default
	sessionConfig.waitsForConnectivity = true
	sessionConfig.allowsCellularAccess = true
	
	let session = URLSession(configuration: sessionConfig)
	
	let request = URLRequest(url: sourceURL)
	
	let task = session.downloadTask(with: request) {
		(tempLocalURL, response, error) in
		if let tempLocalURL = tempLocalURL, error == nil {
			// success
			if let statusCode = (response as? HTTPURLResponse)?.statusCode {
				print("Download Status: \(statusCode)")
			}
			
			// move from temp location to final destination
			do {
				// delete file if it exists
				try? FileManager.default.removeItem(at: destinationURL)
				// move the temp file to the final destination
				try FileManager.default.moveItem(at: tempLocalURL, to: destinationURL)
				print("File is available at:")
				print("\(destinationURL)")
			} catch COVIDError.DownloadError(let error) {
				if let status = (response as? HTTPURLResponse)?.statusCode {
					print("Download Status: \(status)")
				}
				print(error)
			} catch {
				print("Unable to move file:")
				print("\tfrom: \(tempLocalURL)")
				print("\tto: \(destinationURL)")
				print(error)
			}
			
		} else {
			print("Download Error:")
			print("URL: \(sourceURL.absoluteString)")
			print("\(error!.localizedDescription)")
		}
	}
	
	task.resume()
	
	while !task.progress.isFinished {
		sleep(1)
	}
	
	if try destinationURL.checkResourceIsReachable() {
		try formatFileHeader(fileURL: destinationURL)
	} else {
		throw COVIDError.DownloadError(error: "Unable to download file.")
	}
	
	return destinationURL
}
