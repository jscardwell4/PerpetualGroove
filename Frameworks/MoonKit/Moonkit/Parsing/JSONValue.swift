//
//  JSONValue.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/1/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//
import Foundation

// MARK: - JSONValue
/** Enumeration of discriminating union to represent a JSON value */
public enum JSONValue {
  public typealias ObjectValue = OrderedDictionary<Swift.String, JSONValue>
  public typealias ArrayValue = Swift.Array<JSONValue>
  public typealias AnyMappedObjectValue = OrderedDictionary<Swift.String, Any>
  public typealias AnyMappedArrayValue = Swift.Array<Any>

  case Boolean (Bool)
  case String (Swift.String)
  case Array (ArrayValue)
  case Object (ObjectValue)
  case Number (NSNumber)
  case Null

  /** Initialize to `Null` */
  public init() { self = Null }

  /**
  Initialize from a convertible type

  - parameter v: T:JSONValueConvertible
  */
  public init<T:JSONValueConvertible>(_ v: T) { self = v.jsonValue }

  /**
  Initialize to case `Array` using a `JSONValue` sequence

  - parameter s: S
  */
  public init<S:SequenceType where S.Generator.Element == JSONValue>(_ s: S) {
    self = Array(Swift.Array(s))
  }

  /**
  Initialize to case `Array` using a `JSONValueConvertible` sequence

  - parameter s: S
  */
  public init<S:SequenceType where S.Generator.Element:JSONValueConvertible>(_ s: S) {
    self = Array(Swift.Array(s).map({$0.jsonValue}))
  }

  /**
  Initialize to case `Object` using a key-value collection

  - parameter c: C
  */
  public init<C:KeyValueCollectionType where C.KeysLazyCollectionType.Generator.Element == Swift.String,
                                             C.ValuesLazyCollectionType.Generator.Element == JSONValue>(_ c: C)
  {
    self = Object(OrderedDictionary<Swift.String, JSONValue>(keys: c.keys, values: c.values))
  }

  /**
  Initialize to case `Object` using a key-value collection

  - parameter c: C
  */
  public init<C:KeyValueCollectionType where C.KeysLazyCollectionType.Generator.Element == Swift.String,
    C.ValuesLazyCollectionType.Generator.Element:JSONValueConvertible>(_ c: C)
  {
    self = Object(OrderedDictionary<Swift.String, JSONValue>(keys: c.keys, values: c.values.map({$0.jsonValue})))
  }

  public init?(_ v: Any) {
    if let x = v as? JSONValueConvertible { self = x.jsonValue }
    else if let x = v as? NSNumber { self = Number(x) }
    else if let x = v as? Swift.String { self = String(x) }
    else if let x = v as? BooleanType { self = Boolean(x.boolValue) }
    else if v is NSNull { self = Null }
    else if let x = v as? NSArray {
      let converted = compressedMap(x, {JSONValue($0)})
      if converted.count == x.count { self = Array(converted) }
      else { return nil }
    }
    else if let x = v as? [Any] {
      let converted = compressedMap(x, {JSONValue($0)})
      if converted.count == x.count { self = Array(converted) }
      else { return nil }
    }
    else if let x = v as? OrderedDictionary<Swift.String, Any> {
      let converted = x.compressedMap({JSONValue($2)})
      if converted.count == x.count { self = Object(converted) }
      else { return nil }
    }
    else if let x = v as? NSDictionary {
      let keys = x.allKeys.map({Swift.String($0)})
      let values = compressedMap(x.allValues, {JSONValue($0)})
      if keys.count == values.count { self = Object(OrderedDictionary(Swift.Array(zip(keys, values)))) }
      else { return nil }
    }
    else { return nil }
  }

  /**
  Initialize with any object or return nil upon conversion failure

  - parameter v: AnyObject
  */
  public init?(_ value: Any?) {
    if let v = value {
      self.init(v)
    } else { return nil }
  }

  /**
  stringValueWithDepth:

  - parameter depth: Int

  - returns: Swift.String
  */
  private func stringValueWithDepth(depth: Int) -> Swift.String {
    switch self {
      case .Boolean(_),
           .Null(_),
           .Number(_),
           .String(_):
        return rawValue

      case .Array(let a):
        let outerIndent = " " * (depth * 4)
        let innerIndent = outerIndent + " " * 4
        var string = "["
        let elements = a.map({$0.stringValueWithDepth(depth + 1)})
        switch elements.count {
          case 0: string += "]"
          case 1: string += "\n\(innerIndent)" + elements[0] + "\n\(outerIndent)]"
          default: string += "\n\(innerIndent)" + ",\n\(innerIndent)".join(elements) + "\n\(outerIndent)]"
        }
        return string

      case .Object(let o):
        let outerIndent = " " * (depth * 4)
        let innerIndent = outerIndent + " " * 4
        var string = "{"
        let keyValuePairs = o.map({"\"\($1)\": \($2.stringValueWithDepth(depth + 1))"}).values.array
        switch keyValuePairs.count {
          case 0: string += "]"
          case 1: string += "\n\(innerIndent)" + keyValuePairs[0] + "\n\(outerIndent)}"
          default: string += "\n\(innerIndent)" + ",\n\(innerIndent)".join(keyValuePairs) + "\n\(outerIndent)}"
        }
        return string
    }
  }

