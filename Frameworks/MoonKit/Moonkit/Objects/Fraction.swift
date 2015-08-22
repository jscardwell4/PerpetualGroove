//
//  Fraction.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/21/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/**
Converts two fractions into equivalent fractions with a common denominator

- parameter x: Fraction
- parameter y: Fraction

- returns: (Fraction, Fraction)
*/
private func commonize<T:FractionType>(x: Fraction<T>, _ y: Fraction<T>) -> (Fraction<T>, Fraction<T>) {
  switch (x.denominator, y.denominator) {
  case let (n, m) where n == m: return (x, y)
  case let (n, m) where n % m == 0: return (x, Fraction((n / m) * y.numerator, n))
  case let (n, m) where m % n == 0: return (Fraction((m / n) * x.numerator, m), y)
  case let (n, m):
    let commonBase = lcm(n, m)
    return (Fraction((commonBase / n) * x.numerator, commonBase),
            Fraction((commonBase / m) * y.numerator, commonBase))

  }
}

public typealias FractionType = protocol<FloatingPointType, Divisible, Multiplicable, IntConvertible, DoubleConvertible, FloatLiteralConvertible, Hashable, SignedNumberType, AbsoluteValuable>

public struct Fraction<T:FractionType>   {

  public var numerator = 0
  public var denominator = 1
  public var value: T { return T(numerator) / T(denominator) }
  public var inverse: Fraction { return Fraction(denominator, numerator) }

  public var reduced: Fraction { var result = self; result.reduce(); return result }
  mutating public func reduce() { let divisor = gcd(numerator, denominator); numerator /= divisor; denominator /= divisor }

  public init(_ value: T) {
    let pieces = ".".split(String(value))
    guard pieces.count == 2 else { numerator = value.IntValue; return }
    denominator = Int(pow(10.0, Double(pieces[1].characters.count)))
    numerator = Int("".join(pieces))!
    reduce()
  }
  public init(_ n: Int = 0, _ d: Int = 1) { numerator = n; denominator = d}
}

// MARK: - SignedNumberType
extension Fraction: SignedNumberType {}

public prefix func -<T:FractionType>(x: Fraction<T>) -> Fraction<T> { return Fraction(-x.numerator, x.denominator) }
public func -<T:FractionType>(lhs: Fraction<T>, rhs: Fraction<T>) -> Fraction<T> {
  let (l, r) = commonize(lhs, rhs)
  return Fraction(l.numerator - r.numerator, l.denominator).reduced
}
public func +<T:FractionType>(lhs: Fraction<T>, rhs: Fraction<T>) -> Fraction<T> {
  let (l, r) = commonize(lhs, rhs)
  return Fraction(l.numerator + r.numerator, l.denominator).reduced
}
public func *<T:FractionType>(lhs: Fraction<T>, rhs: Fraction<T>) -> Fraction<T> {
  return Fraction(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator).reduced
}
public func /<T:FractionType>(lhs: Fraction<T>, rhs: Fraction<T>) -> Fraction<T> { return (lhs * rhs.inverse).reduced }

// MARK: - CustomStringConvertible
extension Fraction: CustomStringConvertible {

  public var description: String { return "\(numerator)/\(denominator)" }

}

// MARK: - IntegerLiteralConvertible
extension Fraction: IntegerLiteralConvertible {
  public init(integerLiteral: Int) { numerator = integerLiteral }
}

// MARK: - FloatLiteralConvertible
extension Fraction: FloatLiteralConvertible {
  public init(floatLiteral value: T.FloatLiteralType) { self.init(T(floatLiteral: value)) }
}

extension Fraction: Strideable, _Strideable {
  public func distanceTo(other: Fraction) -> Fraction { return self - other }
  public func advancedBy(n: Fraction) -> Fraction { return self + n }
}

// MARK: - Comparable, Equatable
extension Fraction: Comparable, Equatable {}
public func <<T:FractionType>(lhs: Fraction<T>, rhs: Fraction<T>) -> Bool { return lhs.value < rhs.value }
public func ==<T:FractionType>(var lhs: Fraction<T>, var rhs: Fraction<T>) -> Bool {
  lhs.reduce(); rhs.reduce()
  return lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator
}

// MARK: - Hashable
extension Fraction: Hashable {
  public var hashValue: Int { return value.hashValue }
}

// MARK: - AbsoluteValuable
extension Fraction: AbsoluteValuable {
  public static func abs(x: Fraction) -> Fraction {
    return Fraction(Swift.abs(x.numerator), Swift.abs(x.denominator))
  }
}

// MARK: - FloatingPointType
extension Fraction: FloatingPointType {
  public typealias _BitsType = T._BitsType
  public init(_ value: UInt8) { numerator = Int(value) }
  public init(_ value: Int8) { numerator = Int(value) }
  public init(_ value: UInt16) { numerator = Int(value) }
  public init(_ value: Int16) { numerator = Int(value) }
  public init(_ value: UInt32) { numerator = Int(value) }
  public init(_ value: Int32) { numerator = Int(value) }
  public init(_ value: UInt64) { numerator = Int(value) }
  public init(_ value: Int64) { numerator = Int(value) }
  public init(_ value: UInt) { numerator = Int(value) }
  public init(_ value: Int) { numerator = value }

  public static var infinity: Fraction { return Fraction(1, 0) }
  public static var NaN: Fraction { return Fraction(0, 0) }
  public static var quietNaN: Fraction { return Fraction(0, 0) }

  public static func _fromBitPattern(bits: _BitsType) -> Fraction<T> {
    return Fraction(T._fromBitPattern(bits))
  }

  public func _toBitPattern() -> _BitsType { return value._toBitPattern() }

  public var floatingPointClass: FloatingPointClassification { return value.floatingPointClass }
  public var isSignMinus: Bool { return value.isSignMinus }
  public var isNormal: Bool { return value.isNormal }
  public var isFinite: Bool { return value.isFinite }
  public var isZero: Bool { return numerator == 0 }
  public var isSubnormal: Bool { return value.isSubnormal }
  public var isInfinite: Bool { return value.isInfinite }
  public var isNaN: Bool { return value.isNaN }
  public var isSignaling: Bool { return value.isSignaling }
}