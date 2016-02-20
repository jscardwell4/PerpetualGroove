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
//public func ∪=<S1:SequenceType, S2:SequenceType
//  where S2.Generator.Element == S1.Generator.Element,
//        S1.Generator.Element:Equatable>(inout lhs: S1, rhs: S2)
//{
//  lhs.unionInPlace(rhs)
//}

// minus
public func ∖<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> [S1.Generator.Element]
{
  var result: [S1.Generator.Element] = []
  for element in lhs where element ∉ rhs { result.append(element) }
  return result
}
//public func ∖=<S1:SequenceType, S2:SequenceType
//  where S2.Generator.Element == S1.Generator.Element,
//        S1.Generator.Element:Equatable>(inout lhs: S1, rhs: S2)
//{
//  lhs.subtractInPlace(rhs)
//}

// intersect
public func ∩<S1:SequenceType, S2:SequenceType
  where S2.Generator.Element == S1.Generator.Element,
        S1.Generator.Element:Equatable>(lhs: S1, rhs: S2) -> [S1.Generator.Element]
{

  var result: [S1.Generator.Element] = []
  for element in lhs where element ∈ rhs { result.append(element) }
  return result
}
//public func ∩=<S1:SequenceType, S2:SequenceType
//  where S2.Generator.Element == S1.Generator.Element,
//        S1.Generator.Element:Equatable>(inout lhs: S1, rhs: S2)
//{
//  lhs.intersectInPlace(rhs)
//}

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
//public func ⊻=<S1:SequenceType, S2:SequenceType
//  where S2.Generator.Element == S1.Generator.Element,
//        S1.Generator.Element:Equatable>(inout lhs: S1, rhs: S2)
//{
//  lhs.exclusiveOrInPlace(rhs)
//}

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

//TODO: All of these set operations need revisiting now that there is a real `Set` type

//public func ∪<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T> (lhs:S0, rhs:S1) -> [T]
//{
//
//  return Array(lhs) + rhs.filter({lhs ∌ $0})
//}

//public func ∪=<T:Equatable, S:SequenceType where S.Generator.Element == T> (inout lhs:[T], rhs:S)
//{
//  return lhs += rhs.filter({lhs ∌ $0})
//}

//public func ∪<C:RangeReplaceableCollectionType, S:CollectionType 
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(lhs: C, rhs: S) -> C 
//{
//  return lhs + rhs.filter({lhs ∌ $0})
//}

//public func ∪<C:RangeReplaceableCollectionType, S:SequenceType 
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(lhs: C, rhs: S) -> C 
//{
//  return lhs + rhs.filter({lhs ∌ $0})
//}

//public func ∪<C:RangeReplaceableCollectionType, S:SequenceType 
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(lhs: S, rhs: C) -> C 
//{
//  return rhs + lhs.filter({rhs ∌ $0})
//}

//public func ∪=<C:RangeReplaceableCollectionType, S:CollectionType 
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(inout lhs: C, rhs: S)
//{
//  lhs.appendContentsOf(rhs.filter({lhs ∌ $0}))
//}

//public func ∪=<C:RangeReplaceableCollectionType, S:SequenceType 
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(inout lhs: C, rhs: S)
//{
//  lhs.appendContentsOf(rhs.filter({lhs ∌ $0}))
//}

//public func ⚭<C:RangeReplaceableCollectionType, S:CollectionType
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(lhs: C, rhs: S) -> Bool
//{
//  return (lhs ∩ rhs).count > 0
//}

//public func ⚭<C:RangeReplaceableCollectionType, S:SequenceType
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(lhs: C, rhs: S) -> Bool
//{
//  return (lhs ∩ rhs).count > 0
//}


//public func !⚭<C:RangeReplaceableCollectionType, S:CollectionType
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(lhs: C, rhs: S) -> Bool
//{
//  return !(lhs ⚭ rhs)
//}

//public func !⚭<C:RangeReplaceableCollectionType, S:SequenceType
//  where S.Generator.Element == C.Generator.Element, S.Generator.Element:Equatable>(lhs: C, rhs: S) -> Bool
//{
//  return !(lhs ⚭ rhs)
//}



//public func ∪=<T, C:RangeReplaceableCollectionType, S:SequenceType
//  where C.Generator.Element == S.Generator.Element> (inout lhs:C, rhs:S)
//{
//  appendContentsOf(&lhs, rhs)
//}

//public func ∖<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T> (lhs:S0, rhs:S1) -> [T]
//{
//  return lhs.filter { $0 ∉ rhs }
//}

//public func ∖=<C:RangeReplaceableCollectionType, S:SequenceType
//  where C.Generator.Element == S.Generator.Element, C.Generator.Element:Hashable>(inout lhs: C, rhs: S)
//{
//  for element in rhs { if let idx = lhs.indexOf(element) { lhs.removeAtIndex(idx) } }
//}

//public func ∩<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T> (lhs:S0, rhs:S1) -> [T]
//{
//  return uniqued(lhs ∪ rhs).filter {$0 ∈ lhs && $0 ∈ rhs}
//}

