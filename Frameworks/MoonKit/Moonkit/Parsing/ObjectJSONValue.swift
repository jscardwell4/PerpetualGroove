//
//  ObjectJSONValue.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/** Convenience struct for manipulating `JSONValue.Object` cases */
public struct ObjectJSONValue: JSONValueConvertible, JSONValueInitializable {
  public var jsonValue: JSONValue { return .Object(value) }
  public private(set) var value: JSONValue.ObjectValue
  public var count: Int { return value.count }
  public init(_ value: JSONValue.ObjectValue) { self.value = value }
  public init<J:JSONValueConvertible>(_ value: OrderedDictionary<String, J>) { self.value = value.map({$2.jsonValue}) }
  public init(_ value: [String:JSONValue]) { self.value = OrderedDictionary(value) }
  public init<J:JSONValueConvertible>(_ value: [String:J]) { self.value = OrderedDictionary(value).map({$2.jsonValue}) }

  public init?(_ v: JSONValue?) { switch v ?? .Null { case .Object(let o): value = o; default: return nil } }
  public subscript(key: String) -> JSONValue? { get { return value[key] } mutating set { value[key] = newValue } }
  public var keys: LazyForwardCollection<[String]> { return value.keys }
  public var values: LazyForwardCollection<MapCollection<[String], JSONValue>> { return value.values }
  public func filter(includeElement: (Int, String, JSONValue) -> Bool) -> ObjectJSONValue {
    return ObjectJSONValue(value.filter(includeElement))
  }
  public func map<U>(transform: (Int, String, JSONValue) -> U) -> OrderedDictionary<String, U> {
    return value.map(transform)
  }
  public func map(transform: (Int, String, JSONValue) -> JSONValue) -> ObjectJSONValue {
    return ObjectJSONValue(value.map(transform))
  }

  public func compressedMap<U>(transform: (Int, String, JSONValue) -> U?) -> OrderedDictionary<String, U> {
    return value.compressedMap(transform)
  }

  public func contains(object: ObjectJSONValue) -> Bool {
    let objectKeys = Set(object.keys)
    if objectKeys ⊈ keys { return false }
    for objectKey in objectKeys {
      if let objectValue = object[objectKey], selfValue = self[objectKey] {
        switch (objectValue, selfValue) {
        case (.Null, .Null): continue
        case (.String(let os), .String(let ss)) where os == ss: continue
        case (.Boolean(let ob), .Boolean(let sb)) where ob == sb: continue
        case (.Number(let on), .Number(let sn)) where on.isEqualToNumber(sn): continue
        case (.Array(let oa), .Array(let sa)): return ArrayJSONValue(sa).contains(ArrayJSONValue(oa))
        case (.Object(let oo), .Object(let so)): return ObjectJSONValue(so).contains(ObjectJSONValue(oo))
        default: return false
        }
      } else { return false }
    }
    return true
  }

  public mutating func extend(other: ObjectJSONValue) { value.extend(other.value) }
}

extension ObjectJSONValue: CollectionType {
  public typealias Index = JSONValue.ObjectValue.Index
  public typealias Generator = JSONValue.ObjectValue.Generator
  public var startIndex: Index { return value.startIndex }
  public var endIndex: Index { return value.endIndex }
  public func generate() -> Generator { return value.generate() }
  public subscript(idx: Index) -> Generator.Element { get { return value[idx] } set { value[idx] = newValue } }
}

extension ObjectJSONValue: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { return value.description }
  public var debugDescription: String { return "MoonKit.ObjectJSONValue - value: \(description)" }
}

public func +(var lhs: ObjectJSONValue, rhs: ObjectJSONValue) -> ObjectJSONValue { lhs.extend(rhs); return lhs }
public func +=(inout lhs: ObjectJSONValue, rhs: ObjectJSONValue) { lhs.extend(rhs) }
public func +(var lhs: ObjectJSONValue, rhs: JSONValue) -> ObjectJSONValue { if let o = ObjectJSONValue(rhs) { lhs.extend(o) }; return lhs }
public func +=(inout lhs: ObjectJSONValue, rhs: JSONValue) { if let o = ObjectJSONValue(rhs) { lhs.extend(o) } }
public func +(var lhs: ObjectJSONValue, rhs: JSONValue.ObjectValue) -> ObjectJSONValue { lhs.value.extend(rhs); return lhs }
public func +=(inout lhs: ObjectJSONValue, rhs: JSONValue.ObjectValue) { lhs.value.extend(rhs) }
public func +<J:JSONValueConvertible>(var lhs: ObjectJSONValue, rhs: (String, J)) -> ObjectJSONValue { lhs[rhs.0] = rhs.1.jsonValue; return lhs }
public func +=<J:JSONValueConvertible>(inout lhs: ObjectJSONValue, rhs: (String, J)) { lhs[rhs.0] = rhs.1.jsonValue }
public func +(var lhs: ObjectJSONValue, rhs: (String, JSONValue)) -> ObjectJSONValue { lhs[rhs.0] = rhs.1; return lhs }
public func +=(inout lhs: ObjectJSONValue, rhs: (String, JSONValue)) { lhs[rhs.0] = rhs.1 }

