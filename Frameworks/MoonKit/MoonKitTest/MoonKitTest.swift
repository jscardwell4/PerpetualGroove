//
//  MoonKitTest.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/15/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation
@_exported import Nimble
import MoonKit

public final class MoonKitTest {

  public static let integersXXSmall1 = srandomIntegers(0, 100, 0 ..< 50)
  public static let integersXXSmall2 = srandomIntegers(0, 100, 0 ..< 50)

  public static let integersXSmall1  = srandomIntegers(0, 250, 0 ..< 125)
  public static let integersXSmall2  = srandomIntegers(0, 250, 0 ..< 125)

  public static let integersSmall1   = srandomIntegers(0, 500, 0 ..< 250)
  public static let integersSmall2   = srandomIntegers(0, 500, 0 ..< 250)

  public static let integersMedium1  = srandomIntegers(0, 10000, 0 ..< 2000)
  public static let integersMedium2  = srandomIntegers(0, 10000, 0 ..< 2000)

  public static let integersLarge1   = srandomIntegers(0, 50000, 0 ..< 10000)
  public static let integersLarge2   = srandomIntegers(0, 50000, 0 ..< 10000)

  public static let integersXLarge1  = srandomIntegers(0, 100000, 0 ..< 20000)
  public static let integersXLarge2  = srandomIntegers(0, 100000, 0 ..< 20000)

  public static let integersXXLarge1 = srandomIntegers(0, 200000, 0 ..< 40000)
  public static let integersXXLarge2 = srandomIntegers(0, 200000, 0 ..< 40000)

  public static let stringsXXSmall1  = randomIntegersXXSmall1.map {String($0)}
  public static let stringsXXSmall2  = randomIntegersXXSmall2.map {String($0)}

  public static let stringsXSmall1   = randomIntegersXSmall1.map {String($0)}
  public static let stringsXSmall2   = randomIntegersXSmall2.map {String($0)}

  public static let stringsSmall1    = randomIntegersSmall1.map {String($0)}
  public static let stringsSmall2    = randomIntegersSmall2.map {String($0)}

  public static let stringsMedium1   = randomIntegersMedium1.map {String($0)}
  public static let stringsMedium2   = randomIntegersMedium2.map {String($0)}

  public static let stringsLarge1    = randomIntegersLarge1.map {String($0)}
  public static let stringsLarge2    = randomIntegersLarge2.map {String($0)}

  public static let stringsXLarge1   = randomIntegersXLarge1.map {String($0)}
  public static let stringsXLarge2   = randomIntegersXLarge2.map {String($0)}

  public static let stringsXXLarge1  = randomIntegersXXLarge1.map {String($0)}
  public static let stringsXXLarge2  = randomIntegersXXLarge2.map {String($0)}

  public static let randomIntegersXXSmall1 = randomIntegers(100, 0 ..< 50)
  public static let randomIntegersXXSmall2 = randomIntegers(100, 0 ..< 50)

  public static let randomIntegersXSmall1  = randomIntegers(250, 0 ..< 125)
  public static let randomIntegersXSmall2  = randomIntegers(250, 0 ..< 125)

  public static let randomIntegersSmall1   = randomIntegers(500, 0 ..< 250)
  public static let randomIntegersSmall2   = randomIntegers(500, 0 ..< 250)

  public static let randomIntegersMedium1  = randomIntegers(10000, 0 ..< 2000)
  public static let randomIntegersMedium2  = randomIntegers(10000, 0 ..< 2000)

  public static let randomIntegersLarge1   = randomIntegers(50000, 0 ..< 10000)
  public static let randomIntegersLarge2   = randomIntegers(50000, 0 ..< 10000)

  public static let randomIntegersXLarge1  = randomIntegers(100000, 0 ..< 20000)
  public static let randomIntegersXLarge2  = randomIntegers(100000, 0 ..< 20000)

  public static let randomIntegersXXLarge1 = randomIntegers(200000, 0 ..< 40000)
  public static let randomIntegersXXLarge2 = randomIntegers(200000, 0 ..< 40000)

