//
//  Protocols.swift
//  MSKit
//
//  Created by Jason Cardwell on 11/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import Swift

public typealias Byte = UInt8
public typealias Byte2 = UInt16
public typealias Byte4 = UInt32
public typealias Byte8 = UInt64

public protocol ByteArrayConvertible: Equatable {
  var bytes: [Byte] { get }
  init(_ bytes: [Byte])
  init<S:SequenceType where S.Generator.Element == Byte>(_ bytes: S)
}

public func ==<B:ByteArrayConvertible>(lhs: B, rhs: B) -> Bool {
  let leftBytes = lhs.bytes, rightBytes = rhs.bytes
  guard leftBytes.count == rightBytes.count else { return false }
  for (leftByte, rightByte) in zip(leftBytes, rightBytes) { guard leftByte  == rightByte else { return false } }
  return true
}
extension ByteArrayConvertible {
  public init<S:SequenceType where S.Generator.Element == Byte>(_ bytes: S) { self.init(Array(bytes)) }
}

extension UInt: ByteArrayConvertible {
  public var bytes: [Byte] { return sizeof(UInt.self) == 8 ? UInt64(self).bytes : UInt32(self).bytes }
  public init(_ bytes: [Byte]) {
    self = sizeof(UInt.self) == 8 ? UInt(UInt64(bytes)) : UInt(UInt32(bytes))
  }
}

extension Int: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt(self).bytes }
  public init<S:SequenceType where S.Generator.Element == Byte>(_ bytes: S) { self = Int(UInt(bytes)) }
}


extension UInt8: ByteArrayConvertible {
  public var bytes: [Byte] { return [self] }
  public init(_ bytes: [Byte]) {
    guard let byte = bytes.first else { self = 0; return }
    self = byte
  }
}
extension Int8: ByteArrayConvertible {
  public var bytes: [Byte] { return [UInt8(self)] }
  public init(_ bytes: [Byte]) { self = Int8(UInt8(bytes)) }
}

extension UInt16: ByteArrayConvertible {
  public var bytes: [Byte] { return [Byte(self >> 8 & 0xFF), Byte(self & 0xFF)] }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count < 3 else { self = UInt16(bytes[count - 2 ..< count]); return }
    switch bytes.count {
    case 2:
      self = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    case 1:
      self = UInt16(bytes[0])
    default:
      self = 0
    }
  }
}
extension Int16: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt16(self).bytes }
  public init(_ bytes: [Byte]) { self = Int16(UInt16(bytes)) }
}

extension UInt32: ByteArrayConvertible {
  public var bytes: [Byte] {
    return [Byte(self >> 24 & 0xFF), Byte(self >> 16 & 0xFF), Byte(self >> 8 & 0xFF), Byte(self & 0xFF)]
  }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count > 2 else { self = UInt32(UInt16(bytes)); return }
    self = UInt32(UInt16(bytes[0 ..< count - 2])) << 16 | UInt32(UInt32(bytes[count - 2 ..< count]))
  }
}
extension Int32: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt32(self).bytes }
  public init(_ bytes: [Byte]) { self = Int32(UInt32(bytes)) }
}

extension UInt64: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt32(self >> 32 & 0xFFFFFFFF).bytes  + UInt32(self & 0xFFFFFFFF).bytes }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count > 4 else { self = UInt64(UInt32(bytes)); return }
    self = UInt64(UInt32(bytes[0 ..< count - 4])) << 32 | UInt64(UInt32(bytes[count - 4 ..< count]))
  }
}
extension Int64: ByteArrayConvertible {
  public var bytes: [Byte] { return UInt64(self).bytes }
  public init(_ bytes: [Byte]) { self = Int64(UInt64(bytes)) }
}

extension GCDAsyncUdpSocketError: ErrorType {}

public protocol JSONValueConvertible {
  var jsonValue: JSONValue { get }
}

public protocol JSONValueInitializable {
  init?(_ jsonValue: JSONValue?)
}

public protocol Divisible {
  func /(lhs: Self, rhs: Self) -> Self
}

