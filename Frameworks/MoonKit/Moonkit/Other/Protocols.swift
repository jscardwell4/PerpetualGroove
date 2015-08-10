//
//  Protocols.swift
//  MSKit
//
//  Created by Jason Cardwell on 11/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

extension GCDAsyncUdpSocketError: ErrorType {}

public protocol JSONValueConvertible {
  var jsonValue: JSONValue { get }
}

public protocol JSONValueInitializable {
  init?(_ jsonValue: JSONValue?)
}

public protocol JSONExport {
  var jsonString: String { get }
}

public protocol WrappedErrorType: ErrorType {
  var underlyingError: ErrorType? { get }
}

public protocol KeyValueCollectionType: CollectionType {
  typealias Key: Hashable
  typealias Value
  subscript (key: Key) -> Value? { get }
  typealias KeysLazyCollectionType: CollectionType
  typealias ValuesLazyCollectionType: CollectionType
  var keys: LazyForwardCollection<KeysLazyCollectionType> { get }
  var values: LazyForwardCollection<ValuesLazyCollectionType> { get }
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
//      MSLogDebug("nested = \(nested)")
////      result.extend(nested.valuesForKey(key))
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
//  result.extend(_findValuesForKey(key, inContainer: container))
//  return result
//}
//
//private func _findValuesForKey<K, C:KeySearchable>(key: K, inContainer container: C) -> [Any] {
//  var result: [Any] = []
//  for value in container.allValues {
//    if let searchableValue = value as? KeySearchable {
//// wtf?
//      result.extend(findValuesForKey(key, inContainer: searchableValue))
//    }
//  }
//  return result
//}

extension Dictionary: KeyValueCollectionType {}

public protocol Presentable {
  var title: String { get }
}

public protocol Divisible {
  func /(lhs: Self, rhs: Self) -> Self
}

public protocol EnumerableType {
  static var allCases: [Self] { get }
}

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
  static func enumerate(block: (Self) -> Void) { allCases.apply(block) }
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
