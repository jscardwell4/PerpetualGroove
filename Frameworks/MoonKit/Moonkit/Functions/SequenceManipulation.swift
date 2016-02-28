//
//  SequenceManipulation.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public extension SequenceType where Generator.Element:IntegerArithmeticType, Generator.Element:IntegerLiteralConvertible {
  public var sum: Generator.Element {
    let initial: Generator.Element = 0
    return reduce(initial, combine: {$0 + $1})
  }
}

public extension SequenceType where Generator.Element:ArithmeticType {
  public var sum: Generator.Element { return reduce(Generator.Element.init(), combine: +) }
}

public extension SequenceType where Generator.Element:CGFloatable {
  public var sum: CGFloat {
    let initial: CGFloat = 0
    return reduce(initial, combine: {$0 + $1.CGFloatValue})
  }
}

public extension SequenceType where Generator.Element: Named {
  public func sortByName() -> [Generator.Element] {
    return sort { $0.name < $1.name }
  }
}

public enum SegmentOptions<PadType> {
  case PadFirstGroup(PadType)
  case PadLastGroup(PadType)
  case UnpaddedFirstGroup
  case UnpaddedLastGroup
}
public extension SequenceType {

  /**
   bisect:

   - parameter predicate: (Self.Generator.Element) throws -> Bool
  */
  public func bisect(@noescape predicate: (Self.Generator.Element) throws -> Bool) rethrows -> ([Self.Generator.Element], [Self.Generator.Element]) {
    var group1: [Self.Generator.Element] = [], group2: [Self.Generator.Element] = []
    for element in self { if try predicate(element) { group1.append(element) } else { group2.append(element) } }
    return (group1, group2)
  }


  /**
  segment:options:

  - parameter segmentSize: Int = 2
  - parameter options: SegmentOptions<Generator.Element> = .Default

  - returns: [[Generator.Element]]
  */
  public func segment(segmentSize: Int = 2, options: SegmentOptions<Generator.Element> = .UnpaddedLastGroup) -> [[Generator.Element]] {
    var result: [[Generator.Element]] = []
    var array: [Generator.Element] = []
    let segmentSize = max(segmentSize, 1)

    switch options {
      case .UnpaddedLastGroup:
        for element in self {
          if array.count == segmentSize { result.append(array); array = [] }
          array.append(element)
        }
        result.append(array)

      case .PadLastGroup(let p):
        for element in self {
          if array.count == segmentSize { result.append(array); array = [] }
          array.append(element)
        }
        while array.count < segmentSize { array.append(p) }
        result.append(array)

      case .UnpaddedFirstGroup:
        for element in reverse() {
          if array.count == segmentSize { result.insert(array, atIndex: 0); array = [] }
          array.insert(element, atIndex: 0)
        }
        result.insert(array, atIndex: 0)

      case .PadFirstGroup(let p):
        for element in self {
          if array.count == segmentSize { result.insert(array, atIndex: 0); array = [] }
          array.insert(element, atIndex: 0)
        }
        while array.count < segmentSize { array.insert(p, atIndex: 0) }
        result.insert(array, atIndex: 0)

    }

    return result
  }

}

public struct InfiniteSequenceOf<T>: SequenceType {
  private let value: T
  public init(_ v: T) { value = v }
  public func generate() -> AnyGenerator<T> { return AnyGenerator(body: {self.value}) }
}

public func zip<S:SequenceType, T>(seq: S, value: T) -> [(S.Generator.Element, T)] {
  return Array(zip(seq, InfiniteSequenceOf(value)))
}

/**
sequence:T):

- parameter v: (T
- parameter T):

- returns: SequenceOf<T>
*/
public func sequence<T>(v: (T,T)) -> AnySequence<T> { return AnySequence([v.0, v.1]) }

/**
sequence:T:T):

- parameter v: (T
- parameter T:
- parameter T):

- returns: SequenceOf<T>
*/
public func sequence<T>(v: (T,T,T)) -> AnySequence<T> { return AnySequence([v.0, v.1, v.2]) }

/**
sequence:T:T:T):

- parameter v: (T
- parameter T:
- parameter T:
- parameter T):

- returns: SequenceOf<T>
*/
public func sequence<T>(v: (T,T,T,T)) -> AnySequence<T> { return AnySequence([v.0, v.1, v.2, v.3]) }

/**
disperse2:

- parameter s: S

- returns: (T, T)
*/
public func disperse2<S:SequenceType,T where S.Generator.Element == T>(s: S) -> (T, T) {
  let array = Array(s)
  return (array[0], array[1])
}

/**
disperse3:

- parameter s: S

- returns: (T, T, T)
*/
public func disperse3<S:SequenceType,T where S.Generator.Element == T>(s: S) -> (T, T, T) {
  let array = Array(s)
  return (array[0], array[1], array[2])
}

/**
disperse4:

- parameter s: S

- returns: (T, T, T, T)
*/
public func disperse4<S:SequenceType,T where S.Generator.Element == T>(s: S) -> (T, T, T, T) {
  let array = Array(s)
  return (array[0], array[1], array[2], array[3])
}

/**
Zip together two sequences as an array of tuples formed via cross product

- parameter s1: S1
- parameter s2: S2

- returns: [(S1.Generator.Element, S2.Generator.Element)]
*/
public func crossZip<S1:SequenceType, S2:SequenceType>(s1: S1, s2: S2) -> [(S1.Generator.Element, S2.Generator.Element)] {
  var result: [(S1.Generator.Element, S2.Generator.Element)] = []
  for outter in s1 {
    for inner in s2 {
      result.append((outter, inner))
    }
  }
  return result
}

/**
unzip:S1>:

- parameter z: Zip2<S0
- parameter S1>:

- returns: ([E0], [E1])
*/
public func unzip<S0:SequenceType, S1:SequenceType, E0, E1 where E0 == S0.Generator.Element, E1 == S1.Generator.Element>(z: Zip2Sequence<S0, S1>) -> ([E0], [E1]) {
  return z.reduce(([], []), combine: { (result: ([E0], [E1]), p: (E0, E1)) -> ([E0], [E1]) in
    var result = result
    result.0.append(p.0)
    result.1.append(p.1)
    return result
  })
}

/**
unzip:

- parameter s: S

- returns: ([E0], [E1])
*/
public func unzip<E0, E1, S:SequenceType where S.Generator.Element == (E0, E1)>(s: S) -> ([E0], [E1]) {
  return s.reduce(([], []), combine: { (result: ([E0], [E1]), p: (E0, E1)) -> ([E0], [E1]) in
    var result = result
    result.0.append(p.0)
    result.1.append(p.1)
    return result
  })
}

public func collect<T where T:GeneratorType>(generator: T) -> [T.Element] {
  var generator = generator
  var result: [T.Element] = []
  var done = false
  while !done { if let e = generator.next() { result += [e] } else { done = true } }
  return result
}

public func collectFrom<C:CollectionType, S:SequenceType where C.Index == S.Generator.Element>(source: C, indexes: S)
  -> [C.Generator.Element]
{
  var result: [C.Generator.Element] = []
  for idx in indexes { result.append(source[idx]) }
  return result
}


