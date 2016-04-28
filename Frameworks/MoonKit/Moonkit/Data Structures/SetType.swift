//
//  SetType.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation

public protocol SetType: CollectionType {
  associatedtype Element = Self.Generator.Element //: Hashable

  init(minimumCapacity: Int)
  init<S:SequenceType where S.Generator.Element == Self.Generator.Element>(_ elements: S)

  mutating func insert(member: Self.Generator.Element)
  mutating func remove(member: Self.Generator.Element) -> Self.Generator.Element?

  mutating func reserveCapacity(capacity: Int)

  func contains(member: Self.Generator.Element) -> Bool
  func ∈ (lhs: Self.Generator.Element, rhs: Self) -> Bool
  func ∉ (lhs: Self.Generator.Element, rhs: Self) -> Bool

  func ∋ (lhs: Self, rhs: Self.Generator.Element) -> Bool
  func ∌ (lhs: Self, rhs: Self.Generator.Element) -> Bool

  func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func ⊂<S:SequenceType where S.Generator.Element == Self.Generator.Element> (lhs: Self, rhs: S) -> Bool
  func ⊄<S:SequenceType where S.Generator.Element == Self.Generator.Element> (lhs: Self, rhs: S) -> Bool

  func isSupersetOf<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func ⊃<S:SequenceType where S.Generator.Element == Self.Generator.Element> (lhs: Self, rhs: S) -> Bool
  func ⊅<S:SequenceType where S.Generator.Element == Self.Generator.Element> (lhs: Self, rhs: S) -> Bool

  func isSubsetOf<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func ⊆<S:SequenceType where S.Generator.Element == Self.Generator.Element> (lhs: Self, rhs: S) -> Bool
  func ⊈<S:SequenceType where S.Generator.Element == Self.Generator.Element> (lhs: Self, rhs: S) -> Bool

  func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func ⊇<S:SequenceType where S.Generator.Element == Self.Generator.Element> (lhs: Self, rhs: S) -> Bool
  func ⊉<S:SequenceType where S.Generator.Element == Self.Generator.Element> (lhs: Self, rhs: S) -> Bool

  func isDisjointWith<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func ⚭<S:SequenceType where S.Generator.Element == Self.Generator.Element>(lhs: Self, rhs: S) -> Bool
  func !⚭<S:SequenceType where S.Generator.Element == Self.Generator.Element>(lhs: Self, rhs: S) -> Bool

  func union<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Self
  func ∪<S:SequenceType where S.Generator.Element == Self.Generator.Element>(lhs: Self, rhs: S) -> Self

  mutating func unionInPlace<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S)
  func ∪=<S:SequenceType where S.Generator.Element == Self.Generator.Element>(inout lhs: Self, rhs: S)

  func subtract<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Self
  func ∖<S:SequenceType where S.Generator.Element == Self.Generator.Element>(lhs: Self, rhs: S) -> Self

  mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S)
  func ∖=<S:SequenceType where S.Generator.Element == Self.Generator.Element>(inout lhs: Self, rhs: S)

  func intersect<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Self
  func ∩<S:SequenceType where S.Generator.Element == Self.Generator.Element>(lhs: Self, rhs: S) -> Self

  mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S)
  func ∩=<S:SequenceType where S.Generator.Element == Self.Generator.Element>(inout lhs: Self, rhs: S)

  func exclusiveOr<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Self
  func ⊻<S:SequenceType where S.Generator.Element == Self.Generator.Element>(lhs: Self, rhs: S) -> Self

  mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S)
  func ⊻=<S:SequenceType where S.Generator.Element == Self.Generator.Element>(inout lhs: Self, rhs: S)

 
}

// contains
public func ∈<S:SetType>(lhs: S.Generator.Element, rhs: S) -> Bool { return rhs.contains(lhs) }
public func ∉<S:SetType>(lhs: S.Generator.Element, rhs: S) -> Bool { return !(lhs ∈ rhs) }

public func ∋<S:SetType>(lhs: S, rhs: S.Generator.Element) -> Bool { return lhs.contains(rhs) }
public func ∌<S:SetType>(lhs: S, rhs: S.Generator.Element) -> Bool { return !(lhs ∋ rhs) }

// subset
public func ⊂<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isStrictSubsetOf(rhs)
}
public func ⊄<S1:SetType, S2:SequenceType
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !lhs.isStrictSubsetOf(rhs)
}

public func ⊆<S1:SetType, S2:SequenceType
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isSubsetOf(rhs)
}
public func ⊈<S1:SetType, S2:SequenceType
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !lhs.isSubsetOf(rhs)
}

// superset
public func ⊃<S1:SetType, S2:SequenceType
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isStrictSupersetOf(rhs)
}
public func ⊅<S1:SetType, S2:SequenceType
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !lhs.isStrictSupersetOf(rhs)
}

public func ⊇<S1:SetType, S2:SequenceType
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isSupersetOf(rhs)
}
public func ⊉<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !lhs.isSupersetOf(rhs)
}

// disjoint
public func !⚭<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isDisjointWith(rhs)
}
public func ⚭<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !lhs.isDisjointWith(rhs)
}

// union
public func ∪<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> S1 
{ 
  return lhs.union(rhs)
}
public func ∪=<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(inout lhs: S1, rhs: S2) 
{ 
  lhs.unionInPlace(rhs)
}
public func ∪<S:SetType>(lhs: S, rhs: S.Generator.Element) -> S { var lhs = lhs; lhs ∪= rhs; return lhs }
public func ∪=<S:SetType>(inout lhs: S, rhs: S.Generator.Element) { lhs.insert(rhs) }
public func ∪=<S:SetType>(inout lhs: S, rhs: S) { lhs.unionInPlace(rhs) }

// minus
public func ∖<S1:SetType, S2:SequenceType
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> S1 
{ 
  return lhs.subtract(rhs)
}
public func ∖=<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(inout lhs: S1, rhs: S2) 
{ 
  lhs.subtractInPlace(rhs)
}
public func ∖<S:SetType>(lhs: S, rhs: S.Generator.Element) -> S { var lhs = lhs; lhs ∖= rhs; return lhs }
public func ∖=<S:SetType>(inout lhs: S, rhs: S.Generator.Element) { lhs.remove(rhs) }

// intersect
public func ∩<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> S1 
{ 
  return lhs.intersect(rhs)
}
public func ∩=<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(inout lhs: S1, rhs: S2) 
{ 
  lhs.intersectInPlace(rhs)
}

// xor
public func ⊻<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> S1 
{ 
  return lhs.exclusiveOr(rhs)
}
public func ⊻=<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(inout lhs: S1, rhs: S2)
{ 
  lhs.exclusiveOrInPlace(rhs)
}
//public func ⊻<S:SetType>(lhs: S, rhs: S.Generator.Element) -> S {
//  var rhsSet = S(minimumCapacity: 1)
//  rhsSet.insert(rhs)
//  return lhs ⊻ rhsSet
//}
//public func ⊻=<S:SetType>(inout lhs: S, rhs: S.Generator.Element) {
//  var rhsSet = S(minimumCapacity: 1)
//  rhsSet.insert(rhs)
//  lhs ⊻= rhsSet
//}
