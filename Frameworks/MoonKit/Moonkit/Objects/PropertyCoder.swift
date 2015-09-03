//
//  PropertyCoder.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation


public struct PropertyCoder<ValueType: AnyObject> {
  let propertyName: String
  let defaultValue: ValueType
  public func encode(source: NSObject, _ coder: NSCoder) {
    coder.encodeObject(source.valueForKey(propertyName), forKey: propertyName)
  }
  public func decode(coder:NSCoder) -> ValueType {
    return coder.decodeObjectForKey(propertyName) as? ValueType ?? defaultValue
  }
}