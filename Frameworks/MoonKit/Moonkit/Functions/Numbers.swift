//
//  Numbers.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/14/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public extension SignedIntegerType {
  public var isNegative: Bool { return self < 0 }
}

public protocol NumberType {}

public let π = CGFloat(M_PI)

public func pow<I:IntegerType>(lhs: I, _ rhs: I) -> I {
  var i = rhs
  var result = lhs
  while i > 1 {
    result *= lhs
    i = i - 1
  }
  return result
}

public func **<T:IntegerType>(lhs: T, rhs: T) -> T { return pow(lhs, rhs) }
//public func copysign<

//public extension SignedNumberType {
//  public var isSignMinus: Bool {
//    return
//  }
//}

public protocol IntegerConvertible {
  init(_ value: UInt8)
  init(_ value: Int8)
  init(_ value: UInt16)
  init(_ value: Int16)
  init(_ value: UInt32)
  init(_ value: Int32)
  init(_ value: UInt64)
  init(_ value: Int64)
  init(_ value: UInt)
  init(_ value: Int)
  init(_ value: _IntegerProducibleType)
}

public extension IntegerConvertible {
  init(_ value: _IntegerProducibleType) {
    switch value {
      case let v as UInt8: self.init(v)
      case let v as UInt16: self.init(v)
      case let v as UInt32: self.init(v)
      case let v as UInt64: self.init(v)
      case let v as Int8: self.init(v)
      case let v as Int16: self.init(v)
      case let v as Int32: self.init(v)
      case let v as Int64: self.init(v)
      default: logWarning("unknown '_IntegerProdocibleType"); self.init(0)
    }
  }
}

public protocol IntegerProducible {
  func toUInt8() -> UInt8
  func toInt8() -> Int8
  func toUInt16() -> UInt16
  func toInt16() -> Int16
  func toUInt32() -> UInt32
  func toInt32() -> Int32
  func toUInt64() -> UInt64
  func toInt64() -> Int64
  func toUInt() -> UInt
  func toInt() -> Int
}

public protocol _IntegerProducibleType: FloatConvertible {}
extension UInt8: _IntegerProducibleType {}
extension Int8: _IntegerProducibleType {}
extension UInt16: _IntegerProducibleType {}
extension Int16: _IntegerProducibleType {}
extension UInt32: _IntegerProducibleType {}
extension Int32: _IntegerProducibleType {}
extension UInt64: _IntegerProducibleType {}
extension Int64: _IntegerProducibleType {}
extension UInt: _IntegerProducibleType {}
extension Int: _IntegerProducibleType {}

extension UInt8: IntegerConvertible {}
extension Int8: IntegerConvertible {}
extension UInt16: IntegerConvertible {}
extension Int16: IntegerConvertible {}
extension UInt32: IntegerConvertible {}
extension Int32: IntegerConvertible {}
extension UInt64: IntegerConvertible {}
extension Int64: IntegerConvertible {}
extension UInt: IntegerConvertible {}
extension Int: IntegerConvertible {}
extension Float: IntegerConvertible {}
extension Double: IntegerConvertible {}
extension CGFloat: IntegerConvertible {}

extension IntegerProducible where Self:_IntegerProducibleType {
  public func toUInt8() -> UInt8 { return UInt8(self) }
  public func toInt8() -> Int8 { return Int8(self) }
  public func toUInt16() -> UInt16 { return UInt16(self) }
  public func toInt16() -> Int16 { return Int16(self) }
  public func toUInt32() -> UInt32 { return UInt32(self) }
  public func toInt32() -> Int32 { return Int32(self) }
  public func toUInt64() -> UInt64 { return UInt64(self) }
  public func toInt64() -> Int64 { return Int64(self) }
  public func toUInt() -> UInt { return UInt(self) }
  public func toInt() -> Int { return Int(self) }

}

