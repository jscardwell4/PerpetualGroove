//
//  KeyValueCollection.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/9/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public protocol KeyValueCollection: CollectionType {
  associatedtype Key:Hashable
  associatedtype Value
  associatedtype Element = (Key, Value)

  subscript(key: Key) -> Value? { get }
  subscript(index: Index) -> (Key, Value) { get }

  func indexForKey(key: Key) -> Index?
  func valueForKey(key: Key) -> Value?

  var keys: LazyMapCollection<Self, Key> { get }
  var values: LazyMapCollection<Self, Value> { get }

  init<S:SequenceType where S.Generator.Element == Self.Generator.Element>(_ elements: S)
}

extension KeyValueCollection where Self.Generator.Element == (Key, Value) {
  public var keys: LazyMapCollection<Self, Key> { return lazy.map { $0.0 } }
  public var values: LazyMapCollection<Self, Value> { return lazy.map { $0.1 } }

  public func formattedDescription(indent indent: Int = 0) -> String {

    var components: [String] = []

    let keyDescriptions = keys.map { "\($0)" }
    let maxKeyLength = keyDescriptions.reduce(0) { max($0, $1.characters.count) }
    let indentation = " " * (indent * 4)
    for (key, value) in zip(keyDescriptions, values) {
      let keyString = "\(indentation)\(key): "
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

}

public protocol MutableKeyValueCollection: KeyValueCollection {
  subscript(key: Key) -> Value? { get set }

  mutating func insertValue(value: Value, forKey key: Key)

  mutating func removeAtIndex(index: Index) -> (Key, Value)
  mutating func removeValueForKey(key: Key) -> Value?

  mutating func updateValue(value: Value, forKey key: Key) -> Value?
}

extension Dictionary: KeyValueCollection {}

extension Dictionary: MutableKeyValueCollection {
  public mutating func insertValue(value: Value, forKey key: Key) {
    self[key] = value
  }
  public func valueForKey(key: Key) -> Value? {
    return self[key]
  }
}