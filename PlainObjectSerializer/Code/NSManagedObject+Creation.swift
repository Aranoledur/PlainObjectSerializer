//
//  NSManagedObject+Creation.swift
//  PlainObjectSerializer
//
//  Created by Nikolay Ischuk on 14.09.16.
//  Copyright © 2017 EasyVerzilla. All rights reserved.
//

import Foundation
import CoreData

public extension CoreDataFetchable where Self: NSManagedObject {
    
    public init(managedObjectContext context: NSManagedObjectContext) {
        self.init(entity: Self.entityDescriptionForFetchable(in: context), insertInto: context)
    }
    
    public static func createEntityInContext(_ context: NSManagedObjectContext) -> Self? {
        
        let entityDesc = NSEntityDescription.entity(forEntityName: entityName, in: context)
        
        guard let entity = entityDesc else {
            return nil
        }
        
        return self.init(entity: entity, insertInto: context)
    }
    
    @discardableResult
    public static func lazyCreateEntityInContext(_ context: NSManagedObjectContext, withPredicate predicate: NSPredicate?) -> Self? {
        
        var result: Self?
        if let predicate = predicate {
            result = findAllWithPredicate(predicate, inContext: context)?.last
        } else {
            result = findAllInContext(context)?.last
        }
        
        if result == nil {
            result = createEntityInContext(context)
        }
        
        return result
    }

    public func deleteEntity() {
        managedObjectContext?.delete(self)
    }
    
    fileprivate func deleteEntitesSet(_ items: Set<NSManagedObject>) {
        for item in items {
            item.managedObjectContext?.delete(item)
        }
    }
    
    public func deleteEntities(_ items: inout NSSet?) {
        if let items = items as? Set<NSManagedObject> {
            deleteEntitesSet(items)
        }
        items = nil
    }
    
    public func deleteEntities(_ items: inout NSOrderedSet?) {
        if let items = items?.set as? Set<NSManagedObject> {
            deleteEntitesSet(items)
        }
        items = nil
    }
}

