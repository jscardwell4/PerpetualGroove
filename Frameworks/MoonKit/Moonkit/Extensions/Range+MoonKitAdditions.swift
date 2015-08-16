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

public extension Range where Element: Comparable {

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

  public func split(range: Range<Element>) -> [Range<Element>] {
    if range.startIndex == startIndex {
      return [Range<Element>(start: range.endIndex, end: endIndex)]
    } else {
      return [Range<Element>(start: startIndex, end: range.startIndex), Range<Element>(start: range.endIndex, end: endIndex)]
    }
  }

}