//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        
        let identifiers = entries.compactMap { UUID(uuidString: $0.identifier ?? UUID().uuidString) }
               let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
               var repDict = Dictionary(uniqueKeysWithValues: zip(identifiers, entries))
               fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        self.context.perform {
            do {
                let entries = try self.context.fetch(fetchRequest)
                for entry in entries {
                    guard let id = UUID(uuidString: entry.identifier ?? ""),
                    let representation = repDict[id]
                else { continue }
                    self.update(entry: entry, with: representation)
                    repDict.removeValue(forKey: id)
                }
                for rep in repDict.values {
                    let _ = Entry(entryRepresentation: rep)
                }
            } catch {
                completion(NSError(domain: "JournalCoreData.sync", code: 999))
            }
            try! self.context.save()
            completion(nil)
        }
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    let context: NSManagedObjectContext
}
