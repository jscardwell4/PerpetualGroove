//
//  Fraction.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/21/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

infix operator ╱ { associativity left precedence 200 } // U+2571

public func ╱<F:FractionType>(lhs: F, rhs: F) -> Fraction<F> {
  return Fraction<F>(lhs, rhs)
}

public func ╱(lhs: UInt8, rhs: UInt8) -> Fraction<Int8> {
  return Fraction<Int8>(Int8(lhs), Int8(rhs))
}

public func ╱(lhs: UInt16, rhs: UInt16) -> Fraction<Int16> {
  return Fraction<Int16>(Int16(lhs), Int16(rhs))
}

public func ╱(lhs: UInt32, rhs: UInt32) -> Fraction<Int32> {
  return Fraction<Int32>(Int32(lhs), Int32(rhs))
}

public func ╱(lhs: UInt64, rhs: UInt64) -> Fraction<Int64> {
  return Fraction<Int64>(Int64(lhs), Int64(rhs))
}

public func ╱(lhs: UInt, rhs: UInt) -> Fraction<Int> {
  return Fraction<Int>(Int(lhs), Int(rhs))
}

public func ╱(lhs: Int, rhs: Int) -> Fraction<Int> {
  return Fraction<Int>(lhs, rhs)
}


/**
Converts two fractions into equivalent fractions with a common denominator

- parameter x: Fraction
- parameter y: Fraction

- returns: (Fraction, Fraction)
*/
private func commonize<F:FractionType>(x: Fraction<F>, _ y: Fraction<F>) -> (Fraction<F>, Fraction<F>) {
  switch (x.denominator, y.denominator) {
  case let (n, m) where n == m: return (x, y)
  case let (n, m) where n % m == F(intMax: 0): return (x, Fraction((n / m) * y.numerator, n))
  case let (n, m) where m % n == F(intMax: 0): return (Fraction((m / n) * x.numerator, m), y)
  case let (n, m):
    let commonBase = lcm(n, m)
    return (Fraction((commonBase / n) * x.numerator, commonBase),
            Fraction((commonBase / m) * y.numerator, commonBase))

  }
}

public typealias FractionType = protocol<Comparable, SignedNumberType, ArithmeticType, Hashable>

public struct Fraction<ValueType:FractionType>   {

  public var numerator: ValueType = ValueType(intMax: 0)
  public var denominator: ValueType = ValueType(intMax: 1)
  public var value: ValueType { return numerator / denominator }
  public var inverse: Fraction { return Fraction(denominator, numerator) }

  public var reduced: Fraction { var result = self; result.reduce(); return result }
  mutating public func reduce() {
    let divisor = gcd(numerator, denominator); numerator /= divisor; denominator /= divisor
  }

  public func fractionWithBase(base: ValueType) -> Fraction<ValueType> {
    guard base != denominator else { return self }
    return base < denominator ? (numerator / (denominator / base))╱base : (numerator * (base / denominator))╱base
  }

  public init(_ value: ValueType) {
    let pieces = ".".split(String(value))
    guard pieces.count == 2 else { numerator = value; return }
    denominator = ValueType(intMax: IntMax(pow(10.0, Double(pieces[1].characters.count))))
    numerator = ValueType(intMax: IntMax("".join(pieces))!)
    reduce()
  }
  public init(_ n: ValueType, _ d: ValueType) { numerator = n; denominator = d}
}

// MARK: - Hashable
extension Fraction: Hashable { public var hashValue: Int { return value.hashValue } }

// MARK: - SignedNumberType
//extension Fraction: SignedNumberType {}

public prefix func -<F:FractionType>(x: Fraction<F>) -> Fraction<F> { return Fraction(-x.numerator, x.denominator) }
public func -<F:FractionType>(lhs: Fraction<F>, rhs: Fraction<F>) -> Fraction<F> {
  let (l, r) = commonize(lhs, rhs)
  return Fraction(l.numerator - r.numerator, l.denominator).reduced
}
public func +<F:FractionType>(lhs: Fraction<F>, rhs: Fraction<F>) -> Fraction<F> {
  let (l, r) = commonize(lhs, rhs)
  return Fraction(l.numerator + r.numerator, l.denominator).reduced
}
public func *<F:FractionType>(lhs: Fraction<F>, rhs: Fraction<F>) -> Fraction<F> {
  return Fraction(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator).reduced
}
public func /<F:FractionType>(lhs: Fraction<F>, rhs: Fraction<F>) -> Fraction<F> { return (lhs * rhs.inverse).reduced }

public func %<F:FractionType>(lhs: Fraction<F>, rhs: Fraction<F>) -> Fraction<F> {
  let (l, r) = commonize(lhs, rhs)
  return Fraction(l.numerator % r.numerator, l.denominator).reduced
}

public func -=<F:FractionType>(inout lhs: Fraction<F>, rhs: Fraction<F>) { lhs = lhs - rhs }
public func +=<F:FractionType>(inout lhs: Fraction<F>, rhs: Fraction<F>) { lhs = lhs + rhs }
public func *=<F:FractionType>(inout lhs: Fraction<F>, rhs: Fraction<F>) { lhs = lhs * rhs }
public func /=<F:FractionType>(inout lhs: Fraction<F>, rhs: Fraction<F>) { lhs = lhs / rhs }
public func %=<F:FractionType>(inout lhs: Fraction<F>, rhs: Fraction<F>) { lhs = lhs % rhs }

