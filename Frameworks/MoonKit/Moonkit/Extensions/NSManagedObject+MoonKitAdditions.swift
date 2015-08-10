//
//  NSManagedObject+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 3/5/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import CoreData
import Swift

extension NSManagedObject {

  public func fireFault() { willAccessValueForKey(nil) }

  /**
  entityDescription:

  - parameter context: NSManagedObjectContext

  - returns: NSEntityDescription?
  */
  public class func entityDescription(context: NSManagedObjectContext) -> NSEntityDescription? {
    if let modelEntities = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName {
      return modelEntities[NSStringFromClass(self)]
    } else { return nil }
  }


}