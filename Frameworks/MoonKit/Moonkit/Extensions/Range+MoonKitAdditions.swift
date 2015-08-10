//
//  Range+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/26/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

private func sortedRanges<T:ForwardIndexType where T:Comparable>(ranges: [Range<T>]) -> [Range<T>] {
  return ranges.sort({
    (lhs: Range<T>, rhs: Range<T>) -> Bool in
    return lhs.startIndex < rhs.startIndex
  })
}

public extension Range where Element: Comparable{

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