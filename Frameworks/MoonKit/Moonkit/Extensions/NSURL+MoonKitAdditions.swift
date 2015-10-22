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
