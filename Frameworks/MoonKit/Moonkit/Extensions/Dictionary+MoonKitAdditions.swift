//
//  Dictionary+MoonKitAdditions.swift
//  Remote
//
//  Created by Jason Cardwell on 12/20/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

//extension NSDictionary: JSONExport {
//  public var JSONString: String { return JSONSerialization.JSONFromObject(JSONObject) ?? "" }
//  public var JSONObject: AnyObject { return self }
//}

//extension NSDictionary: JSONValueConvertible {
//  public var JSONValue: NSDictionary { return self }
//  public convenience init?(JSONValue: NSDictionary) { self.init(dictionary: JSONValue) }
//}

public protocol KeyValueCollectionTypeGenerator {
  typealias Key
  typealias Value
  mutating func next() -> (Key, Value)?
}

extension DictionaryGenerator: KeyValueCollectionTypeGenerator {}

/**
keys:

- parameter x: C

- returns: [C.Key]
*/
public func keys<C: KeyValueCollectionType where C.Generator: KeyValueCollectionTypeGenerator>(x: C) -> [C.Key] {
  var keys: [C.Key] = []
  for entry in x { if let key = _reflect(entry)[0].1.value as? C.Key { keys.append(key) } }
  return keys
}

/**
values:

- parameter x: C

- returns: [C.Value]
*/
public func values<C: KeyValueCollectionType where C.Generator: KeyValueCollectionTypeGenerator>(x: C) -> [C.Value] {
  var values: [C.Value] = []
  for entry in x { if let value = _reflect(entry)[1].1.value as? C.Value { values.append(value) } }
  return values
}


/**
formattedDescription:indent:

- parameter dictionary: C
- parameter indent: Int = 0

- returns: String
*/
public func formattedDescription<C: KeyValueCollectionType where C.Generator: KeyValueCollectionTypeGenerator>(dictionary: C, indent: Int = 0) -> String {

  var components: [String] = []

  let keyDescriptions = keys(dictionary).map { "\($0)" }
  let maxKeyLength = keyDescriptions.reduce(0) { max($0, $1.characters.count) }
  let indentation = " " * (indent * 4)
  for (key, value) in zip(keyDescriptions, values(dictionary)) {
//    let keyLength = key.count
//    var spacer = ""
//    if keyLength != maxKeyLength {
//      let offset = maxKeyLength - keyLength + 1
//      let numberOfTabs = Int(floor(Double(offset) / 4.0)) - 1
//      spacer = "\t" * numberOfTabs
//    }
    let keyString = "\(indentation)\(key): "//\(spacer)"
    var valueString: String
    var valueComponents = "\n".split("\(value)")
    if valueComponents.count > 0 {
      valueString = valueComponents.removeAtIndex(0)
      if valueComponents.count > 0 {
        let spacer = "\t" * (Int(floor(Double((maxKeyLength+1))/4.0)) - 1)
        let subIndentString = "\n\(indentation)\(spacer)"
        valueString += subIndentString + subIndentString.join(valueComponents)
      }
    } else { valueString = "nil" }
    components += ["\(keyString)\(valueString)"]
  }
  return "\n".join(components)
}

public extension Dictionary {
  /**
  init:Value)]:

  - parameter elements: [(Key, Value)]
  */
  init(_ elements: [(Key,Value)]) {
    self = [Key:Value]()
    for (k, v) in elements { self[k] = v }
  }

  var keyValuePairs: [(Key, Value)] { return Array(AnySequence({self.generate()})) }

  func map<U>(transform: (Key, Value) -> U) -> [Key:U] {
    var result: [Key:U] = [:]
    for (key, value) in self { result[key] = transform(key, value) }
    return result
  }
}

/**
keyValuePairs:

- parameter dict: [K V]

- returns: [(K, V)]
*/
public func keyValuePairs<K:Hashable,V>(dict: [K:V]) -> [(K, V)] { return dict.keyValuePairs }

/**
extended:newElements:V)]:

- parameter dict: [K V]
- parameter newElements: [(K
- parameter V)]:

- returns: [K:V]
*/
public func extended<K:Hashable,V>(dict: [K:V], newElements: [(K,V)]) -> [K:V] {
  return Dictionary(Array(AnySequence({dict.generate()})) + newElements)
}

