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
}

extension KeyValueCollection where Self.Generator.Element == (Key, Value) {
  public var keys: LazyMapCollection<Self, Key> { return lazy.map { $0.0 } }
  public var values: LazyMapCollection<Self, Value> { return lazy.map { $0.1 } }
}

public protocol MutableKeyValueCollection: KeyValueCollection, MutableCollectionType {
  subscript(key: Key) -> Value? { get set }

  mutating func insertValue(value: Value, forKey key: Key)

  mutating func removeAtIndex(index: Index) -> (Key, Value)
  mutating func removeValueForKey(key: Key) -> Value?

  mutating func updateValue(value: Value, forKey key: Key) -> Value?
}

