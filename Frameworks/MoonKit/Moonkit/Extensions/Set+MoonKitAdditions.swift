//
//  Set+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/31/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
/*
// contains
public func ∈<Element:Hashable>(lhs: Element, rhs: Set<Element>) -> Bool {
  return rhs.contains(lhs)
}
public func ∋<Element:Hashable>(lhs: Set<Element>, rhs: Element) -> Bool {
  return lhs.contains(rhs)
}

public func ∉<Element:Hashable>(lhs: Element, rhs: Set<Element>) -> Bool { return !(lhs ∈ rhs) }
public func ∌<Element:Hashable>(lhs: Set<Element>, rhs: Element) -> Bool { return !(lhs ∋ rhs) }

// subset/superset
public func ⊂<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return lhs.isStrictSubsetOf(rhs)
}
public func ⊃<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return lhs.isStrictSupersetOf(rhs)
}
public func ⊆<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return lhs.isSubsetOf(rhs)
}
public func ⊇<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return lhs.isSupersetOf(rhs)
}
public func ⊄<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return !(lhs ⊂ rhs)
}
public func ⊅<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return !(lhs ⊃ rhs)
}
public func ⊈<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return !(lhs ⊆ rhs)
}
public func ⊉<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return !(lhs ⊇ rhs)
}

// union
public func ∪<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Set<Element>
{
  return lhs.union(rhs)
}
public func ∪=<S:SequenceType
  where S.Generator.Element:Hashable>(inout lhs: Set<S.Generator.Element>, rhs: S)
{
  lhs.unionInPlace(rhs)
}

// minus
public func ∖<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Set<Element>
{
  return lhs.subtract(rhs)
}
public func ∖=<S:SequenceType
  where S.Generator.Element:Hashable>(inout lhs: Set<S.Generator.Element>, rhs: S)
{
  lhs.subtractInPlace(rhs)
}

// intersect
public func ∩<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Set<Element>
{
  return lhs.intersect(rhs)
}
public func ∩=<S:SequenceType
  where S.Generator.Element:Hashable>(inout lhs: Set<S.Generator.Element>, rhs: S)
{
  lhs.intersectInPlace(rhs)
}

// xor
public func ⊻<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Set<Element>
{
  return lhs.exclusiveOr(rhs)
}
public func ⊻=<S:SequenceType
  where S.Generator.Element:Hashable>(inout lhs: Set<S.Generator.Element>, rhs: S)
{
  lhs.exclusiveOrInPlace(rhs)
}

// disjoint
public func !⚭<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return lhs.isDisjointWith(rhs)
}
public func ⚭<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: Set<Element>, rhs: S) -> Bool
{
  return !lhs.isDisjointWith(rhs)
}
*/
//public func filter<T>(source: Set<T>, includeElement: (T) -> Bool) -> Set<T> {
//  return Set(Array(source).filter(includeElement))
//}

extension Set: PrettyPrint {
  public var prettyDescription: String {
    return Array(self).prettyDescription
  }
}

extension Set: SetType {
  // Can't actually do anything here without knowledge of the set's current capacity
  public mutating func reserveCapacity(capacity: Int) { }
}

extension Set: NestingContainer {
  public var topLevelObjects: [Any] {
    var result: [Any] = []
    for value in self {
      result.append(value as Any)
    }
    return result
  }
  public func topLevelObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in self {
      if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
  public var allObjects: [Any] {
    var result: [Any] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.appendContentsOf(container.allObjects)
      } else {
        result.append(value as Any)
      }
    }
    return result
  }
  public func allObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.appendContentsOf(container.allObjects(type))
      } else if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
}

extension Set: KeySearchable {
  public var allValues: [Any] { return topLevelObjects }
}
