//
//  FunctionManipulation.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/**
Compose operator

- parameter f: A -> B
- parameter g: B -> C

- returns: A -> C
*/
public func ∘<A, B, C>(f: A -> B, g: B -> C) -> A -> C { return {g(f($0))} }

/**
The curry functions turn a function with x arguments into a series of x functions, each accepting one argument.
From "Functional Programming in Swift", www.objc.io
*/
public func curry<A, B, C>( f: (A, B) -> C) -> A -> B -> C {
  return { x in { y in f(x, y) } }
}
public func curry<A, B, C, D>( f: (A, B, C) -> D) -> A -> B -> C -> D {
  return { a in { b in { c in f( a, b, c) } } }
}


/**
Apple's memoized function producer

- parameter body: ((T) -> U
- parameter T:

- returns: U) -> (T) -> U
*/
public func memoize<T: Hashable, U>(body: ((T) -> U, T) -> U) -> (T) -> U {
  var memo: [T:U] = [:]
  var result: (T -> U)!
  result = {
    (t: T) -> U in
    if let q = memo[t] { return q }
    let r = body(result, t)
    memo[t] = r
    return r
  }
  return result
}

/**
The flip function reverses the order of the arguments of the function you pass into it.
From "Functional Programming in Swift", www.objc.io
*/
public func flip<A, B, C>( f: (B, A) -> C) -> (A, B) -> C { return {f($1, $0)} }

/**
A func for inverting a closure that returns a `Bool` given a single parameter `T`

- parameter f: T -> Bool

- returns: T -> Bool
*/
public func invert<T>(f: T -> Bool) -> T -> Bool { return {!f($0)} }

/**
The function is a simple wrapper around `reduce` that ignores the actual reduction as a way to visit every element

- parameter sequence: S
- parameter block: (S.Generator.Element) -> Void
*/
public func apply<S:SequenceType>(sequence: S, _ f: (S.Generator.Element) -> Void) { sequence.reduce(Void(), combine: { f($0.1) }) }
public func apply<T>(x: T, _ f: (T) -> Void) { f(x) }
//public func apply<T, U>(x: T, f: (T) -> U) -> U { return f(x) }

public extension SequenceType {
  public func apply(f: Generator.Element -> Void) { reduce(Void(), combine: { f($0.1) }) }
  public func pairwiseApply(f: (Generator.Element, Generator.Element) -> Void) {
    AnySequence({() -> AnyGenerator<(Generator.Element, Generator.Element)> in
      let sequenceArray = Array(self)
      var i = 1
      return anyGenerator({
        let result: (Generator.Element, Generator.Element)?
        if i < sequenceArray.count { result = (sequenceArray[i - 1], sequenceArray[i]) } else { result = nil }
        i++
        return result
      })
    }).apply(f)

  }
}

public func applyMaybe<S:SequenceType>(sequence: S?, _ f: (S.Generator.Element) -> Void) { if let s = sequence { apply(s, f) } }
public func applyMaybe<T>(x: T?, _ f: (T) -> Void) { if let x = x { apply(x, f) } }

public func pairwiseApply<S:SequenceType>(sequence: S, _ f: (S.Generator.Element, S.Generator.Element) -> Void) {
  apply(AnySequence({() -> AnyGenerator<(S.Generator.Element, S.Generator.Element)> in
    let sequenceArray = Array(sequence)
    var i = 1
    return anyGenerator({
      let result: (S.Generator.Element, S.Generator.Element)?
      if i < sequenceArray.count { result = (sequenceArray[i - 1], sequenceArray[i]) } else { result = nil }
      i++
      return result
    })
  }), f)
}

/**
A function that simply calls `apply` and then returns the sequence

- parameter sequence: S
- parameter block: (S.Generator.Element) -> Void

- returns: S
*/
public func pipedApply<S:SequenceType>(x: S, _ f: (S.Generator.Element) -> Void) -> S { apply(x, f); return x }
public func pipedApply<T>(x: T, _ f: (T) -> Void) -> T { f(x); return x }

/** Operator function for the `apply` function */
public func ➤<S:SequenceType>(lhs: S, rhs: (S.Generator.Element) -> Void) { apply(lhs, rhs) }
public func ➤<T>(lhs: T, rhs: (T) -> Void) { apply(lhs, rhs) }
public func ➤|<T, U>(lhs: T, rhs: (T) -> U) -> U { return rhs(lhs) }

/** Operator function for the `chainApply` function */
public func ➤|<S:SequenceType>(lhs: S, rhs: (S.Generator.Element) -> Void) -> S { return pipedApply(lhs, rhs) }
public func ➤|<T>(lhs: T, rhs: (T) -> Void) -> T { return pipedApply(lhs, rhs) }

/** Piping operator */
public func >>><T>(lhs: T, rhs: T -> Void) { rhs(lhs) }
public func >>><T, U>(lhs: T, rhs: T -> U) -> U { return rhs(lhs) }
public func >>><T, U>(lhs: T, rhs: U) -> (T, U) { return (lhs, rhs) }
public func >>><T, U, V>(lhs: (T, U), rhs: (T, U) -> V) -> V { return rhs(lhs) }

/** Operator for monadic bind */
//public func ?>><T, U>(lhs: T?, rhs: T -> U?) -> U? { return flatMap(lhs, rhs) }
public func ?>><T>(lhs: T?, rhs: T -> Void) { if let x = lhs { rhs(x) } }
public func ?>><T,U>(lhs: T?, rhs: T -> U) -> U? { if let x = lhs { return rhs(x) } else { return nil } }

/** Accumulating args */
public func >?><T, U>(lhs: T?, rhs: U) -> (T, U)? { if let x = lhs { return (x, rhs) } else { return nil } }
public func >?><T, U, V>(lhs: (T, U)?, rhs: (T, U) -> V) -> V? { if let x = lhs { return rhs(x) } else { return nil } }

