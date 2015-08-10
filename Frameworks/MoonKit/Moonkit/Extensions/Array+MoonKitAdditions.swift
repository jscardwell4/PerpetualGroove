//
//  Array+MoonKitAdditions.swift
//  Remote
//
//  Created by Jason Cardwell on 12/20/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

extension Array {
  func compressedMap<U>(transform: (Element) -> U?) -> [U] { return MoonKit.compressedMap(self, transform) }
}

extension Array: NestingContainer {
  public var topLevelObjects: [Any] {
    var result: [Any] = []
    for value in self {
      result.append(value as Any)
    }
    return result
  }
  public func topLevelObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in self {
      if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
  public var allObjects: [Any] {
    var result: [Any] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.extend(container.allObjects)
      } else {
        result.append(value as Any)
      }
    }
    return result
  }
  public func allObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.extend(container.allObjects(type))
      } else if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
}

extension Array: KeySearchable {
  public var allValues: [Any] { return topLevelObjects }
}

