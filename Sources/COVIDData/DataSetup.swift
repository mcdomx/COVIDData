//
//  File.swift
//  
//
//  Created by Mark on 12/1/20.
//

import Foundation
import CoreData


@available(iOS 10.0, *)
var persistentContainer: NSPersistentContainer = {
	let modelURL = Bundle.module.url(forResource: "COVIDData", withExtension: "momd")!
	let mom = NSManagedObjectModel(contentsOf: modelURL)!
	
	let container = NSPersistentContainer(name: "COVIDData", managedObjectModel: mom)
	
	container.loadPersistentStores(completionHandler: { (storeDescription, error) in
		if let error = error as NSError? {
			fatalError("Unresolved error \(error), \(error.userInfo)")
		}
	})
		
	return container
}()



// MARK: - Core Data Saving support

@available(iOS 10.0, *)
func saveContext () {

	let context = persistentContainer.viewContext

	if context.hasChanges {
		do {
			try context.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	} else {
		print("No persistent container has been set!")
	}

}