public protocol ArithmeticType {
  func +(lhs: Self, rhs: Self) -> Self
  func -(lhs: Self, rhs: Self) -> Self
  func *(lhs: Self, rhs: Self) -> Self
  func /(lhs: Self, rhs: Self) -> Self
  func %(lhs: Self, rhs: Self) -> Self
  func +=(inout lhs: Self, rhs: Self)
  func -=(inout lhs: Self, rhs: Self)
  func /=(inout lhs: Self, rhs: Self)
  func *=(inout lhs: Self, rhs: Self)
  func %=(inout lhs: Self, rhs: Self)
  func toIntMax() -> IntMax
  init(intMax: IntMax)
}

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
public protocol _FloatProducibleType {}
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
      default: logWarning("unknown '_FloatProdocibleType"); self.init(0.0)
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


public protocol JSONExport {
  var jsonString: String { get }
}

public protocol WrappedErrorType: ErrorType {
  var underlyingError: ErrorType? { get }
}

public extension ErrorType where Self:RawRepresentable, Self.RawValue == String {
  public var description: String { return rawValue }
}

public protocol ExtendedErrorType: ErrorType, CustomStringConvertible {
  var line: Int32 { get set }
  var function: String { get set }
  var file: String { get set }
  var reason: String { get set }
  init()
  init(line: Int32, function: String, file: String, reason: String)
}

public extension ExtendedErrorType {
  public init(line l: Int32 = __LINE__, function fu: String = __FUNCTION__, file fi: String = __FILE__, reason r: String) {
    self.init()
    line = l; function = fu; file = fi; reason = r
  }
  public var description: String { return "<\((file as NSString).lastPathComponent):\(line)> \(function)  \(reason)" }
}

public protocol KeyValueCollectionType: CollectionType {
  typealias Key: Hashable
  typealias Value
  subscript (key: Key) -> Value? { get }
  typealias KeysType: LazyCollectionType
  typealias ValuesType: LazyCollectionType
  var keys: KeysType { get }
  var values: ValuesType { get }
}

public protocol KeyedContainer {
  typealias Key: Hashable
  func hasKey(key: Key) -> Bool
  func valueForKey(key: Key) -> Any?
}

public protocol KeySearchable {
  var allValues: [Any] { get }
}

//public extension KeySearchable where Self:KeyedContainer {
//  public func valuesForKey(key: Key) -> [Any] {
//    var result: [Any] = []
//    if let v = valueForKey(key) { result.append(v) }
//
////    func nestedContainer<T:KeySearchable where T:KeyedContainer, T.Key == Key>(x: T) -> T { return x }
////
////    func nestedContainer<T>(x: Any) -> T { return x }
//
//    for case let nested as KeySearchable in allValues  {
//      logDebug("nested = \(nested)")
////      result.appendContentsOf(nested.valuesForKey(key))
//    }
//    return result
//  }
//}

public protocol NestingContainer {
  var topLevelObjects: [Any] { get }
  func topLevelObjects<T>(type: T.Type) -> [T]
  var allObjects: [Any] { get }
  func allObjects<T>(type: T.Type) -> [T]
}

//public func findValuesForKey<K, C:KeySearchable>(key: K, inContainer container: C) -> [Any] {
//  return _findValuesForKey(key, inContainer: container)
//}
//
//public func findValuesForKey<K, C:KeySearchable where C:KeyedContainer, K == C.Key>(key: K, inContainer container: C) -> [Any]
//{
//  var result: [Any] = []
//  if container.hasKey(key),
//    let v = container.valueForKey(key)
//  {
//    result.append(v)
//  }
//  result.appendContentsOf(_findValuesForKey(key, inContainer: container))
//  return result
//}
//
//private func _findValuesForKey<K, C:KeySearchable>(key: K, inContainer container: C) -> [Any] {
//  var result: [Any] = []
//  for value in container.allValues {
//    if let searchableValue = value as? KeySearchable {
//// wtf?
//      result.appendContentsOf(findValuesForKey(key, inContainer: searchableValue))
//    }
//  }
//  return result
//}

extension Dictionary: KeyValueCollectionType {}

public protocol Presentable {
  var title: String { get }
}

public protocol EnumerableType {
  static var allCases: [Self] { get }
}

public extension EnumerableType where Self: Equatable {
  public var index: Int { return Self.allCases.indexOf(self)! }
  public init(index: Int) {
    guard Self.allCases.indices.contains(index) else { fatalError("index out of bounds") }
    self = Self.allCases[index]
  }
}

