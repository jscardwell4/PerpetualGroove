//
//  SetOperations.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/// Set operations for regular sequences

// contains
public func ∈<S:SequenceType
  where S.Generator.Element:Equatable>(lhs: S.Generator.Element, rhs: S) -> Bool
{
  return rhs.contains(lhs)
}
public func ∋<S:SequenceType
  where S.Generator.Element:Equatable>(lhs: S, rhs: S.Generator.Element) -> Bool
{
  return lhs.contains(rhs)
}

public func ∉<S:SequenceType
  where S.Generator.Element:Equatable>(lhs: S.Generator.Element, rhs: S) -> Bool
{
  return !(lhs ∈ rhs)
}
public func ∌<S:SequenceType
  where S.Generator.Element:Equatable>(lhs: S, rhs: S.Generator.Element) -> Bool
{
  return !(lhs ∋ rhs)
}

// subset/superset
public func ⊂<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  return lhs ⊆ rhs && lhs.underestimateCount() < rhs.underestimateCount()
}
public func ⊃<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  return rhs ⊂ lhs
}
public func ⊆<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  for element in lhs { guard rhs.contains(element) else { return false } }
  return true
}
public func ⊇<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  return rhs ⊆ lhs
}
public func ⊄<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  return !(lhs ⊂ rhs)
}
public func ⊅<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  return !(lhs ⊃ rhs)
}
public func ⊈<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  return !(lhs ⊆ rhs)
}
public func ⊉<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  return !(lhs ⊇ rhs)
}

// union
public func ∪<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> [S1.Generator.Element]
{
  var result = Array(lhs)
  for element in rhs where element ∉ lhs { result.append(element) }
  return result
}

// minus
public func ∖<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> [S1.Generator.Element]
{
  var result: [S1.Generator.Element] = []
  for element in lhs where element ∉ rhs { result.append(element) }
  return result
}

// intersect
public func ∩<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> [S1.Generator.Element]
{

  var result: [S1.Generator.Element] = []
  for element in lhs where element ∈ rhs { result.append(element) }
  return result
}

// xor
public func ⊻<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> [S1.Generator.Element]
{
  var result: [S1.Generator.Element] = []
  for element in lhs where element ∉ rhs { result.append(element) }
  for element in rhs where element ∉ lhs { result.append(element) }
  return result
}

// disjoint
public func !⚭<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  for element in lhs { guard element ∉ rhs else { return false } }
  return true
}
public func ⚭<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> Bool
{
  return !(lhs ⚭ rhs)
}

