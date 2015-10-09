//
//  NSRange+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension _NSRange: CustomStringConvertible {
  public var description: String { return "_NSRange { location: \(location); length: \(length) }" }
}

extension _NSRange {

  /**
  initWithLocation:

  - parameter location: Int
  */
  public init(location: Int) { self.init(location: location, length: 0) }

  /**
  initWithString:

  - parameter string: String
  */
  public init(string: String) { self = NSRangeFromString(string) }

  /**
  initWithLength:

  - parameter length: Int
  */
  public init(length: Int) { self.init(location: 0, length: length) }

  public var max: Int { return NSMaxRange(self) }

  /**
  contains:

  - parameter loc: Int

  - returns: Bool
  */
  public func contains(loc: Int) -> Bool { return NSLocationInRange(loc, self) }

  /**
  union:

  - parameter range: NSRange

  - returns: NSRange
  */
  @warn_unused_result(mutable_variant="unionInPlace")
  public func union(range: NSRange) -> NSRange { return NSUnionRange(self, range) }

  /**
  unionInPlace:

  - parameter range: NSRange
  */
  public mutating func unionInPlace(range: NSRange) { self = union(range) }

  /**
  intersect:

  - parameter range: NSRange

  - returns: NSRange
  */
  @warn_unused_result(mutable_variant="intersectInPlace")
  public func intersect(range: NSRange)-> NSRange { return NSIntersectionRange(self, range) }

  /**
  intersectInPlace:

  - parameter range: NSRange
  */
  public mutating func intersectInPlace(range: NSRange) { self = intersect(range) }
}