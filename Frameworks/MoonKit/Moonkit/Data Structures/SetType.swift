//
//  SetType.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation

public protocol SetType: CollectionType {
  typealias Element: Hashable
  init(minimumCapacity: Int)
  mutating func insert(member: Element)
  mutating func remove(member: Element) -> Element?
  func contains(member: Element) -> Bool
  func isSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
  func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
  func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
  func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
  func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
  func union<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Self
  mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S)
  func subtract<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Self
  mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S)
  func intersect<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Self
  mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S)
  func exclusiveOr<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Self
  mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S)
//  func ∈(lhs: Element, rhs: Self) -> Bool
//  func ∉(lhs: Element, rhs: Self) -> Bool
//  func ∋(lhs: Self, rhs: Element) -> Bool
//  func ∌(lhs: Self, rhs: Element) -> Bool
//  func ⊆<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Bool
//  func ⊈<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Bool
//  func ⊂<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Bool
//  func ⊄<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Bool
//  func ⚭<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Bool
//  func !⚭<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Bool
//  func ∪<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Self
//  func ∩<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Self
//  func ∖<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Self
//  func ⊻<S:SequenceType where S.Generator.Element == Element>(lhs: Self, rhs: S) -> Self
//  func ∪=<S:SequenceType where S.Generator.Element == Element>(inout lhs: Self, rhs: S)
//  func ∩=<S:SequenceType where S.Generator.Element == Element>(inout lhs: Self, rhs: S)
//  func ∖=<S:SequenceType where S.Generator.Element == Element>(inout lhs: Self, rhs: S)
//  func ⊻=<S:SequenceType where S.Generator.Element == Element>(inout lhs: Self, rhs: S)
}

