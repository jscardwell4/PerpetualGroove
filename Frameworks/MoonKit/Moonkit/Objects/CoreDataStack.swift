//
//  CoreDataStack.swift
//  Remote
//
//  Created by Jason Cardwell on 12/18/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData

private var stackInstanceCount = 0
private var stackInstances: [ObjectIdentifier:Int] = [:]

private var mainContextCount = 0
private var isolatedContextCount = 0
private var privateContextCount = 0

public class CoreDataStack {

  public let managedObjectModel: NSManagedObjectModel
  public let persistentStore: NSPersistentStore
  public let persistentStoreCoordinator: NSPersistentStoreCoordinator
  public let rootContext: NSManagedObjectContext
  public var nametag: String {
    guard let stack = stackInstances[ObjectIdentifier(self)] else { return "<stack>" }
    return "<stack\(String(stack))>"
  }

  /**
  initWithManagedObjectModel:persistentStoreURL:options:

  - parameter managedObjectModel: NSManagedObjectModel
  - parameter persistentStoreURL: NSURL
  - parameter options: [NSObject:AnyObject]? = nil
  
  - throws: Any error encountered while adding a peristent store for the specified url
  */
  public init(managedObjectModel: NSManagedObjectModel,
              persistentStoreURL: NSURL?,
              options: [NSObject:AnyObject]? = nil) throws
  {
    self.managedObjectModel = managedObjectModel
    persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

    let storeType = persistentStoreURL == nil ? NSInMemoryStoreType : NSSQLiteStoreType
    do {
      let store = try persistentStoreCoordinator.addPersistentStoreWithType(storeType,
                                                             configuration: nil,
                                                                       URL: persistentStoreURL,
                                                                   options: options)
      persistentStore = store
      rootContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
      stackInstances[ObjectIdentifier(self)] = ++stackInstanceCount
      rootContext.persistentStoreCoordinator = persistentStoreCoordinator
      rootContext.nametag = "\(nametag)<root>"
      MSLogDebug("\(nametag) initialized")
    } catch {
      MSHandleError(error as NSError)
      persistentStore = NSPersistentStore(persistentStoreCoordinator: nil, configurationName: nil, URL: NSURL(), options: nil)
      rootContext = NSManagedObjectContext()
      throw error
    }
  }

