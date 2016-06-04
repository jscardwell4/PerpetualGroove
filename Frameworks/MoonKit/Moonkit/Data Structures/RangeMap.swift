//
//  RangeMap.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/25/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation
import Surge

// MARK: - Helpers to simplify treating ForwardIndexType as Comparable

@inline(__always)
private func <<F:ForwardIndexType>(lhs: F, rhs: F) -> Bool {
  return lhs.distanceTo(rhs) > 0
}

@inline(__always)
private func ><F:ForwardIndexType>(lhs: F, rhs: F) -> Bool {
  return lhs.distanceTo(rhs) < 0
}


@inline(__always)
private func <=<F:ForwardIndexType>(lhs: F, rhs: F) -> Bool {
  return lhs.distanceTo(rhs) > 0 || lhs == rhs
}

@inline(__always)
private func >=<F:ForwardIndexType>(lhs: F, rhs: F) -> Bool {
  return lhs.distanceTo(rhs) < 0 || lhs == rhs
}

@inline(__always)
private func ==<F:ForwardIndexType>(lhs: F, rhs: F) -> Bool {
  return lhs.distanceTo(rhs) == 0
}

// MARK: - Helpers to convert to an array of non-overlapping ranges

private func rangify<S:SequenceType, F:ForwardIndexType where S.Generator.Element == F>(indices: S) -> ContiguousArray<Range<F>> {
  let sortedIndices = indices.sort { $0 < $1 }
  guard sortedIndices.count > 0 else { return [] }
  guard sortedIndices.count > 1 else { return [sortedIndices[0] ... sortedIndices[0]] }
  var ranges = ContiguousArray<Range<F>>()
  var range = sortedIndices[0] ..< sortedIndices[0].successor()
  for index in sortedIndices.dropFirst() {
    guard !range.contains(index) else { continue }
    if range.endIndex == index { range.endIndex._successorInPlace() }
    else {
      ranges.append(range)
      range = index ..< index.successor()
    }
  }
  if ranges[ranges.endIndex.predecessor()] != range { ranges.append(range) }
  return ranges
}

private func rangify<S:SequenceType, F:ForwardIndexType where S.Generator.Element == Range<F>>(ranges: S) -> ContiguousArray<Range<F>> {
  let sortedRanges = ranges.sort { $0.startIndex < $1.startIndex }
  guard sortedRanges.count > 0 else { return [] }
  var result = ContiguousArray<Range<F>>()
  var range = sortedRanges[0]
  for r in sortedRanges.dropFirst() {
    guard !range.contains(r) else { continue }
    if r.startIndex > range.endIndex {
      result.append(range)
      range = r
    } else {
      range.endIndex = r.endIndex
    }
  }
  if result[result.endIndex.predecessor()] != range { result.append(range) }
  return result
}

// MARK: - RangeMap

/// A collection of non-overlapping ranges
public struct RangeMap<RangeIndex:ForwardIndexType>: CollectionType {

  public typealias Element = Range<RangeIndex>
  public typealias _Element = Element
  public typealias Index = Int

  var ranges: ContiguousArray<Element>

  public var headIndex: RangeIndex? { return ranges.first?.startIndex }
  public var tailIndex: RangeIndex? { return ranges.last?.endIndex }

  public var indexCount: Int {
    return Int(Surge.sum(ranges.map({Double($0.count.toIntMax())})))
  }

  public init() { ranges = [] }

  public init<S:SequenceType where S.Generator.Element == RangeIndex>(_ sequence: S) { ranges = rangify(sequence) }

  public init<S:SequenceType where S.Generator.Element == Range<RangeIndex>>(_ sequence: S) { ranges = rangify(sequence) }
  
  /// The range containing the min `RangeIndex` and the max `RangeIndex` or nil if the collection is empty.
  public var coverage: Element? {
    guard let headIndex = headIndex, tailIndex = tailIndex else { return nil }
    return headIndex ..< tailIndex
  }

  /// Returns the significant index into `ranges` when inserting `element`.
  /// The returned index is determined via the following:
  /// 
  /// `∃ r: ranges[ranges.startIndex] == r, r.startIndex ≥ element ➞ ranges.startIndex`
  ///
  /// `∃ r: ranges[ranges.endIndex.predecessor()] == r, r.endIndex < element ➞ ranges.endIndex`
  ///
  /// `∃ r: r.contains(element) ➞ ranges.indexOf(r)`
  ///
  /// `∃ r: r.startIndex = element.successor() ➞ ranges.indexOf(r)`
  ///
  /// `∃ r: r.endIndex == element ➞ ranges.indexOf(r)`
  private func insertionPointFor(element: RangeIndex) -> Int {

    guard let headIndex = headIndex, tailIndex = tailIndex else { return ranges.startIndex }
    guard headIndex < element else { return ranges.startIndex }
    guard tailIndex > element else {
      return tailIndex == element ? ranges.endIndex.predecessor() : ranges.endIndex
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

    return searchSlice(ranges[ranges.indices])
  }


  /// Insert `element` into the collection. If an existing element contains `element`, no action is taken.
  /// If `element` prepends or extends an existing element, the existing element is updated.
  /// Otherwise, a new element is inserted for `element`.
  public mutating func insert(element: RangeIndex) {

    // If empty, just append the element
    guard !ranges.isEmpty else { ranges.append(element ... element); return }

    let index = insertionPointFor(element)
    guard index < ranges.endIndex else { ranges.append(element ... element); return }

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

  /// Merges `ranges` with the ranges expressed by `indices`.
  public mutating func insert<S:SequenceType where S.Generator.Element == RangeIndex>(indices: S) {
    ranges = rangify(ranges + rangify(indices))
  }

  /// Merges `ranges` with `sequence`.
  public mutating func appendContentsOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    ranges = rangify(ranges + sequence)
  }

  /// Returns a `RangeMap` whose elements consist of the gaps between `ranges` over `coverage`.
  @warn_unused_result
  public func invert(coverage coverage: Element) -> RangeMap<RangeIndex> {
    var result = self
    result.invertInPlace(coverage: coverage)
    return result
  }

  /// Replaces `ranges` the gaps between `ranges` over `coverage`.
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

  public func reverse() -> RangeMap<RangeIndex> {
    var result = self
    result.reverseInPlace()
    return result
  }

  public mutating func reverseInPlace() {
    ranges = ContiguousArray(ranges.reverse())
  }

  public var startIndex: Int { return ranges.startIndex }
  public var endIndex: Int { return ranges.endIndex }

  public subscript(index: Index) -> Element { return ranges[index] }

}

extension RangeMap: Equatable {}

public func ==<R:ForwardIndexType>(lhs: RangeMap<R>, rhs: RangeMap<R>) -> Bool {
  guard lhs.count == rhs.count else { return false }
  for (range1, range2) in zip(lhs, rhs) { guard range1 == range2 else { return false } }
  return true
}

extension RangeMap: CustomStringConvertible {

  public var description: String {
    var result = "["
    var isFirst = true
    for range in ranges {
      if isFirst { isFirst = false } else { result += ", " }
      if range.count == 1 { result += "\(range.startIndex)" }
      else { result += "\(range.startIndex)..<\(range.endIndex)" }
    }
    result += "]"
    return result
  }

}
