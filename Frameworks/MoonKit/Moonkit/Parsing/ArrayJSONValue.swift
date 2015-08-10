//
//  ArrayJSONValue.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public struct ArrayJSONValue: JSONValueConvertible, JSONValueInitializable {
  public private(set) var value: [JSONValue]
  public var jsonValue: JSONValue { return .Array(value) }
  public var count: Int { return value.count }

  public init(_ value: [JSONValue]) { self.value = value }
  public init<J:JSONValueConvertible>(_ value: [J]) { self.value = value.map({$0.jsonValue}) }
  public init?(_ v: JSONValue?) { switch v ?? .Null { case .Array(let a): value = a; default: return nil } }

  public func filter(includeElement: (JSONValue) -> Bool) -> ArrayJSONValue {
    return ArrayJSONValue(value.filter(includeElement))
  }

  public mutating func append<J:JSONValueConvertible>(j: J) { append(j.jsonValue) }
  public mutating func append(j: JSONValue) { value.append(j) }

  public mutating func extend(other: ArrayJSONValue) { extend(other.value) }
  public mutating func extend(other: [JSONValue]) { value.extend(other) }

  public func map<U>(transform: (JSONValue) -> U) -> [U] { return value.map(transform) }
  public func map(transform: (JSONValue) -> JSONValue) -> ArrayJSONValue { return ArrayJSONValue(value.map(transform)) }

  public func compressedMap<U>(transform: (JSONValue) -> U?) -> [U] { return value.compressedMap(transform) }

  public var objectMapped: [ObjectJSONValue] { return compressedMap({ObjectJSONValue($0)}) }

  public func contains(array: ArrayJSONValue) -> Bool {
    if array.count > count { return false }
    for object in array {
      switch object {
      case .Null where object ∈ value: continue
      case .String(_) where object ∈ value: continue
      case .Number(_) where object ∈ value: continue
      case .Boolean(_) where object ∈ value: continue
      case .Object(_) where object ∈ value: continue
      case .Array(_) where object ∈ value: continue
      default: return false
      }
    }

    return true
  }

}
extension ArrayJSONValue: CollectionType {
  public typealias Index = JSONValue.ArrayValue.Index
  public typealias Generator = JSONValue.ArrayValue.Generator
  public var startIndex: Index { return value.startIndex }
  public var endIndex: Index { return value.endIndex }
  public func generate() -> Generator { return value.generate() }
  public subscript(idx: Index) -> Generator.Element { get { return value[idx] } set { value[idx] = newValue } }
}

extension ArrayJSONValue: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { return value.description }
  public var debugDescription: String { return "MoonKit.ArrayJSONValue - value: \(description)" }
}

public func +(var lhs: ArrayJSONValue, rhs: ArrayJSONValue) -> ArrayJSONValue { lhs.extend(rhs); return lhs }
public func +=(inout lhs: ArrayJSONValue, rhs: ArrayJSONValue) { lhs.extend(rhs) }

public func +(var lhs: ArrayJSONValue, rhs: JSONValue) -> ArrayJSONValue { lhs.append(rhs); return lhs }
public func +=(inout lhs: ArrayJSONValue, rhs: JSONValue) { lhs.append(rhs) }

public func +(var lhs: ArrayJSONValue, rhs: JSONValue.ArrayValue) -> ArrayJSONValue { lhs.extend(rhs); return lhs }
public func +=(inout lhs: ArrayJSONValue, rhs: JSONValue.ArrayValue) { lhs.extend(rhs) }

public func +<J:JSONValueConvertible>(var lhs: ArrayJSONValue, rhs: J) -> ArrayJSONValue { lhs.append(rhs); return lhs }
public func +=<J:JSONValueConvertible>(inout lhs: ArrayJSONValue, rhs: J) { lhs.append(rhs) }
