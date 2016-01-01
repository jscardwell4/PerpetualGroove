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

