//
//  Generic.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/5/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation


public func ~=<T:Equatable>(lhs: T?, rhs: T?) -> Bool {
  if let l = lhs, r = rhs where l ~= r { return true }
  else if lhs == nil && rhs == nil { return true }
  else { return false }
}

public func typeCast<T,U>(t: T, _ u: U.Type) -> U? { return t as? U }
public func typeCast<T,U>(t: T?, _ u: U.Type) -> U? { return t != nil ? typeCast(t!, u) : nil }

public func **<T:IntegerArithmeticType>(lhs: T, rhs: T) -> T {
  return (1..<rhs.toIntMax()).reduce(lhs, combine: {n, _ in n * lhs})
}

public func **(lhs: Float, rhs: Int) -> Float {
  return (0..<rhs).reduce(Float(0.0), combine: {n, _ in n * lhs})
}

public func **(lhs: Double, rhs: Int) -> Double {
  return (0..<rhs).reduce(0.0, combine: {n, _ in n * lhs})
}

public func **(lhs: CGFloat, rhs: Int) -> CGFloat {
  return (0..<rhs).reduce(CGFloat(0.0), combine: {n, _ in n * lhs})
}

public func sum<S:SequenceType where S.Generator.Element == CGFloat>(s: S) -> CGFloat {
  return s.reduce(CGFloat(), combine: {$0 + $1})
}

public func sum<S:SequenceType where S.Generator.Element == Float>(s: S) -> Float {
  return s.reduce(Float(), combine: {$0 + $1})
}

public func sum<S:SequenceType where S.Generator.Element == Double>(s: S) -> Double {
  return s.reduce(0.0, combine: {$0 + $1})
}

public func sum<S:SequenceType where S.Generator.Element:IntegerArithmeticType>(s: S) -> IntMax {
  return s.reduce(0, combine: {$0 + $1.toIntMax()})
}

public func sum<S:SequenceType where S.Generator.Element:ArithmeticType>(s: S) -> S.Generator.Element {
  return s.reduce(S.Generator.Element(), combine: +)
}

/**
advance:amount:

- parameter range: Range<T>
- parameter amount: T.Distance
*/
public func advance<T: ForwardIndexType>(inout range: Range<T>, amount: T.Distance) {
  let d = distance(range.startIndex, range.endIndex)
  let start: T = advance(range.startIndex, amount)
  let end: T = advance(range.startIndex, amount + d)
  range = Range<T>(start: start, end: end)
}

/**
join:elements:

- parameter seperator: T
- parameter elements: [T]

- returns: [T]
*/
public func join<T>(seperator: T, _ elements: [T]) -> [T] {
  if elements.count > 1 {
    var joinedElements: [T] = []
    for element in elements[0..<(elements.count - 1)] {
      joinedElements.append(element)
      joinedElements.append(seperator)
    }
    joinedElements.append(elements.last!)
    return joinedElements
  } else {
    return elements
  }
}

/**
advance:amount:

- parameter range: Range<T>
- parameter amount: T.Distance

- returns: Range<T>
*/
public func advance<T: ForwardIndexType>(range: Range<T>, amount: T.Distance) -> Range<T> {
  return Range<T>(start: advance(range.startIndex, amount), end: advance(range.endIndex, amount))
}

/**
find:value:

- parameter domain: C
- parameter value: C.Generator.Element?

- returns: C.Index?
*/
public func find<C: CollectionType where C.Generator.Element: Equatable>(domain: C, _ value: C.Generator.Element?) -> C.Index? {
  if let v = value { return domain.indexOf(v) } else { return nil }
}

/**
findFirst:predicate:

- parameter domain: S
- parameter predicate: (S.Generator.Element) -> Bool

- returns: (C.Generator.Element)?
*/
public func findFirst<S: SequenceType>(domain: S?, _ predicate: (S.Generator.Element) -> Bool) -> (S.Generator.Element)? {
  if let sequence = domain { for element in sequence { if predicate(element) { return element } } }
  return nil
}

/**
length:

- parameter interval: ClosedInterval<T>

- returns: T.Stride
*/
public func length<T:Strideable>(interval: ClosedInterval<T>) -> T.Stride { return interval.start.distanceTo(interval.end) }


/**
toString:

- parameter x: T?

- returns: String
*/
public func toString<T>(x: T?) -> String { if let xx = x { return String(xx) } else { return "nil" } }


public func +(lhs: Range<Int>, rhs: Int) -> Range<Int> { return lhs.startIndex + rhs ..< lhs.endIndex + rhs }


/**
The Box class is used to box values and as a workaround to the limitations with generics in the compiler. 
From "Functional Programming in Swift", www.objc.io
*/
public class Box<T> { public let unbox: T; public init(_ value: T) { unbox = value } }