extension UInt8: IntegerProducible {}
extension Int8: IntegerProducible {}
extension UInt16: IntegerProducible {}
extension Int16: IntegerProducible {}
extension UInt32: IntegerProducible {}
extension Int32: IntegerProducible {}
extension UInt64: IntegerProducible {}
extension Int64: IntegerProducible {}
extension UInt: IntegerProducible {}
extension Int: IntegerProducible {}
extension Float: IntegerProducible {}
extension Double: IntegerProducible {}
extension CGFloat: IntegerProducible {}

public protocol FloatConvertible {
  init(_ value: Float)
  init(_ value: Double)
  init(_ value: CGFloat)
  init(_ value: _FloatProducibleType)
}
public protocol _FloatProducibleType { init() }
public protocol FloatProducible {
  func toFloat() -> Float
  func toDouble() -> Double
  func toCGFloat() -> CGFloat
}
extension Float: _FloatProducibleType {}
extension Double: _FloatProducibleType {}
extension CGFloat: _FloatProducibleType {}

public extension FloatConvertible { //where Self:_FloatProducibleType {
  public init(_ value: _FloatProducibleType) {
    switch value {
      case let v as Float: self.init(v)
      case let v as Double: self.init(v)
      case let v as CGFloat: self.init(v)
      default:
        logWarning("unknown '_FloatProducibleType")
        self.init(0.0)
    }
  }
}

extension Float: FloatConvertible {}
extension Double: FloatConvertible {}
extension CGFloat: FloatConvertible {
  public init(_ value: CGFloat) { self = value }
}

extension UInt8: FloatConvertible {}
extension Int8: FloatConvertible {}
extension UInt16: FloatConvertible {}
extension Int16: FloatConvertible {}
extension UInt32: FloatConvertible {}
extension Int32: FloatConvertible {}
extension UInt64: FloatConvertible {}
extension Int64: FloatConvertible {}

public extension IntegerProducible where Self:_FloatProducibleType {
  public func toUInt8() -> UInt8 { return UInt8(self) }
  public func toInt8() -> Int8 { return Int8(self) }
  public func toUInt16() -> UInt16 { return UInt16(self) }
  public func toInt16() -> Int16 { return Int16(self) }
  public func toUInt32() -> UInt32 { return UInt32(self) }
  public func toInt32() -> Int32 { return Int32(self) }
  public func toUInt64() -> UInt64 { return UInt64(self) }
  public func toInt64() -> Int64 { return Int64(self) }
  public func toUInt() -> UInt { return UInt(self) }
  public func toInt() -> Int { return Int(self) }
}

extension Float: ArithmeticType {
  public func toIntMax() -> IntMax { return IntMax(self) }
  public init(intMax: IntMax) { self = Float(intMax) }
}
extension Double: ArithmeticType {
  public func toIntMax() -> IntMax { return IntMax(self) }
  public init(intMax: IntMax) { self = Double(intMax) }
}
extension CGFloat: ArithmeticType {
  public func toIntMax() -> IntMax { return IntMax(self) }
  public init(intMax: IntMax) { self = CGFloat(intMax) }
}
extension Int: ArithmeticType {
  public init(intMax: IntMax) { self = Int(intMax) }
}
extension UInt: ArithmeticType {
  public init(intMax: IntMax) { self = UInt(intMax) }
}
extension Int8: ArithmeticType {
  public init(intMax: IntMax) { self = Int8(intMax) }
}
extension UInt8: ArithmeticType {
  public init(intMax: IntMax) { self = UInt8(intMax) }
}
extension Int16: ArithmeticType {
  public init(intMax: IntMax) { self = Int16(intMax) }
}
extension UInt16: ArithmeticType {
  public init(intMax: IntMax) { self = UInt16(intMax) }
}
extension Int32: ArithmeticType {
  public init(intMax: IntMax) { self = Int32(intMax) }
}
extension UInt32: ArithmeticType {
  public init(intMax: IntMax) { self = UInt32(intMax) }
}
extension Int64: ArithmeticType {
  public init(intMax: IntMax) { self = Int64(intMax) }
}
extension UInt64: ArithmeticType {
  public init(intMax: IntMax) { self = UInt64(intMax) }
}