public func *<F:FractionType>(lhs: Fraction<F>, rhs: F) -> F { return lhs.value * rhs }
public func *<F:FractionType>(lhs: F, rhs: Fraction<F>) -> F { return lhs * rhs.value }

//extension Fraction: ArithmeticType {
//  public func toIntMax() -> IntMax { return value.toIntMax() }
//  public init(intMax: IntMax) { self.init(intMax) }
//}

// MARK: - CustomStringConvertible
extension Fraction: CustomStringConvertible {

  public var description: String { return "\(numerator)/\(denominator)" }

}

// MARK: - IntegerLiteralConvertible
//extension Fraction: IntegerLiteralConvertible {
//  public init(integerLiteral: IntMax) { numerator = ValueType(intMax: integerLiteral) }
//}

// MARK: - FloatLiteralConvertible
//extension Fraction: FloatLiteralConvertible {
//  public init(floatLiteral value: Double) { numerator = value; denominator = Double(1) }
//}

extension Fraction { //: Strideable, _Strideable {
  public func distanceTo(other: Fraction) -> Fraction { return self - other }
  public func advancedBy(n: Fraction) -> Fraction { return self + n }
}

// MARK: - Comparable, Equatable
extension Fraction: Comparable, Equatable {}
public func <<F:FractionType>(lhs: Fraction<F>, rhs: Fraction<F>) -> Bool { return lhs.value < rhs.value }
public func ==<F:FractionType>(var lhs: Fraction<F>, var rhs: Fraction<F>) -> Bool {
  lhs.reduce(); rhs.reduce()
  return lhs.numerator == rhs.numerator && lhs.denominator == rhs.denominator
}

public func ==<F:FractionType>(lhs: Fraction<F>, rhs: F) -> Bool { return lhs.value == rhs }
public func ==<F:FractionType>(lhs: F, rhs: Fraction<F>) -> Bool { return rhs.value == lhs }
public func ==<F:FractionType, I:SignedIntegerType>(lhs: Fraction<F>, rhs: I) -> Bool {
  guard lhs.value % 1 == 0 else { return false }
  return lhs.value.toIntMax() == rhs.toIntMax()
}

public func ==<F:FractionType, I:SignedIntegerType>(lhs: I, rhs: Fraction<F>) -> Bool {
  guard rhs.value % 1 == 0 else { return false }
  return rhs.value.toIntMax() == lhs.toIntMax()
}

// MARK: - AbsoluteValuable
extension Fraction { //: AbsoluteValuable {
  public static func abs(x: Fraction) -> Fraction {
    return Fraction(Swift.abs(x.numerator), Swift.abs(x.denominator))
  }
}

extension Fraction: CustomPlaygroundQuickLookable {
  public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
    return .Text("\(numerator)╱\(denominator)")
  }
}

// MARK: - FloatingPointType
extension Fraction {//: FloatingPointType {
//  public typealias _BitsType = T._BitsType
//  public init(_ value: UInt8)   { numerator = value; denominator = UInt8(1)   }
//  public init(_ value: Int8)    { numerator = value; denominator = Int8(1)    }
//  public init(_ value: UInt16)  { numerator = value; denominator = UInt16(1)  }
//  public init(_ value: Int16)   { numerator = value; denominator = Int16(1)   }
//  public init(_ value: UInt32)  { numerator = value; denominator = UInt32(1)  }
//  public init(_ value: Int32)   { numerator = value; denominator = Int32(1)   }
//  public init(_ value: UInt64)  { numerator = value; denominator = UInt64(1)  }
//  public init(_ value: Int64)   { numerator = value; denominator = Int64(1)   }
//  public init(_ value: UInt)    { numerator = value; denominator = UInt(1)    }
//  public init(_ value: Int)     { numerator = value; denominator = Int(1)     }
//  public init(_ value: Float)   { numerator = value; denominator = Float(1)   }
//  public init(_ value: Double)  { numerator = value; denominator = Double(1)  }
//  public init(_ value: CGFloat) { numerator = value; denominator = CGFloat(1) }
//
  public static var infinity: Fraction { return Fraction(1, 0) }
  public static var NaN: Fraction { return Fraction(0, 0) }
  public static var quietNaN: Fraction { return Fraction(0, 0) }

//  public static func _fromBitPattern(bits: _BitsType) -> Fraction<T> {
//    return Fraction(T._fromBitPattern(bits))
//  }

//  public func _toBitPattern() -> _BitsType { return value._toBitPattern() }

//  public var floatingPointClass: FloatingPointClassification { return value.floatingPointClass }
//  public var isSignMinus: Bool { return value.isSignMinus }
//  public var isNormal: Bool { return value.isNormal }
//  public var isFinite: Bool { return value.isFinite }
//  public var isZero: Bool { return numerator == 0 }
//  public var isSubnormal: Bool { return value.isSubnormal }
//  public var isInfinite: Bool { return value.isInfinite }
//  public var isNaN: Bool { return value.isNaN }
//  public var isSignaling: Bool { return value.isSignaling }
}