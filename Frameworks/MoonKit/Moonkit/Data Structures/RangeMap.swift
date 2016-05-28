//
//  RangeMap.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/25/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation
import Surge

@inline(__always)
private func <<F:ForwardIndexType>(lhs: F, rhs: F) -> Bool {
  return lhs.distanceTo(rhs) > 0
}

@inline(__always)
private func ><F:ForwardIndexType>(lhs: F, rhs: F) -> Bool {
  return lhs.distanceTo(rhs) < 0
}

@inline(__always)
private func ==<F:ForwardIndexType>(lhs: F, rhs: F) -> Bool {
  return lhs.distanceTo(rhs) == 0
}




public struct RangeMap<RangeIndex:ForwardIndexType>: CollectionType, CustomStringConvertible {

  public typealias Element = Range<RangeIndex>
  public typealias _Element = Element
  public typealias Index = Int

  var ranges: ContiguousArray<Element> = []

  public var headIndex: RangeIndex? { return ranges.first?.startIndex }
  public var tailIndex: RangeIndex? { return ranges.last?.endIndex }

  public var indexCount: Int {
    return Int(Surge.sum(ranges.map({Double($0.count.toIntMax())})))
  }

  public init() {}

  public var coverage: Element? {
    guard let headIndex = headIndex, tailIndex = tailIndex else { return nil }
    return headIndex ..< tailIndex
  }

  public mutating func insert(element: RangeIndex) {
    // If empty, just append the element
    guard let headIndex = headIndex, tailIndex = tailIndex else {
      ranges.append(element ... element)
      return
    }

    // Handle case of element being the min element
    guard headIndex < element else {
      switch ranges[0] {
        case let range where range.contains(element): break
        case let range where range.startIndex == element.successor():
          ranges[0] = element ..< range.endIndex
        default:
          ranges.insert(element ... element, atIndex: 0)
      }
      return
    }

    // Handle case of element being the max element
    guard tailIndex > element else {
      let index = ranges.endIndex.predecessor()
      switch ranges[index] {
        case let range where range.endIndex == element:
          ranges[index] = range.startIndex ... element
        default:
          ranges.append(element ... element)
      }
      return
    }

    // Recursively searches an array slice to return an insertion point for `element`.
    func searchSlice(slice: ArraySlice<Element>) -> Int {
      let sliceRange = slice.indices
      let index = sliceRange.middleIndex
      switch slice[index] {
        case let range where range.contains(element): return index
        case let range where range.startIndex == element.successor(): return index
        case let range where range.endIndex == element: return index
        case let range where range.endIndex < element:
          guard index.successor() != sliceRange.endIndex else { return sliceRange.endIndex }
          return searchSlice(slice[index.successor() ..< sliceRange.endIndex])
        case let range where range.startIndex > element:
          guard index != sliceRange.startIndex else { return sliceRange.startIndex }
          return searchSlice(slice[sliceRange.startIndex ..< index])
        default: return ranges.endIndex
      }
    }

    // Get the insertion point for `element`
    let index = searchSlice(ranges[ranges.indices])

    // Handle insertion
    switch ranges[index] {
      case let range where range.contains(element):
        // `element` already contained
        break

      case let range where element.successor() == range.startIndex
        && index.predecessor() >= ranges.startIndex
        && ranges[index.predecessor()].endIndex == element:
        // bridge ranges at `index.predecessor()` and `index` with `element`
        ranges.replaceRange(index.predecessor() ... index,
                            with: [ranges[index.predecessor()].startIndex ..< range.endIndex])

      case let range where element.successor() == range.startIndex:
        // prepend `element` to range at `index`
        ranges[index] = element ..< range.endIndex

      case let range where range.endIndex == element
        && index.successor() < ranges.endIndex
        && ranges[index.successor()].startIndex == element.successor():
        // bridge ranges at `index` and `index.successor()` with `element`
        ranges.replaceRange(index ... index.successor(),
                            with: [range.startIndex ..< ranges[index.successor()].endIndex])

      case let range where range.endIndex == element:
        // append `element` to range at `index`
        ranges[index] = range.startIndex ... range.endIndex

      case let range where range.startIndex > element:
        // insert `element` before range at `index`
        ranges.insert(element ... element, atIndex: index)

      case let range where range.endIndex < element:
        // insert `element` after range at `index`
        ranges.insert(element ... element, atIndex: index.successor())

      default:
        fatalError("one of the other cases should have matched")
    }
  }

  @warn_unused_result
  public func invert(coverage coverage: Element) -> RangeMap<RangeIndex> {
    var result = self
    result.invertInPlace(coverage: coverage)
    return result
  }

  public mutating func invertInPlace(coverage coverage: Element) {

    guard let headIndex = headIndex, tailIndex = tailIndex else { ranges = [coverage]; return }

    var invertedRanges = ContiguousArray<Element>(minimumCapacity: ranges.count &+ 1)

    if coverage.startIndex < headIndex {
      invertedRanges.append(coverage.startIndex ..< ranges[0].startIndex)
    }

    for index in 1 ..< ranges.endIndex {
      invertedRanges.append(ranges[index.predecessor()].endIndex ..< ranges[index].startIndex)
    }

    if tailIndex < coverage.endIndex {
      invertedRanges.append(ranges[ranges.endIndex.predecessor()].endIndex ..< coverage.endIndex)
    }

    ranges = invertedRanges

  }

  public var startIndex: Int { return ranges.startIndex }
  public var endIndex: Int { return ranges.endIndex }

  public subscript(index: Index) -> Element { return ranges[index] }

  public var description: String {
    var result = "["
    var isFirst = true
    for range in ranges {
      if isFirst { isFirst = false } else { result += ", " }
      if range.count == 1 { result += "\(range.startIndex)" }
      else { result += "\(range.startIndex)...\(range.endIndex.advancedBy(-1))" }
    }
    result += "]"
    return result
  }
}
