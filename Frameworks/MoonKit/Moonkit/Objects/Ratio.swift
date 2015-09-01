//
//  Ratio.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/22/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

infix operator ∶ { associativity left precedence 200 } // U+2236

public func ∶<F:FractionType>(lhs: F, rhs: F) -> Ratio<F> { return Ratio<F>(lhs ╱ rhs) }

public struct Ratio<T:FractionType> {

  private var fraction = T(intMax: 1)╱T(intMax: 1)
  public var numerator: T { get { return fraction.numerator } set { fraction.numerator = newValue } }
  public var denominator: T { get { return fraction.denominator } set { fraction.denominator = newValue } }

  public init(_ f: Fraction<T>) { fraction = f }
  public init (_ v: T) { fraction = Fraction(v) }

  public var value: T { return fraction.value }
  public var inverseValue: T { return fraction.inverse.value }

  public func denominatorForNumerator(n: T) -> T { return n * inverseValue }
  public func numeratorForDenominator(d: T) -> T { return d * value }
}

// MARK: - CustomStringConvertible
extension Ratio: CustomStringConvertible {
  public var description: String { return "\(numerator):\(denominator)" }
}

// MARK: - SignedNumberType
//extension Ratio: SignedNumberType {}

public prefix func -<T:FractionType>(x: Ratio<T>) -> Ratio<T> { return Ratio(-x.fraction) }
public func -<T:FractionType>(lhs: Ratio<T>, rhs: Ratio<T>) -> Ratio<T> { return Ratio(lhs.fraction - rhs.fraction) }
public func +<T:FractionType>(lhs: Ratio<T>, rhs: Ratio<T>) -> Ratio<T> { return Ratio(lhs.fraction + rhs.fraction) }
public func *<T:FractionType>(lhs: Ratio<T>, rhs: Ratio<T>) -> Ratio<T> { return Ratio(lhs.fraction * rhs.fraction) }
public func /<T:FractionType>(lhs: Ratio<T>, rhs: Ratio<T>) -> Ratio<T> { return Ratio(lhs.fraction / rhs.fraction) }
public func %<T:FractionType>(lhs: Ratio<T>, rhs: Ratio<T>) -> Ratio<T> { return Ratio(lhs.fraction % rhs.fraction) }

public func *<T:FractionType>(lhs: Ratio<T>, rhs: T) -> T { return lhs.fraction * rhs }
public func *<T:FractionType>(lhs: T, rhs: Ratio<T>) -> T { return lhs * rhs.fraction }

public func -=<T:FractionType>(inout lhs: Ratio<T>, rhs: Ratio<T>) { lhs = lhs - rhs }
public func +=<T:FractionType>(inout lhs: Ratio<T>, rhs: Ratio<T>) { lhs = lhs + rhs }
public func *=<T:FractionType>(inout lhs: Ratio<T>, rhs: Ratio<T>) { lhs = lhs * rhs }
public func /=<T:FractionType>(inout lhs: Ratio<T>, rhs: Ratio<T>) { lhs = lhs / rhs }
public func %=<T:FractionType>(inout lhs: Ratio<T>, rhs: Ratio<T>) { lhs = lhs % rhs }

//extension Ratio: ArithmeticType {
//  public func toIntMax() -> IntMax { return value.toIntMax() }
//  public init(intMax: IntMax) { self.init(intMax) }
//}

// MARK: - IntegerLiteralConvertible
//extension Ratio: IntegerLiteralConvertible {
//  public init(integerLiteral: IntMax) { self.init(integerLiteral) }
//}

// MARK: - FloatLiteralConvertible
//extension Ratio: FloatLiteralConvertible {
//  public init(floatLiteral value: T.FloatLiteralType) { self.init(Fraction<T>(floatLiteral: value)) }
//}

//extension Ratio: Strideable, _Strideable {
//  public func distanceTo(other: Ratio<T>) -> Ratio<T> { return self - other }
//  public func advancedBy(n: Ratio<T>) -> Ratio<T> { return self + n }
//}

// MARK: - Comparable, Equatable
extension Ratio: Comparable, Equatable {}
public func <<T:FractionType>(lhs: Ratio<T>, rhs: Ratio<T>) -> Bool { return lhs.fraction < rhs.fraction }
public func ==<T:FractionType>(lhs: Ratio<T>, rhs: Ratio<T>) -> Bool { return lhs.fraction == rhs.fraction }

// MARK: - Hashable
extension Ratio: Hashable {
  public var hashValue: Int { return fraction.hashValue }
}

//extension Ratio: AbsoluteValuable {
//  public static func abs(x: Ratio) -> Ratio { return Ratio(Fraction.abs(x.fraction)) }
//}

// MARK: - FloatingPointType
extension Ratio {//: FloatingPointType {
//  public typealias _BitsType = T._BitsType
//  public init(_ value: UInt8)  { self.init(Fraction(IntMax(value))) }
//  public init(_ value: Int8)   { self.init(Fraction(IntMax(value))) }
//  public init(_ value: UInt16) { self.init(Fraction(IntMax(value))) }
//  public init(_ value: Int16)  { self.init(Fraction(IntMax(value))) }
//  public init(_ value: UInt32) { self.init(Fraction(IntMax(value))) }
//  public init(_ value: Int32)  { self.init(Fraction(IntMax(value))) }
//  public init(_ value: UInt64) { self.init(Fraction(IntMax(value))) }
//  public init(_ value: Int64)  { self.init(Fraction(IntMax(value))) }
//  public init(_ value: UInt)   { self.init(Fraction(IntMax(value))) }
//  public init(_ value: Int)    { self.init(Fraction(IntMax(value))) }

  public static var infinity: Ratio { return Ratio(Fraction<T>.infinity) }
  public static var NaN: Ratio { return Ratio(Fraction<T>.NaN) }
  public static var quietNaN: Ratio { return Ratio(Fraction<T>.quietNaN) }

//  public static func _fromBitPattern(bits: _BitsType) -> Ratio { return Ratio(Fraction<T>._fromBitPattern(bits)) }

//  public func _toBitPattern() -> _BitsType { return fraction._toBitPattern() }

//  public var floatingPointClass: FloatingPointClassification { return fraction.floatingPointClass }
//  public var isSignMinus: Bool { return fraction.isSignMinus }
//  public var isNormal: Bool { return fraction.isNormal }
//  public var isFinite: Bool { return fraction.isFinite }
//  public var isZero: Bool { return numerator == 0 }
//  public var isSubnormal: Bool { return fraction.isSubnormal }
//  public var isInfinite: Bool { return fraction.isInfinite }
//  public var isNaN: Bool { return fraction.isNaN }
//  public var isSignaling: Bool { return fraction.isSignaling }
}