//public func ∩=<T:Equatable>(inout lhs:[T], rhs:[T]) { lhs = uniqued(lhs ∪ rhs).filter {$0 ∈ lhs && $0 ∈ rhs} }


/**
Returns true if rhs contains lhs

- parameter lhs: T
- parameter rhs: S
- returns: Bool
*/
//public func ∈<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:T, rhs:S) -> Bool {
//  return rhs.contains(lhs)
//}

/**
Returns true if rhs contains lhs

- parameter lhs: T?
- parameter rhs: S
- returns: Bool
*/
//public func ∈<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:T?, rhs:S) -> Bool {
//  return lhs != nil && rhs.contains(lhs!)
//}

/**
Returns true if rhs contains lhs

- parameter lhs: T
- parameter rhs: U
- returns: Bool
*/
//public func ∈ <T, U where U:IntervalType, T == U.Bound>(lhs:T, rhs:U) -> Bool { return rhs.contains(lhs) }
//public func ∈<O:OptionSetType where O.Element == O>(lhs: O, rhs: O) -> Bool { return rhs.contains(lhs) }

/**
Returns true if lhs contains rhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
//public func ∋<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:S, rhs:T) -> Bool { return rhs ∈ lhs }
//public func ∋<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:S, rhs:T?) -> Bool { return rhs ∈ lhs }
//public func ∋<T, U where U:IntervalType, T == U.Bound>(lhs:U, rhs:T) -> Bool { return lhs.contains(rhs) }
//public func ∋<O:OptionSetType where O.Element == O>(lhs: O, rhs: O) -> Bool { return lhs.contains(rhs) }

/**
Returns true if rhs does not contain lhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
//public func ∉<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:T, rhs:S) -> Bool { return !(lhs ∈ rhs) }
//public func ∉ <T, U where U:IntervalType, T == U.Bound>(lhs:T, rhs:U) -> Bool { return !(lhs ∈ rhs) }
//public func ∉<O:OptionSetType where O.Element == O>(lhs: O, rhs: O) -> Bool { return !(lhs ∈ rhs) }
/**
Returns true if lhs does not contain rhs

- parameter lhs: T
- parameter rhs: T
- returns: Bool
*/
//public func ∌ <T, U:IntervalType where T == U.Bound>(lhs:U, rhs:T) -> Bool { return !(lhs ∋ rhs) }
//public func ∌<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs:S, rhs:T) -> Bool { return !(lhs ∋ rhs) }

/**
Returns true if lhs is a subset of rhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
//public func ⊂<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs:S0, rhs:S1) -> Bool
//{
//  return lhs.filter({$0 ∉ rhs}).isEmpty
//}

/**
Returns true if lhs is a subset of rhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
//public func ⊆<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs:S0, rhs:S1) -> Bool
//{
//  return lhs ⊂ rhs
//}

/**
Returns true if lhs is not a subset of rhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
//public func ⊄<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
//{
//  return !(lhs ⊂ rhs)
//}

/**
Returns true if lhs is not a subset of rhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
//public func ⊈<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
//{
//  return lhs ⊄ rhs
//}

/**
Returns true if rhs is a subset of lhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
//public func ⊃<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
//{
//  return rhs ⊂ lhs
//}

/**
Returns true if rhs is not a subset of lhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
//public func ⊅<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
//{
//  return !(lhs ⊃ rhs)
//}

/**
Returns true if rhs is a subset of lhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
//public func ⊇<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
//{
//  return lhs ⊃ rhs
//}

/**
Returns true if rhs is not a subset of lhs

- parameter lhs: [T]
- parameter rhs: [T]
- returns: Bool
*/
//public func ⊉<T:Equatable, S0:SequenceType, S1:SequenceType
//  where S0.Generator.Element == T, S1.Generator.Element == T>(lhs: S0, rhs: S1) -> Bool
//{
//  return lhs ⊅ rhs
//}

//public func ∋<T1:RawRepresentable, T2:RawRepresentable
//  where T1.RawValue:BitwiseOperationsType, T1.RawValue:Equatable, T1.RawValue == T2.RawValue>(lhs: T1, rhs: T2) -> Bool
//{
//  return lhs.rawValue & rhs.rawValue == rhs.rawValue
//}
//
//public func ∈<T1:RawRepresentable, T2:RawRepresentable
//  where T1.RawValue:BitwiseOperationsType, T1.RawValue:Equatable, T1.RawValue == T2.RawValue>(lhs: T1, rhs: T2) -> Bool
//{
//  return rhs ∋ lhs
//}
//
//public func ∌<T1:RawRepresentable, T2:RawRepresentable
//  where T1.RawValue:BitwiseOperationsType, T1.RawValue:Equatable, T1.RawValue == T2.RawValue>(lhs: T1, rhs: T2) -> Bool
//{
//  return !(lhs ∋ rhs)
//}
//
//public func ∉<T1:RawRepresentable, T2:RawRepresentable
//  where T1.RawValue:BitwiseOperationsType, T1.RawValue:Equatable, T1.RawValue == T2.RawValue>(lhs: T1, rhs: T2) -> Bool
//{
//  return !(lhs ∈ rhs)
//}

