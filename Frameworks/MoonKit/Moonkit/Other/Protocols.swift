//
//  Protocols.swift
//  MSKit
//
//  Created by Jason Cardwell on 11/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
//import UIKit
//import SpriteKit
import Swift


extension GCDAsyncUdpSocketError: ErrorType {}

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
//  func toIntMax() -> IntMax
//  init(intMax: IntMax)
  init()
  var isZero: Bool { get }
}

extension ArithmeticType where Self:BitwiseOperationsType, Self:Equatable {
  public var isZero: Bool { return self == Self.allZeros }
}

public protocol JSONExport {
  var jsonString: String { get }
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
  public var index: Int {
    guard let index = Self.allCases.indexOf(self) else { fatalError("`allCases` does not contain \(self)") }
    return index
  }
  public init(index: Int) {
    guard Self.allCases.indices.contains(index) else { fatalError("index out of bounds") }
    self = Self.allCases[index]
  }
}

public protocol KeyType: RawRepresentable, Hashable {
  var key: String { get }
}

public extension KeyType where Self.RawValue == String {
  var key: String { return rawValue }
  var hashValue: Int { return rawValue.hashValue }
}

public func ==<K:KeyType>(lhs: K, rhs: K) -> Bool { return lhs.key == rhs.key }

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

#if os(iOS)
public protocol ImageAssetLiteralType {
  var image: UIImage { get }
}

public extension ImageAssetLiteralType where Self:RawRepresentable, Self.RawValue == String {
  public var image: UIImage { return UIImage(named: rawValue)! }
}

public extension ImageAssetLiteralType where Self:EnumerableType {
  public static var allImages: [UIImage] { return allCases.map({$0.image}) }
}
import class SpriteKit.SKTextureAtlas
import class SpriteKit.SKTexture
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

  #endif

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

public protocol Packable2 {
  typealias Element
  init(_ elements: (Element, Element))
}

public extension Unpackable2 {
  var unpackArray: [Element] { let tuple = unpack; return [tuple.0, tuple.1] }
}

public protocol Unpackable3 {
  typealias Element
  var unpack: (Element, Element, Element) { get }
}

public protocol Packable3 {
  typealias Element
  init(_ elements: (Element, Element, Element))
}

public extension Unpackable3 {
  var unpackArray: [Element] { let tuple = unpack; return [tuple.0, tuple.1, tuple.2] }
}

public protocol Unpackable4 {
  typealias Element
  var unpack4: (Element, Element, Element, Element) { get }
}

public extension Unpackable4 {
  var unpackArray: [Element] { let tuple = unpack4; return [tuple.0, tuple.1, tuple.2, tuple.3] }
}

public protocol Packable4 {
  typealias Element
  init(_ elements: (Element, Element, Element, Element))
}

public protocol NonHomogeneousUnpackable2 {
  typealias Type1
  typealias Type2
  var unpack2: (Type1, Type2) { get }
}


/** Protocol for an object guaranteed to have a name */
public protocol Named {
  var name: String { get }
}

public protocol DynamicallyNamed: Named {
  var name: String { get set }
}

/** Protocol for an object that may have a name */
public protocol Nameable {
  var name: String? { get }
}

/** Protocol for an object that may have a name and for which a name may be set */
public protocol Renameable: Nameable {
  var name: String? { get set }
}

public protocol StringValueConvertible {
  var stringValue: String { get }
}