public protocol NotificationNameType: RawRepresentable, Hashable {
  var value: String { get }
}

public extension NotificationNameType where Self.RawValue: Hashable {
  var hashValue: Int { return rawValue.hashValue }
}

public extension NotificationNameType where Self.RawValue == String {
  var value: String { return rawValue }
}

public protocol NotificationType: Hashable {
  typealias NotificationName: NotificationNameType
  var name: NotificationName { get }
  var userInfo: [NSObject:AnyObject]? { get }
  var object: AnyObject? { get }
  func post()
}

public extension NotificationType {
  var hashValue: Int { return name.hashValue }
  func post() {
    NSNotificationCenter.defaultCenter().postNotificationName(name.value, object: object, userInfo: userInfo)
  }
  var userInfo: [NSObject:AnyObject]? { return nil }
  var object: AnyObject? { return nil }
}

public extension NotificationType where Self:NotificationNameType {
  var name: Self { return self }
}

public func ==<T:NotificationType>(lhs: T, rhs: T) -> Bool { return lhs.name == rhs.name }

//public extension EnumerableType where Self:RawRepresentable, Self.RawValue: ForwardIndexType {
//  static var allCases: [Self] {
//    return Array(rawRange.generate()).flatMap({Self.init(rawValue: $0)})
//  }
//}

//public extension EnumerableType where Self:RawRepresentable, Self.RawValue == Int  {
//  static var allCases: [Self] {
//    var idx = 0
//    return Array(anyGenerator { Self.init(rawValue: idx++) })
//    return []
//  }
//}

public extension EnumerableType {
  static func enumerate(@noescape block: (Self) -> Void) { allCases.forEach(block) }
}

public protocol ImageAssetLiteralType {
  var image: UIImage { get }
}

public extension ImageAssetLiteralType where Self:RawRepresentable, Self.RawValue == String {
  public var image: UIImage { return UIImage(named: rawValue)! }
}

public extension ImageAssetLiteralType where Self:EnumerableType {
  public static var allImages: [UIImage] { return allCases.map({$0.image}) }
}

public protocol TextureAssetLiteralType {
  static var atlas: SKTextureAtlas { get }
  var texture: SKTexture { get }
}

public extension TextureAssetLiteralType where Self:RawRepresentable, Self.RawValue == String {
  public var texture: SKTexture { return Self.atlas.textureNamed(rawValue) }
}

public extension TextureAssetLiteralType where Self:EnumerableType {
  public static var allTextures: [SKTexture] { return allCases.map({$0.texture}) }
}

// causes ambiguity
public protocol IntegerDivisible {
  func /(lhs: Self, rhs:Int) -> Self
}

public protocol Summable {
  func +(lhs: Self, rhs: Self) -> Self
}

public protocol OptionalSubscriptingCollectionType: CollectionType {
  subscript (position: Optional<Self.Index>) -> Self.Generator.Element? { get }
}

public protocol Unpackable2 {
  typealias Element
  var unpack: (Element, Element) { get }
}

public extension Unpackable2 {
  var unpackArray: [Element] { let tuple = unpack; return [tuple.0, tuple.1] }
}

public protocol Unpackable3 {
  typealias Element
  var unpack: (Element, Element, Element) { get }
}

public extension Unpackable3 {
  var unpackArray: [Element] { let tuple = unpack; return [tuple.0, tuple.1, tuple.2] }
}

public protocol Unpackable4 {
  typealias Element
  var unpack: (Element, Element, Element, Element) { get }
}

public extension Unpackable4 {
  var unpackArray: [Element] { let tuple = unpack; return [tuple.0, tuple.1, tuple.2, tuple.3] }
}

/** Protocol for an object guaranteed to have a name */
@objc public protocol Named {
  var name: String { get }
}

@objc public protocol DynamicallyNamed: Named {
  var name: String { get set }
}

/** Protocol for an object that may have a name */
@objc public protocol Nameable {
  var name: String? { get }
}

/** Protocol for an object that may have a name and for which a name may be set */
@objc public protocol Renameable: Nameable {
  var name: String? { get set }
}

public protocol StringValueConvertible {
  var stringValue: String { get }
}
