//
//  Tests.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation
import Nimble

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
