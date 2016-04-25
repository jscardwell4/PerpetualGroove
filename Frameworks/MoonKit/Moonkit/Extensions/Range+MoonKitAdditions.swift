//
//  Range+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/26/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

// even though infix ..< already exists, we need to declare it
// two more times for the prefix and postfix form
postfix operator ..< { }
prefix operator ..< { }

postfix operator ... {}
prefix operator ... {}

// then, declare a couple of simple custom types that indicate one-sided ranges:
public struct RangeStart<I: ForwardIndexType> { let start: I }
public struct RangeEnd<I: ForwardIndexType> { let end: I }

public extension CollectionType {
  public subscript(r: RangeStart<Index>) -> SubSequence { return suffixFrom(r.start) }
  public subscript(r: RangeEnd<Index>) -> SubSequence { return prefixUpTo(r.end) }
}

// and define ..< to return them
public postfix func ..<<I: ForwardIndexType>(lhs: I) -> RangeStart<I>
{ return RangeStart(start: lhs) }

public prefix func ..<<I: ForwardIndexType>(rhs: I) -> RangeEnd<I>
{ return RangeEnd(end: rhs) }

private func sortedRanges<T:ForwardIndexType where T:Comparable>(ranges: [Range<T>]) -> [Range<T>] {
  return ranges.sort({
    (lhs: Range<T>, rhs: Range<T>) -> Bool in
    return lhs.startIndex < rhs.startIndex
  })
}

public struct OpenIntervalStart<I: Comparable> { let start: I }
public struct OpenIntervalEnd<I: Comparable> { let end: I }

public postfix func ..<<I:Comparable>(lhs: I) -> OpenIntervalStart<I>
{ return OpenIntervalStart(start: lhs) }

public prefix func ..<<I:Comparable>(rhs: I) -> OpenIntervalEnd<I>
{ return OpenIntervalEnd(end: rhs) }

public func ~=<I:Comparable>(lhs: OpenIntervalStart<I>, rhs: I) -> Bool {
  return rhs > lhs.start
}

public func ~=<I:Comparable>(lhs: OpenIntervalEnd<I>, rhs: I) -> Bool {
  return rhs < lhs.end
}

public struct ClosedIntervalStart<I: Comparable> { let start: I }
public struct ClosedIntervalEnd<I: Comparable> { let end: I }

public postfix func ...<I:Comparable>(lhs: I) -> ClosedIntervalStart<I>
{ return ClosedIntervalStart(start: lhs) }

public prefix func ...<I:Comparable>(rhs: I) -> ClosedIntervalEnd<I>
{ return ClosedIntervalEnd(end: rhs) }


public func ~=<I:Comparable>(lhs: ClosedIntervalStart<I>, rhs: I) -> Bool {
  return rhs >= lhs.start
}

public func ~=<I:Comparable>(lhs: ClosedIntervalEnd<I>, rhs: I) -> Bool {
  return rhs <= lhs.end
}

public extension Range {
  public var middleIndex: Element {
    return startIndex.advancedBy(startIndex.distanceTo(endIndex) / 2)
  }
}

public extension Range {
  public func contains(subRange: Range<Element>) -> Bool {
    return subRange.startIndex.distanceTo(startIndex) <= 0 && subRange.endIndex.distanceTo(endIndex) >= 0
  }
  public func contains<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    for element in sequence where !contains(element) { return false }
    return true
  }
}

public extension Range where Element: Comparable {


  /**
  split:noImplicitJoin:

  - parameter ranges: [Range<Element>]
  - parameter noImplicitJoin: Bool = false

  - returns: [Range<Element>]
  */
  public func split(ranges: [Range<Element>], noImplicitJoin: Bool = false) -> [Range<Element>] {
    var result: [Range<Element>] = []

    var n = startIndex

    var q = Queue(ranges)

    while let r = q.dequeue() {

      switch r.startIndex {
        case n:
          if noImplicitJoin { result.append(n ..< n) }
          n = r.endIndex
        case let s where s > n: result.append(n ..< s); n = r.endIndex
        default: break
      }

    }

    if n < endIndex { result.append(n ..< endIndex) }
    return result
  }

  /**
  split:

  - parameter range: Range<Element>

  - returns: [Range<Element>]
  */
  public func split(range: Range<Element>) -> [Range<Element>] {
    if range.startIndex == startIndex {
      return [range.endIndex ..< endIndex]
    } else {
      return [startIndex ..< range.startIndex, range.endIndex ..< endIndex]
    }
  }

}