  public static let randomStringsXXSmall1  = randomIntegersXXSmall1.map {String($0)}
  public static let randomStringsXXSmall2  = randomIntegersXXSmall2.map {String($0)}

  public static let randomStringsXSmall1   = randomIntegersXSmall1.map {String($0)}
  public static let randomStringsXSmall2   = randomIntegersXSmall2.map {String($0)}

  public static let randomStringsSmall1    = randomIntegersSmall1.map {String($0)}
  public static let randomStringsSmall2    = randomIntegersSmall2.map {String($0)}

  public static let randomStringsMedium1   = randomIntegersMedium1.map {String($0)}
  public static let randomStringsMedium2   = randomIntegersMedium2.map {String($0)}

  public static let randomStringsLarge1    = randomIntegersLarge1.map {String($0)}
  public static let randomStringsLarge2    = randomIntegersLarge2.map {String($0)}

  public static let randomStringsXLarge1   = randomIntegersXLarge1.map {String($0)}
  public static let randomStringsXLarge2   = randomIntegersXLarge2.map {String($0)}

  public static let randomStringsXXLarge1  = randomIntegersXXLarge1.map {String($0)}
  public static let randomStringsXXLarge2  = randomIntegersXXLarge2.map {String($0)}

}

// MARK: - Functions for measuring performance
public func randomIntegers(count: Int, _ range: Range<Int>) -> [Int] {
  func randomInt() -> Int { return Int(arc4random()) % range.count + range.startIndex }
  var result = Array<Int>(minimumCapacity: count)
  for _ in 0 ..< count { result.append(randomInt()) }
  return result
}

public func srandomIntegers(seed: UInt32, _ count: Int, _ range: Range<Int>) -> [Int] {
  srandom(seed)
  func randomInt() -> Int { return random() % range.count + range.startIndex }
  var result = Array<Int>(minimumCapacity: count)
  for _ in 0 ..< count { result.append(randomInt()) }
  return result
}

public func randomRange(count: Int, coverage: Double) -> Range<Int> {
  guard count > 0 else { return 0 ..< 0 }
  let length = Int(Double(count) * coverage)
  let end = Int(arc4random()) % count
  let start = max(0, end - length)
  return start ..< end
}

public func performWithIntegers<Target>(@noescape target target: ([Int]) -> Target, execute: (Target, [Int]) -> Void) -> () -> Void
{
  return perform(dataSet1: {MoonKitTest.randomIntegersLarge1}, dataSet2: {MoonKitTest.randomIntegersLarge2}, target: target, execute: execute)
}

public func perform<Target, Data>(
  @noescape dataSet1 dataSet1: () -> [Data],
  @noescape dataSet2: () -> [Data],
  @noescape target: ([Data]) -> Target,
  execute: (Target, [Data]) -> Void
  ) -> () -> Void
{
  let data1 = dataSet1()
  let data2 = dataSet2()
  let target = target(data1)
  return {
    autoreleasepool { execute(target, data2) }
  }
}

// MARK: - Extending Nimble
// MARK: -

// MARK: Tuple equality

public func equal<
  A:Equatable, B:Equatable
  >(expectedValue: (A, B)?) -> NonNilMatcherFunc<(A, B)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func equal<
  A:Equatable, B:Equatable, C:Equatable
  >(expectedValue: (A, B, C)?) -> NonNilMatcherFunc<(A, B, C)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func equal<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable
  >(expectedValue: (A, B, C, D)?) -> NonNilMatcherFunc<(A, B, C, D)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func equal<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable
  >(expectedValue: (A, B, C, D, E)?) -> NonNilMatcherFunc<(A, B, C, D, E)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func equal<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable, F:Equatable
  >(expectedValue: (A, B, C, D, E, F)?) -> NonNilMatcherFunc<(A, B, C, D, E, F)>
{
  return NonNilMatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(stringify(expectedValue))>"
    let actualValue = try actualExpression.evaluate()
    let matches = actualValue != nil && expectedValue != nil && actualValue! == expectedValue!
    if expectedValue == nil || actualValue == nil {
      if expectedValue == nil {
        failureMessage.postfixActual = " (use beNil() to match nils)"
      }
      return false
    }
    return matches
  }
}