public protocol IntConvertible {
  var IntValue: Int { get }
  init(integerLiteral: Int)
}

extension Float: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension CGFloat: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension Double: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension Int: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension UInt: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension Int8: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension UInt8: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension Int16: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension UInt16: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension Int32: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension UInt32: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension Int64: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}
extension UInt64: IntConvertible {
  public var IntValue: Int { return Int(self) }
  public init(integerLiteral: Int) { self.init(integerLiteral) }
}

public protocol DoubleConvertible {
  var DoubleValue: Double { get }
  init(doubleLiteral: Double)
}

extension Float: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension CGFloat: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension Double: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension Int: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension UInt: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension Int8: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension UInt8: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension Int16: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension UInt16: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension Int32: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension UInt32: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension Int64: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}
extension UInt64: DoubleConvertible {
  public var DoubleValue: Double { return Double(self) }
  public init(doubleLiteral: Double) { self.init(doubleLiteral) }
}

public func numericCast<T:_FloatProducibleType, U:FloatConvertible>(x: T) -> U {
  return U(x)
}
//public func numericCast<T:FloatProducible>(x: T) -> Float { return x.toFloat() }
//public func numericCast<T:FloatProducible>(x: T) -> CGFloat { return x.toCGFloat() }

//public func +(lhs: CGFloat, rhs: CGFloatable) -> CGFloat { return lhs + rhs.CGFloatValue }
//public func -(lhs: CGFloat, rhs: CGFloatable) -> CGFloat { return lhs - rhs.CGFloatValue }
//
//public func +=(inout lhs: CGFloat, rhs: CGFloatable) {lhs += rhs }
//public func -=(inout lhs: CGFloat, rhs: CGFloatable) {lhs -= rhs }
//
//public func *(lhs: CGFloat, rhs: CGFloatable) -> CGFloat { return lhs * rhs.CGFloatValue }
//public func /(lhs: CGFloat, rhs: CGFloatable) -> CGFloat { return lhs / rhs.CGFloatValue }
//
//public func *=(inout lhs: CGFloat, rhs: CGFloatable) {lhs *= rhs }
//public func /=(inout lhs: CGFloat, rhs: CGFloatable) {lhs /= rhs }
//
//public func +(lhs: CGFloatable, rhs: CGFloat) -> CGFloat { return lhs.CGFloatValue + rhs }
//public func -(lhs: CGFloatable, rhs: CGFloat) -> CGFloat { return lhs.CGFloatValue - rhs }
//
//public func +=(inout lhs: CGFloatable, rhs: CGFloat) {lhs += rhs }
//public func -=(inout lhs: CGFloatable, rhs: CGFloat) {lhs -= rhs }
//
//public func *(lhs: CGFloatable, rhs: CGFloat) -> CGFloat { return lhs.CGFloatValue * rhs }
//public func /(lhs: CGFloatable, rhs: CGFloat) -> CGFloat { return lhs.CGFloatValue / rhs }
//
//public func *=(inout lhs: CGFloatable, rhs: CGFloat) {lhs *= rhs }
//public func /=(inout lhs: CGFloatable, rhs: CGFloat) {lhs /= rhs }

public func half(x: CGFloat) -> CGFloat { return x * 0.5                 }
public func half(x: Float)   -> Float   { return x * 0.5                 }
public func half(x: Double)  -> Double  { return x * 0.5                 }
public func half(x: Int)     -> Int     { return    Int(Double(x) * 0.5) }
public func half(x: Int8)    -> Int8    { return   Int8(Double(x) * 0.5) }
public func half(x: Int16)   -> Int16   { return  Int16(Double(x) * 0.5) }
public func half(x: Int32)   -> Int32   { return  Int32(Double(x) * 0.5) }
public func half(x: Int64)   -> Int64   { return  Int64(Double(x) * 0.5) }
public func half(x: UInt)    -> UInt    { return   UInt(Double(x) * 0.5) }
public func half(x: UInt8)   -> UInt8   { return  UInt8(Double(x) * 0.5) }
public func half(x: UInt16)  -> UInt16  { return UInt16(Double(x) * 0.5) }
public func half(x: UInt32)  -> UInt32  { return UInt32(Double(x) * 0.5) }
public func half(x: UInt64)  -> UInt64  { return UInt64(Double(x) * 0.5) }

