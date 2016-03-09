//
//  NSURL+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public func +(lhs: NSURL, rhs: String) -> NSURL { return lhs.URLByAppendingPathComponent(rhs) }
public func +=(inout lhs: NSURL, rhs: String) { lhs = lhs + rhs }
public func +<S:SequenceType where S.Generator.Element == String>(lhs: NSURL, rhs: S) -> NSURL {
  return rhs.reduce(lhs) { $0.URLByAppendingPathComponent($1) }
}

extension NSURL {
  public func isEqualToFileURL(other: NSURL) -> Bool {
    var reference1: AnyObject?, reference2: AnyObject?
    do {
      try getResourceValue(&reference1, forKey: NSURLFileResourceIdentifierKey)
      try other.getResourceValue(&reference2, forKey: NSURLFileResourceIdentifierKey)
    } catch {
      logError(error)
      return false
    }
    guard reference1 != nil && reference2 != nil else { return false }
    return reference1!.isEqual(reference2!)
  }
}