  /**
  Generates child context that executes on the main queue

  - returns: NSManagedObjectContext
  */
  public func mainContext() -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    context.parentContext = rootContext
    context.nametag = "\(nametag)<main\(++mainContextCount)>"
    MSLogDebug("context created: \(String(prettyNil: context.nametag))")
    return context
  }

  /**
  Generates a context not related to any other contexts save for the `persistentStoreCoordinator`

  - returns: NSManagedObjectContext
  */
  public func isolatedContext() -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    context.persistentStoreCoordinator = persistentStoreCoordinator
    context.nametag = "\(nametag)<isolated\(++isolatedContextCount)>"
    MSLogDebug("context created: \(String(prettyNil: context.nametag))")
    return context
  }
  /**
  Generates a child context that executes on a private queue

  - returns: NSManagedObjectContext
  */
  public func privateContext() -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    context.parentContext = rootContext
    context.nametag = "\(nametag)<private\(++privateContextCount)>"
    MSLogDebug("context created: \(String(prettyNil: context.nametag))")
    return context
  }

  public struct ContextSaveOptions: OptionSetType {
    public let rawValue: Int
    public init(rawValue value: Int) { rawValue = value }

    public static let Default             = ContextSaveOptions(rawValue: 0b000)
    public static let NonBlocking         = ContextSaveOptions(rawValue: 0b001)
    public static let BackgroundExecution = ContextSaveOptions(rawValue: 0b010)
    public static let Propagating         = ContextSaveOptions(rawValue: 0b100)
  }

  public typealias PerformBlock = (NSManagedObjectContext) -> Void
  public typealias CompletionBlock = (ErrorType?) -> Void

  /**
  saveContext:withBlock:options:completion:

  - parameter context: NSManagedObjectContext
  - parameter block: PerformBlock? = nil
  - parameter options: ContextSaveOptions
  - parameter completion: CompletionBlock? = nil
  
  - throws: Any error saving a context, if options does not contain `NonBlocking`
  */
  public func saveContext(context: NSManagedObjectContext,
                withBlock block: PerformBlock? = nil,
                  options: ContextSaveOptions,
               completion: CompletionBlock? = nil) throws
  {
    var saveError: ErrorType?

    let performWithContext = options.contains(.NonBlocking)
                               ? NSManagedObjectContext.performBlock
                               : NSManagedObjectContext.performBlockAndWait

    let perform: (NSManagedObjectContext, PerformBlock) -> Void = {
      context, work in

      performWithContext(context) ({ work(context) })
    }

    let save: (NSManagedObjectContext) throws -> Void = {
      $0.processPendingChanges()
      guard $0.hasChanges else { return }

      MSLogDebug("saving context '\($0.nametag)'")

      try $0.save()
    }

    let propagate: (NSManagedObjectContext) throws -> Void = {
      var currentContext = $0
      while let parentContext = currentContext.parentContext {
        try save(parentContext)
        currentContext = parentContext
      }
    }

    // Create a child context if flagged for background execution
    if options.contains(.BackgroundExecution) {

      let child = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
      child.nametag = "child of \(context.nametag)"
      child.parentContext = context
      child.undoManager = nil

      perform(child) {
        context in

        block?(context)
        do { try save(context) } catch { saveError = error }

        let parentContext = context.parentContext!

        if saveError == nil { do { try save(parentContext) } catch { saveError = error } }

        if saveError == nil && options.contains(.Propagating) {
          do { try propagate(parentContext) } catch { saveError = error }
        }

        completion?(saveError)
      }
    } else {
      perform(context) {
        context in

        block?(context)

        do { try save(context) } catch { saveError = error }

        if saveError == nil && options.contains(.Propagating) {
          do { try propagate(context) } catch { saveError = error }
        }

        completion?(saveError)
      }
    }

    if let error = saveError where !options.contains(.NonBlocking) { throw error }
  }
  

  /**
  saveContext:withBlock::propagate:nonBlocking:completion:

  - parameter moc: NSManagedObjectContext
  - parameter block: ((NSManagedObjectContext) -> Void)? = nil
  - parameter propagate: Bool = false
  - parameter nonBlocking: Bool = false
  - parameter completion: ((Bool, NSError?) -> Void)? = nil
  */
  @available(*, unavailable, message = "saveContext:WithBlock:propagate:nonBlocking:backgroundExecution:completion: is unavailable, use saveContext:withBlock:options:completion: instead")
  public func saveContext(context: NSManagedObjectContext,
                withBlock block: ((NSManagedObjectContext) -> Void)? = nil,
                propagate: Bool = false,
              nonBlocking: Bool = false,
      backgroundExecution: Bool = false,
               completion: ((Bool, NSError?) -> Void)? = nil)
  {

    // Initialize variables for passing to completion block
    var saveError: NSError?
    var success = true

    // Create a closure that calls the appropriate `perform` variation
    let perform: (NSManagedObjectContext?, (NSManagedObjectContext) -> Void) -> Void = {
      context, work in if let moc = context { (nonBlocking ? moc.performBlock : moc.performBlockAndWait)({work(moc)}) }
    }

    // Create a closure for performing the save operation on the current context
    let save: (NSManagedObjectContext?) -> Void = {
      context in
      if let moc = context {
        moc.processPendingChanges()
        if moc.hasChanges == true {
          MSLogDebug("saving context '\(String(prettyNil: moc.nametag))'")
          do {
            try moc.save()
            success = true
          } catch {
            success = false
            saveError = error as NSError
          }
        }
      }
    }

    let propagateSave: (NSManagedObjectContext) -> Void = {
      context in
      var currentContext = context
      while let parentContext = currentContext.parentContext {
        save(parentContext)
        currentContext = parentContext
      }
    }

    // Create a child context if flagged for background execution
    if backgroundExecution {
      let childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
      childContext.nametag = "child of \(String(prettyNil: context.nametag))"
      childContext.parentContext = context
      childContext.undoManager = nil
      perform(childContext) {
        context in
        block?(context)
        save(context)
        let parentContext = context.parentContext!
        save(parentContext)
        if propagate { propagateSave(parentContext) }
        completion?(success, saveError)
      }
    } else {
      perform(context) {
        context in
        block?(context)
        save(context)
        if let parentContext = context.parentContext where propagate { propagateSave(parentContext) }
        completion?(success, saveError)
      }
    }

  }

}