public protocol CGFloatable {
  var CGFloatValue: CGFloat { get }
}

extension CGFloat: CGFloatable { public var CGFloatValue: CGFloat { return self          } }
extension Float:   CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension Double:  CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension Int:     CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension Int8:    CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension Int16:   CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension Int32:   CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension Int64:   CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension UInt:    CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension UInt8:   CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension UInt16:  CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension UInt32:  CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }
extension UInt64:  CGFloatable { public var CGFloatValue: CGFloat { return CGFloat(self) } }

public protocol Floatable {
  var FloatValue: Float { get }
}

extension CGFloat: Floatable { public var FloatValue: Float { return Float(self) } }
extension Float:   Floatable { public var FloatValue: Float { return self        } }
extension Double:  Floatable { public var FloatValue: Float { return Float(self) } }
extension Int:     Floatable { public var FloatValue: Float { return Float(self) } }
extension Int8:    Floatable { public var FloatValue: Float { return Float(self) } }
extension Int16:   Floatable { public var FloatValue: Float { return Float(self) } }
extension Int32:   Floatable { public var FloatValue: Float { return Float(self) } }
extension Int64:   Floatable { public var FloatValue: Float { return Float(self) } }
extension UInt:    Floatable { public var FloatValue: Float { return Float(self) } }
extension UInt8:   Floatable { public var FloatValue: Float { return Float(self) } }
extension UInt16:  Floatable { public var FloatValue: Float { return Float(self) } }
extension UInt32:  Floatable { public var FloatValue: Float { return Float(self) } }
extension UInt64:  Floatable { public var FloatValue: Float { return Float(self) } }

//public protocol FloatValueConvertible { var floatValue: Float { get }; init(_ floatValue: Float) }
//public protocol CGFloatValueConvertible { var cgfloatValue: CGFloat { get }; init(_ cgfloatValue: CGFloat) }
//public protocol DoubleValueConvertible { var doubleValue: Double { get }; init(_ doubleValue: Double) }
//
//extension Float: FloatValueConvertible { public var floatValue: Float { return self } }
//extension CGFloat: FloatValueConvertible { public var floatValue: Float { return Float(self) } }
//extension Double: FloatValueConvertible { public var floatValue: Float { return Float(self) } }
//extension IntMax: FloatValueConvertible { public var floatValue: Float { return Float(self) } }
//
//extension Float: CGFloatValueConvertible { public var cgfloatValue: CGFloat { return CGFloat(self) } }
//extension Double: CGFloatValueConvertible { public var cgfloatValue: CGFloat { return CGFloat(self) } }
//extension IntMax: CGFloatValueConvertible { public var cgfloatValue: CGFloat { return CGFloat(self) } }
//extension CGFloat: CGFloatValueConvertible {
//  public var cgfloatValue: CGFloat { return self }
//  public init(_ cgfloatValue: CGFloat) { self = cgfloatValue }
//}
//
//extension Float: DoubleValueConvertible { public var doubleValue: Double { return Double(self) } }
//extension CGFloat: DoubleValueConvertible { public var doubleValue: Double { return Double(self) } }
//extension IntMax: DoubleValueConvertible { public var doubleValue: Double { return Double(self) } }
//extension Double: DoubleValueConvertible { public var doubleValue: Double { return self } }
//
//
//public func numericCast<T:FloatValueConvertible>(x: T) -> Float {
//  return x.floatValue
//}
