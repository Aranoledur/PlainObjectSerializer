//
//  NSManagedObject+Finders.swift
//  PlainObjectSerializer
//
//  Created by Nikolay Ischuk on 14.09.16.
//  Copyright © 2017 EasyVerzilla. All rights reserved.
//

import CoreData

/**
 Protocol to be conformed to by `NSManagedObject` subclasses that allow for convenience
 methods that make fetching, inserting, deleting, and change management easier.
 */
@objc public protocol CoreDataFetchable: NSFetchRequestResult {
    static var entityName: String { get }
}

public extension CoreDataFetchable where Self: NSManagedObject {
    
    static public func entityDescriptionForFetchable(in context: NSManagedObjectContext) -> NSEntityDescription! {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            assertionFailure("Entity named \(entityName) doesn't exist. Fix the entity description or naming of \(Self.self).")
            return nil
        }
        return entity
    }
    
    static public func fetchRequestForEntityInFetchable(inContext context: NSManagedObjectContext) -> NSFetchRequest<Self> {
        let fetchRequest = NSFetchRequest<Self>()
        fetchRequest.entity = entityDescriptionForFetchable(in: context)
        return fetchRequest
    }
    
    static func executeFetchRequest(_ request: NSFetchRequest<Self>, inContext context: NSManagedObjectContext) -> [Self]? {
        
        var results: [Self]? = nil
        
        context.performAndWait {
            do {
                let anyArray = try context.fetch(request)
                results = anyArray
                
            } catch {
                debugPrint("Couldn't create entity \(entityName) in context with concurrency type \(context.concurrencyType), error \(error)")
            }
        }
        
        return results
    }
    
    static func findAllInContext(_ context: NSManagedObjectContext) -> [Self]? {
        let fetchRequest = fetchRequestForEntityInFetchable(inContext: context)
        
        return executeFetchRequest(fetchRequest, inContext: context)
    }
    
    static func findAllWithPredicate(_ searchTerm: NSPredicate, inContext context: NSManagedObjectContext) -> [Self]? {
        let fetchRequest = fetchRequestForEntityInFetchable(inContext: context)
        
        fetchRequest.predicate = searchTerm
        
        return executeFetchRequest(fetchRequest, inContext: context)
    }
    
    static func findAllSortedBy(_ sortTerm: String, ascending: Bool, inContext context: NSManagedObjectContext) -> [Self]? {
        return findAllSortedBy(sortTerm, ascending: ascending, withPredicate: nil, inContext: context)
    }
    
    static func findAllSortedBy(_ sortTerm: String, ascending: Bool, withPredicate predicate: NSPredicate?, inContext context: NSManagedObjectContext) -> [Self]? {
        let fetchRequest = fetchRequestForEntityInFetchable(inContext: context)
        
        fetchRequest.predicate = predicate
        
        let sortKeys = sortTerm.components(separatedBy: ",")
        
        var sortDesciptors = [NSSortDescriptor]()
        for sortKey in sortKeys {
            let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: ascending)
            
            sortDesciptors.append(sortDescriptor)
        }
        
        fetchRequest.sortDescriptors = sortDesciptors
        
        return executeFetchRequest(fetchRequest, inContext: context)
    }
    
    func entityInContext(_ otherContext: NSManagedObjectContext) -> Self? {
        if objectID.isTemporaryID {
            do {
                try managedObjectContext?.obtainPermanentIDs(for: [self])
            } catch {
                debugPrint(error)
                return nil
            }
        }
        
        do {
            let inContext = try otherContext.existingObject(with: objectID)
            return inContext as? Self
        } catch {
            debugPrint(error)
        }
        
        return nil
    }
}