  /** The formatted JSONValue string representation */
  public var prettyRawValue: Swift.String { return stringValueWithDepth(0) }

  /** An object representation of the value */
  public var anyObjectValue: AnyObject {
    switch self {
      case .Boolean(let b): return b
      case .Null:           return NSNull()
      case .Number(let n):  return n
      case .String(let s):  return s
      case .Array(let a):   return a.map({$0.anyObjectValue})
      case .Object(let o):  return o.map({$2.anyObjectValue}) as MSDictionary
    }
  }

  /** The associated value */
  public var value: Any {
    switch self {
      case .Boolean(let b): return b
      case .Null:           return ()
      case .Number(let n):  return n
      case .String(let s):  return s
      case .Array(let a):   return a
      case .Object(let o):  return o
    }
  }

  public var stringValue: Swift.String? { switch self { case .String(let s):  return s; default: return nil } }
  public var boolValue: Bool? { switch self { case .Boolean(let b):  return b; default: return nil } }
  public var numberValue: NSNumber? { switch self { case .Number(let n):  return n; default: return nil } }
  public var intValue: Int? { return numberValue?.longValue }
  public var int8Value: Int8? { return numberValue?.charValue }
  public var int16Value: Int16? { return numberValue?.shortValue }
  public var int32Value: Int32? { return numberValue?.intValue }
  public var int64Value: Int64? { return numberValue?.longLongValue }
  public var uintValue: UInt? { return numberValue?.unsignedLongValue }
  public var uint8Value: UInt8? { return numberValue?.unsignedCharValue }
  public var uint16Value: UInt16? { return numberValue?.unsignedShortValue }
  public var uint32Value: UInt32? { return numberValue?.unsignedIntValue }
  public var uint64Value: UInt64? { return numberValue?.unsignedLongLongValue }
  public var floatValue: Float? { return numberValue?.floatValue }
  public var CGFloatValue: CGFloat? { if let d = doubleValue { return CGFloat(d) } else { return nil } }
  public var doubleValue: Double? { return numberValue?.doubleValue }
  public var CGSizeValue: CGSize? { return CGSize(stringValue) }
  public var UIEdgeInsetsValue: UIEdgeInsets? { return UIEdgeInsets(stringValue) }
  public var CGRectValue: CGRect? { return CGRect(stringValue) }
  public var CGPointValue: CGPoint? { return CGPoint(stringValue) }
  public var CGVectorValue: CGVector? { return CGVector(stringValue) }
  public var UIOffsetValue: UIOffset? { return UIOffset(stringValue) }
  public var CGAffineTransformValue: CGAffineTransform? { return CGAffineTransform(stringValue) }

  public var objectValue: ObjectValue? { switch self { case .Object(let o):  return o; default: return nil } }
  public var mappedObjectValue: AnyMappedObjectValue? {
    return objectValue?.map({$2.mappedObjectValue ?? $2.mappedArrayValue ?? $2.value})
  }

  public var arrayValue: ArrayValue? { switch self { case .Array(let a):  return a; default: return nil } }
  public var mappedArrayValue: AnyMappedArrayValue? {
    return arrayValue?.map({$0.mappedArrayValue ?? $0.mappedObjectValue ?? $0.value})
  }

  /** The value any dictionary keypaths expanded into deeper levels */
  public var inflatedValue: JSONValue {
    switch self {
      case .Array(let a): return .Array(a.map({$0.inflatedValue}))
      case .Object(let o):
        let expand = {(var keypath: Stack<Swift.String>, var leaf: ObjectValue) -> JSONValue in
          while let k = keypath.pop() { leaf = [k:.Object(leaf)] }
          return .Object(leaf)
        }
        return .Object(o.inflated(expand).map({$2.inflatedValue}))
      default: return self
    }
  }

  /**
  Returns the value at the specified index when self is Array or Object and index is valid, nil otherwise

  - parameter idx: Int

  - returns: JSONValue?
  */
  public subscript(idx: Int) -> JSONValue? {
    switch self {
      case .Array(let a) where a.count > idx: return a[idx]
      case .Object(let o) where o.count > idx: return o[idx].2
    default: return nil
    }
  }

  /**
  Returns the value for the specified key when self is Object and nil otherwise

  - parameter key: Swift.String

  - returns: JSONValue?
  */
  public subscript(key: Swift.String) -> JSONValue? {
    switch self { case .Object(let o): return o[key]; default: return nil }
  }
}

