//
//  SetType.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation

public protocol SetType: CollectionType {
  associatedtype Element: Hashable
  init(minimumCapacity: Int)
  init<S:SequenceType where S.Generator.Element == Self.Generator.Element>(_ elements: S)
  mutating func insert(member: Element)
  mutating func remove(member: Element) -> Element?
  func contains(member: Element) -> Bool
  func isSubsetOf<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func isSupersetOf<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func isDisjointWith<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Bool
  func union<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Self
  mutating func unionInPlace<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S)
  func subtract<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Self
  mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S)
  func intersect<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Self
  mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S)
  func exclusiveOr<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S) -> Self
  mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Self.Generator.Element>(sequence: S)
}

// contains
public func ∈<S:SetType>(lhs: S.Element, rhs: S) -> Bool { return rhs.contains(lhs) }
public func ∋<S:SetType>(lhs: S, rhs: S.Element) -> Bool { return lhs.contains(rhs) }

public func ∉<S:SetType>(lhs: S.Element, rhs: S) -> Bool { return !(lhs ∈ rhs) }
public func ∌<S:SetType>(lhs: S, rhs: S.Element) -> Bool { return !(lhs ∋ rhs) }

// subset/superset
public func ⊂<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isStrictSubsetOf(rhs)
}
public func ⊃<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isStrictSupersetOf(rhs)
}
public func ⊆<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isSubsetOf(rhs)
}
public func ⊇<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return lhs.isSupersetOf(rhs)
}

public func ⊄<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !(lhs ⊂ rhs)
}
public func ⊅<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !(lhs ⊃ rhs)
}
public func ⊈<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !(lhs ⊆ rhs)
}
public func ⊉<S1:SetType, S2:SequenceType 
               where S1.Generator.Element == S2.Generator.Element>(lhs: S1, rhs: S2) -> Bool 
{ 
  return !(lhs ⊇ rhs)
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
public func ∪<S:SetType>(lhs: S, rhs: S.Element) -> S { var lhs = lhs; lhs ∪= rhs; return lhs }
public func ∪=<S:SetType>(inout lhs: S, rhs: S.Element) { lhs.insert(rhs) }

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
public func ∖<S:SetType>(lhs: S, rhs: S.Element) -> S { var lhs = lhs; lhs ∖= rhs; return lhs }
public func ∖=<S:SetType>(inout lhs: S, rhs: S.Element) { lhs.remove(rhs) }

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
public func ⊻<S:SetType>(lhs: S, rhs: S.Element) -> S {
  var rhsSet = S(minimumCapacity: 1)
  rhsSet.insert(rhs)
  return lhs ⊻ rhsSet
}
public func ⊻=<S:SetType>(inout lhs: S, rhs: S.Element) {
  var rhsSet = S(minimumCapacity: 1)
  rhsSet.insert(rhs)
  lhs ⊻= rhsSet
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
  return !(lhs !⚭ rhs)
}
public func !⚭<S:SetType>(lhs: S, rhs: S.Element) -> Bool { return !lhs.contains(rhs) }
public func ⚭<S:SetType>(lhs: S, rhs: S.Element) -> Bool { return lhs.contains(rhs) }
