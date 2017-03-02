//
//  NSManagedObject+plainObject.swift
//  PlainObjectSerializer
//
//  Created by Nikolay Ischuk on 14.09.16.
//  Copyright © 2017 EasyVerzilla. All rights reserved.
//

import Foundation
import CoreData

public protocol PlainObjectSerializer {
    
    associatedtype T
    
    func fillFromPlainObject(_ plainObject: T)
    func toPlainObject() -> T
    static func uniqueKeyValue(_ source: T) -> (key: String, value: Any)?
}

public extension PlainObjectSerializer {
    static func uniqueKeyValue(_ source: T) -> (key: String, value: Any)? {
        return nil
    }
}

public extension PlainObjectSerializer {
    func assign<T>(_ left: inout T?, right: T?, enforce: Bool) {
        
        if enforce || right != nil {
            left = right
        }
    }
}

public struct SerializationHelper<Serializer: PlainObjectSerializer> where Serializer: NSManagedObject, Serializer: CoreDataFetchable {
    
    /*
     This function is used to find unique plainObjectSerializer from plainObject
     */
    public static func findUniqueEntity(by plainObject: Serializer.T, inContext context: NSManagedObjectContext) -> Serializer?  {
        
        let uniqueKeyValue = Serializer.uniqueKeyValue(plainObject)
        var item: Serializer? = nil
        if let uniqueKeyValue = uniqueKeyValue {
            let predicate = NSPredicate(format: "%K = %@", uniqueKeyValue.key, uniqueKeyValue.value as! NSObject)
            item = Serializer.findAllWithPredicate(predicate, inContext: context)?.last
        }
        
        return item
    }
    
    /*
     This function is used to create unique plainObjectSerializer from plainObject. If one is found, more won't be created.
     */
    public static func lazyCreateUniqueEntity(by plainObject: Serializer.T, inContext context: NSManagedObjectContext) -> Serializer? {
        
        var item: Serializer? = findUniqueEntity(by: plainObject, inContext: context)
        if item == nil {
            item = Serializer.createEntityInContext(context)
        }
        
        return item
    }
    
    /*
     This function is used to create unique plainObjectSerializer from plainObject and fill it with that plainObject. If one is found, more won't be created.
     */
    public static func lazyCreateAndFillUniqueEntity(by plainObject: Serializer.T, inContext context: NSManagedObjectContext) -> Serializer? {
        
        var item: Serializer? = findUniqueEntity(by: plainObject, inContext: context)
        if item == nil {
            item = Serializer.createEntityInContext(context)
        }
        
        if let item = item {
            item.fillFromPlainObject(plainObject)
        }
        
        return item
    }
    
    /*
     Use this to create set of NSManagedObjects from array of plainObjects
     
     - parameter itemsMP: 'Array<M>' array of plainObject items.
     
     - parameter context: `NSManagedObjectContext` to create the object within.
     
     - parameter initClosure: '(U -> Void)?' Closure where you can call some code before fillFromplainObject happen. Usually you want to set revers relation here.
     
     */
    public static func fromPlainObjectArray(_ items: Array<Serializer.T>, context: NSManagedObjectContext, initClosure: ((Serializer) -> Void)?) -> NSSet {
        let mutableSet = NSMutableSet()
        
        for itemMP in items {
            
            let item: Serializer? = lazyCreateUniqueEntity(by: itemMP, inContext: context)
            
            if let item = item {
                initClosure?(item)
                item.fillFromPlainObject(itemMP)
                mutableSet.add(item)
            }
        }
        
        return mutableSet
    }
    
    public static func fromPlainObjectArrayOrdered(_ items: Array<Serializer.T>, context: NSManagedObjectContext, initClosure: ((Serializer) -> Void)?) -> NSOrderedSet {
        let mutableSet = NSMutableOrderedSet()
        
        for itemMP in items {
            
            let item: Serializer? = lazyCreateUniqueEntity(by: itemMP, inContext: context)
            
            if let item = item {
                initClosure?(item)
                item.fillFromPlainObject(itemMP)
                mutableSet.add(item)
            }
        }
        
        return mutableSet
    }
    
    /*
     Use this to create array of plainObjects from set of NSManagedObjects
     
     - parameter items: 'Set<U>' set of NSManagedObjects.
     
     - returns: [M] array of plainObjects
     
     */
    
    public static func toPlainObjectArray(_ items: Set<Serializer>) -> [Serializer.T] {
        var itemsMP: [Serializer.T] = []
        
        for item in items {
            let itemMP = item.toPlainObject()
            
            itemsMP.append(itemMP)
        }
        
        return itemsMP
    }
}
