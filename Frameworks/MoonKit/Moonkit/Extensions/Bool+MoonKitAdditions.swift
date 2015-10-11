//
//  Bool+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/27/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension Bool {
  public init(_ string: String?) {
    if string != nil {
      switch string!.lowercaseString {
        case "1", "yes", "true": self = true
        default: self = false
      }
    } else { self = false }
  }
}

extension Bool: BitwiseOperationsType {
  public static var allZeros: Bool { return false }
}

public func &(lhs: Bool, rhs: Bool) -> Bool { return lhs && rhs }
public func |(lhs: Bool, rhs: Bool) -> Bool { return lhs || rhs }
public func ^(lhs: Bool, rhs: Bool) -> Bool { return (lhs && !rhs) || (rhs && !lhs) }
public prefix func ~(x: Bool) -> Bool { return !x }