//
//  SetOperations.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

//TODO: All of these set operations need revisiting now that there is a real `Set` type

public func ∪<T, S0:SequenceType, S1:SequenceType
  where S0.Generator.Element == T, S1.Generator.Element == T> (lhs:S0, rhs:S1) -> [T]
{
  return Array(lhs) + Array(rhs)
}

//public func ∪=<T, C:RangeReplaceableCollectionType, S:SequenceType
//  where C.Generator.Element == S.Generator.Element> (inout lhs:C, rhs:S)
//{
//  extend(&lhs, rhs)
//}

public func ∖<T:Equatable, S0:SequenceType, S1:SequenceType
  where S0.Generator.Element == T, S1.Generator.Element == T> (lhs:S0, rhs:S1) -> [T]
{
  return lhs.filter { $0 ∉ rhs }
}

public func ∖=<C:RangeReplaceableCollectionType, S:SequenceType
  where C.Generator.Element == S.Generator.Element, C.Generator.Element:Hashable>(inout lhs: C, rhs: S)
{
  let rhsElements = Set(rhs)
  for i in lhs.startIndex..<lhs.endIndex { if rhsElements.contains(lhs[i]) { lhs.removeAtIndex(i) } }
}

public func ∩<T:Equatable, S0:SequenceType, S1:SequenceType
  where S0.Generator.Element == T, S1.Generator.Element == T> (lhs:S0, rhs:S1) -> [T]
{
  return uniqued(lhs ∪ rhs).filter {$0 ∈ lhs && $0 ∈ rhs}
}

//public func ∩=<T:Equatable>(inout lhs:[T], rhs:[T]) { lhs = uniqued(lhs ∪ rhs).filter {$0 ∈ lhs && $0 ∈ rhs} }


/**
Returns true if rhs contains lhs

- parameter lhs: T
- parameter rhs: S
- returns: Bool
*/
public func ∈<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:T, rhs:S) -> Bool {
  return rhs.contains(lhs)
}

/**
Returns true if rhs contains lhs

- parameter lhs: T?
- parameter rhs: S
- returns: Bool
*/
public func ∈<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:T?, rhs:S) -> Bool {
  return lhs != nil && rhs.contains(lhs!)
}

/**
Returns true if rhs contains lhs

- parameter lhs: T
- parameter rhs: U
- returns: Bool
*/
public func ∈ <T, U where U:IntervalType, T == U.Bound>(lhs:T, rhs:U) -> Bool { return rhs.contains(lhs) }

/**
Returns true if lhs contains rhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
public func ∋<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:S, rhs:T) -> Bool { return rhs ∈ lhs }
public func ∋ <T, U where U:IntervalType, T == U.Bound>(lhs:U, rhs:T) -> Bool { return lhs.contains(rhs) }

/**
Returns true if rhs does not contain lhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
public func ∉<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:T, rhs:S) -> Bool { return !(lhs ∈ rhs) }
public func ∉ <T, U where U:IntervalType, T == U.Bound>(lhs:T, rhs:U) -> Bool { return !(lhs ∈ rhs) }

/**
Returns true if lhs does not contain rhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
public func ∌ <T, U:IntervalType where T == U.Bound>(lhs:U, rhs:T) -> Bool { return !(lhs ∋ rhs) }
public func ∌<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:S, rhs:T) -> Bool { return !(lhs ∋ rhs) }

/**
Returns true if lhs is a subset of rhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
public func ⊂<T:Equatable, S0:SequenceType, S1:SequenceType
  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs:S0, rhs:S1) -> Bool
{
  return lhs.filter({$0 ∉ rhs}).isEmpty
}

/**
Returns true if lhs is not a subset of rhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
public func ⊄<T:Equatable, S0:SequenceType, S1:SequenceType
  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
{
  return !(lhs ⊂ rhs)
}

/**
Returns true if rhs is a subset of lhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
public func ⊃<T:Equatable, S0:SequenceType, S1:SequenceType
  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
{
  return rhs ⊂ lhs
}

/**
Returns true if rhs is not a subset of lhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
public func ⊅<T:Equatable, S0:SequenceType, S1:SequenceType
  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
{
  return !(lhs ⊃ rhs)
}