// MARK: RawRepresentable
extension JSONValue: RawRepresentable {
  public var rawValue: Swift.String {
    switch self {
      case .Boolean(let b): return Swift.String(b)
      case .Null:           return "null"
      case .Number(let n):  return Swift.String(n)
      case .String(let s):  return "\"".sandwhich(s)
      case .Array(let a):   return "[" + ",".join(a.map({$0.rawValue})) + "]"
      case .Object(let o):  return "{" + ",".join(o.keyValuePairs.map({"\"\($0)\":\($1.rawValue)"})) + "}"
    }
  }
  public init?(rawValue: Swift.String) {
    let parser = JSONParser(string: rawValue, allowFragment: true)
    do {
      self = try parser.parse()
    } catch {
      MSHandleError(error as NSError)
      return nil
    }
  }
}

// MARK: Equatable
extension JSONValue: Equatable {}
public func ==(lhs: JSONValue, rhs: JSONValue) -> Bool {
  switch (lhs, rhs) {
    case (.String(let ls), .String(let rs)) where ls == rs:
      return true
    case (.Boolean(let lb), .Boolean(let rb)) where lb == rb:
      return true
    case (.Number(let ln), .Number(let rn)) where ln.isEqualToNumber(rn):
      return true
    case (.Null, .Null):
      return true
    case (.Array(let la), .Array(let ra)) where la == ra:
      return true
    case (.Object(let lo), .Object(let ro)) where lo.count == ro.count && lo.keys.array == ro.keys.array:
      let keys = lo.keys.array
      return keys.compressedMap({lo[$0]}) == keys.compressedMap({ro[$0]})
    default:
      return false
  }
}

// MARK: Hashable
extension JSONValue: Hashable {
  public var hashValue: Int { return rawValue.hashValue }
}

// MARK: BooleanLiteralConvertible
extension JSONValue: BooleanLiteralConvertible { public init(booleanLiteral b: Bool) { self = Boolean(b) } }

// MARK: NilLiteralConvertible
extension JSONValue: NilLiteralConvertible { public init(nilLiteral: ()) { self = Null } }

// MARK: IntegerLiteralConvertible
extension JSONValue: IntegerLiteralConvertible { public init(integerLiteral value: Int) { self = Number(value) } }

// MARK: FloatLiteralConvertible
extension JSONValue: FloatLiteralConvertible { public init(floatLiteral value: Double) { self = Number(value) } }

// MARK: ArrayLiteralConvertible
extension JSONValue: ArrayLiteralConvertible { public init(arrayLiteral elements: JSONValue...) { self = Array(elements) } }

// MARK: StringLiteralConvertible
extension JSONValue: StringLiteralConvertible {
  public init(stringLiteral s: Swift.String) { self = String(s) }
  public init(extendedGraphemeClusterLiteral s: Swift.String) { self = String(s) }
  public init(unicodeScalarLiteral s: Swift.String) { self = String(s) }
}

// MARK: StringInterpolationConvertible
extension JSONValue: StringInterpolationConvertible {
  public init(stringInterpolation strings: JSONValue...) { self = String(strings.reduce("", combine: {$0 + ($1.stringValue ?? "")})) }
  public init<T>(stringInterpolationSegment expr: T) { self = String(Swift.String(expr)) }
}

// MARK: Streamable
extension JSONValue: Streamable { public func writeTo<T:OutputStreamType>(inout target: T) { target.write(rawValue) } }

// MARK: Printable
extension JSONValue: CustomStringConvertible { public var description: Swift.String { return rawValue } }

// MARK: DebugPrintable
extension JSONValue: CustomDebugStringConvertible {
  public var debugDescription: Swift.String {
    var description: Swift.String = "\n"
    switch self {
      case .Boolean(let b):
        description += "JSONValue.Boolean(\(b))"
      case .Null:
        description += "JSONValue.Null"
      case .Number(let n):
        description += "JSONValue.Number(\(n))"
      case .String(let s):
        description += "JSONValue.String(\(s))"
      case .Array(let a):
        let c = a.count
        if c == 1 { description += "JSONValue.Array(1 item)\nitem:\n\t{\n\(a[0].debugDescription.indentedBy(8))\n\t}" }
        else {
          description += "JSONValue.Array(\(c) items)"
          if c > 0 {
            let items = ",\n".join(a.map({"\t{\n\($0.debugDescription.indentedBy(8))\n\t}"}))
            description += "\nitems: \(items))"
          }
        }

      case .Object(let o):
        let c = o.count
        if c == 1 {
          let k = o.keys[0], v = o.values[0].debugDescription.indentedBy(8)
          description += "JSONValue.Object(1 entry)\nentry:\n\t\(k): {\n\(v)\n\t}"
        } else {
          description += "JSONValue.Object(\(c) entries)"
          if c > 0 {
            let entries = ",\n".join(o.keyValuePairs.map({"\t\($0): {\n\($1.debugDescription.indentedBy(8))\n\t}"}))
            description += "\nentries:\n\(entries)"
          }
        }
    }
    return description
  }
}