public func ==<
  A:Equatable, B:Equatable
  >(lhs: Expectation<(A, B)>, rhs: (A, B)?)
{
  lhs.to(equal(rhs))
}

public func ==<
  A:Equatable, B:Equatable, C:Equatable
  >(lhs: Expectation<(A, B, C)>, rhs: (A, B, C)?)
{
  lhs.to(equal(rhs))
}

public func ==<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable
  >(lhs: Expectation<(A, B, C, D)>, rhs: (A, B, C, D)?)
{
  lhs.to(equal(rhs))
}

public func ==<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable
  >(lhs: Expectation<(A, B, C, D, E)>, rhs: (A, B, C, D, E)?)
{
  lhs.to(equal(rhs))
}

public func ==<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable, F:Equatable
  >(lhs: Expectation<(A, B, C, D, E, F)>, rhs: (A, B, C, D, E, F)?)
{
  lhs.to(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable
  >(lhs: Expectation<(A, B)>, rhs: (A, B)?)
{
  lhs.toNot(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable, C:Equatable
  >(lhs: Expectation<(A, B, C)>, rhs: (A, B, C)?)
{
  lhs.toNot(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable
  >(lhs: Expectation<(A, B, C, D)>, rhs: (A, B, C, D)?)
{
  lhs.toNot(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable
  >(lhs: Expectation<(A, B, C, D, E)>, rhs: (A, B, C, D, E)?)
{
  lhs.toNot(equal(rhs))
}

public func !=<
  A:Equatable, B:Equatable, C:Equatable, D:Equatable, E:Equatable, F:Equatable
  >(lhs: Expectation<(A, B, C, D, E, F)>, rhs: (A, B, C, D, E, F)?)
{
  lhs.toNot(equal(rhs))
}

// MARK: SetType matchers

public func equal<
  S1: SequenceType,
  S2: SequenceType
  where S1.Generator.Element == S2.Generator.Element, S1.Generator.Element:Equatable
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    failureMessage.postfixMessage = "equal \(sequence)"
    guard let actual = try expression.evaluate() else { return false }
    return actual.elementsEqual(sequence)
  }
}

public func ==<
  S1: SequenceType,
  S2: SequenceType
  where S1.Generator.Element == S2.Generator.Element, S1.Generator.Element:Equatable
  >(lhs: Expectation<S1>, rhs: S2)
{
  lhs.to(equal(rhs))
}

public func !=<
  S1: SequenceType,
  S2: SequenceType
  where S1.Generator.Element == S2.Generator.Element, S1.Generator.Element:Equatable
  >(lhs: Expectation<S1>, rhs: S2)
{
  lhs.toNot(equal(rhs))
}

public func equal<
  S1: SequenceType,
  S2: SequenceType
where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2, isEquivalent: (S1.Generator.Element, S2.Generator.Element) -> Bool) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    failureMessage.postfixMessage = "equal"
    guard let actual = try expression.evaluate() else { return false }
    return actual.elementsEqual(sequence, isEquivalent: isEquivalent)
  }
}

public func beSubsetOf<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be a subset of \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isSubsetOf(sequence)
  }
}

public func beStrictSubsetOf<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be a strict subset of \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isStrictSubsetOf(sequence)
  }
}

public func beSupersetOf<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be a superset of \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isSupersetOf(sequence)
  }
}

public func beStrictSupersetOf<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be a strict superset of \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isStrictSupersetOf(sequence)
  }
}

public func beDisjointWith<
  S1:SetType, S2: SequenceType where S1.Generator.Element == S2.Generator.Element, S1.Element == S2.Generator.Element
  >(sequence: S2) -> NonNilMatcherFunc<S1>
{
  return NonNilMatcherFunc {
    (expression: Expression<S1>, failureMessage: FailureMessage) -> Bool in
    guard let actual = try expression.evaluate() else { return false }
    failureMessage.expected = "expected \(actual)"
    failureMessage.to = "to be disjoint with \(sequence)"
    failureMessage.actualValue = nil
    failureMessage.postfixMessage = ""
    return actual.isDisjointWith(sequence)
  }
}