/**
extend:newEntries:

- parameter x: [K:V]
- parameter newEntries: [K:V]
*/
public func extend<K,V>(inout x: [K:V], newEntries: [K:V]) { for (key, value) in newEntries { x[key] = value } }

/**
map:transform:

- parameter dict: [K:V]
- parameter block: (K, V) -> U
- returns: [K:U]
*/
public func map<K,V,U>(dict: [K:V], transform: (K, V) -> U) -> [K:U] {
  var result: [K:U] = [:]
  for (key, value) in dict { result[key] = transform(key, value) }
  return result
}

/**
subscript:rhs:

- parameter lhs: [K:V]
- parameter rhs: K

- returns: [K:V]
*/
public func -<K,V>(var lhs: [K:V], rhs: K) -> [K:V] {
  lhs.removeValueForKey(rhs)
  return lhs
}

/**
filter:

- parameter dict: [K:V]

- returns: [K:V]
*/
public func filter<K:Hashable,V>(dict: [K:V], include: (K, V) -> Bool) -> [K:V] {
  var filteredDict: [K:V] = [:]
  for (key, value) in dict { if include(key, value) { filteredDict[key] = value } }
  return filteredDict
}

/**
compressed:

- parameter dict: [K:Optional<V>]

- returns: [K:V]
*/
public func compressed<K:Hashable,V>(dict: [K:Optional<V>]) -> [K:V] {
  return Dictionary(dict.keyValuePairs.filter({$1 != nil}).map({($0,$1!)}))
}

/**
compressedMap:transform:

- parameter dict: [K:V]
- parameter block: (K, V) -> U?
- returns: [K:U]
*/
public func compressedMap<K:Hashable,V,U>(dict: [K:V], transform: (K, V) -> U?) -> [K:U] {
  return compressed(map(dict, transform: transform))
}

public func inflated(var dict: [String:AnyObject]) -> [String:AnyObject] { inflate(&dict); return dict }

public func inflate(inout dict: [String:AnyObject]) {
  // First gather a list of keys to inflate
  let inflatableKeys = Array(dict.keys.filter({$0 ~= "(?:\\w\\.)+\\w"}))

  // Enumerate the list inflating each key
  for key in inflatableKeys {

    var keys = ".".split(key)
    let firstKey = keys.first!
    let lastKey = keys.last!
    var keypath = Stack(keys.dropFirst().dropLast())
    let value: AnyObject

    func inflatedValue(obj: AnyObject) -> [String:AnyObject] {
      var kp = keypath
      var d: [String:AnyObject] = [lastKey:obj]

      // If there are stops along the way from first to last, recursively embed in dictionaries
      while let k = kp.pop() { d = [k: d] }

      return d
    }

    // If our value is an array, we embed each value in the array and keep our value as an array
    if let valueArray = dict[key] as? [AnyObject] { value = valueArray.map(inflatedValue) }

      // Otherwise we embed the value
    else { value = inflatedValue(dict[key]!) }

    dict[firstKey] = value
    dict[key] = nil                              // Remove the compressed key-value entry
  }
}

public func zipDict<S0:SequenceType, S1:SequenceType
  where S0.Generator.Element:Hashable>(s0: S0, _ s1: S1) -> [S0.Generator.Element:S1.Generator.Element]
{
  let arrayGenerator: Zip2Sequence<S0, S1> = zip(s0, s1)
  return Dictionary(Array(arrayGenerator))
}

/**
from stackoverflow answer posted by http://stackoverflow.com/users/59541/nate-cook

- parameter lhs: [K1 [K2 T]]
- parameter rhs: [K1 [K2 T]]

- returns: Bool
*/
public func ==<T: Equatable, K1: Hashable, K2: Hashable>(lhs: [K1: [K2: T]], rhs: [K1: [K2: T]]) -> Bool {
  if lhs.count != rhs.count { return false }
  for (key, lhsub) in lhs { if let rhsub = rhs[key] where lhsub == rhsub { continue } else { return false } }
  return true
}
