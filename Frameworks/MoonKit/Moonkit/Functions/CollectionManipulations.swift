//
//  CollectionManipulations.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public extension MutableCollectionType where Index == Int, Generator.Element:Named {
  public mutating func sortByNameInPlace() {
    let sorted = self.sort({ $0.name < $1.name })
    for i in sorted.indices {
      self[i] = sorted[i]
    }
  }
}

infix operator ➞ { associativity none precedence 130 }

public struct SubSequenceIndex<I:ForwardIndexType> {
  let start: I
  let length: I.Distance
}

public func ➞ <I:ForwardIndexType>(lhs: I, rhs: I.Distance) -> SubSequenceIndex<I> {
  return SubSequenceIndex(start: lhs, length: rhs)
}

public extension MutableCollectionType {
  public subscript(i: SubSequenceIndex<Index>) -> SubSequence {
    get { return self[i.start ..< i.start.advancedBy(i.length)] }
    set { self[i.start ..< i.start.advancedBy(i.length)] = newValue }
  }
}

public extension CollectionType {

  public subscript(i: SubSequenceIndex<Index>) -> SubSequence { return self[i.start ..< i.start.advancedBy(i.length)] }

  /**
  first:

  - parameter predicate: (Self.Generator.Element) throws -> Bool
  */
  public func first(@noescape predicate: (Self.Generator.Element) throws -> Bool) rethrows -> Self.Generator.Element? {
    guard let idx = try indexOf(predicate) else { return nil }
    return self[idx]
  }

}


/**
spliced:newElements:atIndex:

- parameter x: C
- parameter newElements: S
- parameter i: C.Index

- returns: C
*/
public func spliced<C : RangeReplaceableCollectionType, S : CollectionType
  where C.Generator.Element == S.Generator.Element>(x: C, newElements: S, atIndex i: C.Index) -> C
{
  var xPrime = x
  xPrime.insertContentsOf(newElements, at: i)
  return xPrime
}

/**
removedAtIndex:index:

- parameter x: C
- parameter index: C.Index

- returns: C
*/
public func removedAtIndex<C : RangeReplaceableCollectionType>(x: C, index: C.Index) -> C {
  var xPrime = x
  xPrime.removeAtIndex(index)
  return xPrime
}

public func valuesForKey<C: KeyValueCollectionType, K:Hashable, V where C.Key == K>(key: K, container: C) -> [V] {
  let containers: [C] = flattened(container)
  return containers.flatMap { $0[key] as? V }
}


/**
 Perform a binary search of the specified collection and return the index of `element` if found.

 - parameter collection: C
 - parameter element: C.Generator.Element

 - returns: C.Index?

 - requires: The collection to search is already sorted
*/
public func binarySearch<C:CollectionType
  where C.Generator.Element: Comparable,
  C.Index:BidirectionalIndexType,
  C.SubSequence.SubSequence == C.SubSequence,
  C.SubSequence:CollectionType,
  C.SubSequence.Index == C.Index,
  C.SubSequence.Generator.Element == C._Element,
  C.SubSequence._Element == C._Element,
  C._Element == C.Generator.Element>(collection: C, element: C.Generator.Element) -> C.Index?
{
  func searchSlice(slice: C.SubSequence) -> C.Index? {
    let range = slice.indices
    let index = range.middleIndex
    let maybeElement = slice[index]
    guard maybeElement != element else { return index }
    if maybeElement < element && index.successor() != range.endIndex {
      return searchSlice(slice[index.successor() ..< range.endIndex])
    } else if maybeElement > element && index != range.startIndex {
      return searchSlice(slice[range.startIndex ..< index])
    }
    return nil
  }

  return searchSlice(collection[collection.indices])
}

/**
 Perform a binary search of the specified collection and return the index of the first
 element to satisfy `predicate` or nil.

 - parameter collection: C
 - parameter isOrderedBefore: (Element) -> Bool
 - parameter predicate: (Element) -> Bool

  - returns: C.Index?

 - requires: The collection to search is already sorted
 */
public func binarySearch<Element, C:CollectionType
  where C.Generator.Element == Element,
  C.Index:BidirectionalIndexType,
  C.SubSequence.SubSequence == C.SubSequence,
  C.SubSequence:CollectionType,
  C.SubSequence.Index == C.Index,
  C.SubSequence.Generator.Element == C._Element,
  C.SubSequence._Element == Element,
  C._Element == Element>(collection: C, isOrderedBefore: (Element) throws -> Bool, predicate: (Element) throws -> Bool) rethrows -> C.Index?
{
  func searchSlice(slice: C.SubSequence) throws -> C.Index? {
    let range = slice.indices
    let index = range.middleIndex
    let maybeElement = slice[index]
    guard try !predicate(maybeElement) else { return index }
    if try isOrderedBefore(maybeElement) && index.successor() != range.endIndex {
      return try searchSlice(slice[index.successor() ..< range.endIndex])
    } else if index != range.startIndex {
      return try searchSlice(slice[range.startIndex ..< index])
    }
    return nil
  }

  return try searchSlice(collection[collection.indices])
}


public func binaryInsertion<C:CollectionType
  where C.Generator.Element: Comparable,
  C.Index:BidirectionalIndexType,
  C.SubSequence.SubSequence == C.SubSequence,
  C.SubSequence:CollectionType,
  C.SubSequence.Index == C.Index,
  C.SubSequence.Generator.Element == C._Element,
  C.SubSequence._Element == C._Element,
  C._Element == C.Generator.Element>(collection: C, element: C.Generator.Element) -> C.Index
{
  guard !collection.isEmpty else { return collection.endIndex }
  guard collection[collection.startIndex] < element else { return collection.startIndex }
  guard collection[collection.endIndex.predecessor()] > element else { return collection.endIndex }

  func searchSlice(slice: C.SubSequence) -> C.Index {
    let range = slice.indices
    let index = range.middleIndex
    let maybeElement = slice[index]
    guard maybeElement != element else { return index }
    if maybeElement < element {
      guard index.successor() != range.endIndex else { return range.endIndex }

      return searchSlice(slice[index.successor() ..< range.endIndex])

    } else if maybeElement > element {
      guard index != range.startIndex else { return range.startIndex }
      return searchSlice(slice[range.startIndex ..< index])

    }
    return collection.endIndex
  }

  return searchSlice(collection[collection.indices])
}
