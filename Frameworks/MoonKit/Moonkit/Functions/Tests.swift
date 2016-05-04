//
//  Tests.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation
import Nimble
import MoonKit

// MARK: - Functions for measuring performance
public func randomIntegers(count: Int, _ range: Range<Int>) -> [Int] {
  func randomInt() -> Int { return Int(arc4random()) % range.count + range.startIndex }
  var result = Array<Int>(minimumCapacity: count)
  for _ in 0 ..< count { result.append(randomInt()) }
  return result
}

public func randomRange(count: Int, coverage: Double) -> Range<Int> {
  let length = Int(Double(count) * coverage)
  let end = Int(arc4random()) % count
  let start = max(0, end - length)
  return start ..< end
}

public let randomIntegersLarge1 = randomIntegers(10000, 0 ..< 2000)
public let randomIntegersLarge2 = randomIntegers(10000, 0 ..< 2000)

public let randomIntegersMedium1 = randomIntegers(50000, 0 ..< 10000)
public let randomIntegersMedium2 = randomIntegers(50000, 0 ..< 10000)

public let randomIntegersSmall1 = randomIntegers(500, 0 ..< 250)
public let randomIntegersSmall2 = randomIntegers(500, 0 ..< 250)


public func performWithIntegers<Target>(@noescape target target: ([Int]) -> Target, execute: (Target, [Int]) -> Void) -> () -> Void
{
  return perform(dataSet1: {randomIntegersLarge1}, dataSet2: {randomIntegersLarge2}, target: target, execute: execute)
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
