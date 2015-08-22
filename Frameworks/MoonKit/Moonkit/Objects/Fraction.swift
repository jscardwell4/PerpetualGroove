//
//  Fraction.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/21/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

private func commonize(x: Fraction, _ y: Fraction) -> (Fraction, Fraction) {
  switch (x.denominator, y.denominator) {
  case let (n, m) where n == m: return (x, y)
  case let (n, m) where n % m == 0: return (x, Fraction(numerator: (n / m) * y.numerator, denominator: n))
  case let (n, m) where m % n == 0: return (Fraction(numerator: (m / n) * x.numerator, denominator: m), y)
  case let (n, m):
    let commonBase = lcm(n, m)
    return (Fraction(numerator: (commonBase / n) * x.numerator, denominator: commonBase),
            Fraction(numerator: (commonBase / m) * y.numerator, denominator: commonBase))

  }
}

public struct Fraction   {

  public var numerator = 0
  public var denominator = 1
  public var doubleValue: Double { return Double(numerator) / Double(denominator) }
  public init(_ double: Double) {
    let pieces = ".".split(String(double))
    guard pieces.count == 2 else { numerator = Int(double); return }
    denominator = Int(pow(10.0, Double(pieces[1].characters.count)))
    numerator = Int("".join(pieces))!

  }
  public init(numerator n: Int = 0, denominator d: Int = 1) { numerator = n; denominator = d}
}

extension Fraction: SignedNumberType {}

public prefix func -(x: Fraction) -> Fraction { return Fraction(numerator: -x.numerator, denominator: x.denominator) }
public func -(lhs: Fraction, rhs: Fraction) -> Fraction {
  let (l, r) = commonize(lhs, rhs)
  return Fraction(numerator: l.numerator - r.numerator, denominator: l.denominator)
}
public func +(lhs: Fraction, rhs: Fraction) -> Fraction {
  let (l, r) = commonize(lhs, rhs)
  return Fraction(numerator: l.numerator + r.numerator, denominator: l.denominator)
}

extension Fraction: CustomStringConvertible {

  public var description: String { return "\(numerator)/\(denominator)" }

}

extension Fraction: IntegerLiteralConvertible {
  public init(integerLiteral: Int) { numerator = integerLiteral }
}

extension Fraction: FloatLiteralConvertible {
  public init(floatLiteral value: Double) { self.init(value) }
}

extension Fraction: Strideable, _Strideable {
  public func distanceTo(other: Fraction) -> Fraction { return self - other }
  public func advancedBy(n: Fraction) -> Fraction { return self + n }
}

extension Fraction: Comparable, Equatable {}
public func <(lhs: Fraction, rhs: Fraction) -> Bool { return lhs.doubleValue < rhs.doubleValue }
public func ==(lhs: Fraction, rhs: Fraction) -> Bool {
  return (lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator) || lhs.doubleValue == rhs.doubleValue
}

extension Fraction: Hashable {
  public var hashValue: Int { return doubleValue.hashValue }
}

extension Fraction: CVarArgType, _CVarArgAlignedType, _CVarArgPassedAsDouble {
  public var _cVarArgAlignment: Int { return doubleValue._cVarArgAlignment }
  public var _cVarArgEncoding: [Int] { return doubleValue._cVarArgEncoding }
}

extension Fraction: AbsoluteValuable {
  public static func abs(x: Fraction) -> Fraction {
    return Fraction(numerator: Swift.abs(x.numerator), denominator: Swift.abs(x.denominator))
  }
}

extension Fraction: FloatingPointType {
  public typealias _BitsType = UInt64
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

  public static var infinity: Fraction { return Fraction(numerator: 1, denominator: 0) }
  public static var NaN: Fraction { return Fraction(numerator: 0, denominator: 0) }
  public static var quietNaN: Fraction { return Fraction(numerator: 0, denominator: 0) }

  public static func _fromBitPattern(bits: UInt64) -> Fraction { return Fraction(Double._fromBitPattern(bits)) }

  public func _toBitPattern() -> UInt64 { return doubleValue._toBitPattern() }

  public var floatingPointClass: FloatingPointClassification { return doubleValue.floatingPointClass }
  public var isSignMinus: Bool { return doubleValue.isSignMinus }
  public var isNormal: Bool { return doubleValue.isNormal }
  public var isFinite: Bool { return doubleValue.isFinite }
  public var isZero: Bool { return numerator == 0 }
  public var isSubnormal: Bool { return doubleValue.isSubnormal }
  public var isInfinite: Bool { return doubleValue.isInfinite }
  public var isNaN: Bool { return doubleValue.isNaN }
  public var isSignaling: Bool { return doubleValue.isSignaling }
}