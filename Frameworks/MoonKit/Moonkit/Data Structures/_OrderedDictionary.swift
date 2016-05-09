//
//  _OrderedDictionary.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/7/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

internal let maxLoadFactorInverse = 1/0.75

protocol _OrderedDictionaryBuffer: CollectionType, MutableCollectionType, RangeReplaceableCollectionType {
  associatedtype _Key:Hashable
  associatedtype _Value
  associatedtype _Element = (_Key, _Value)

  associatedtype Index = Int

  var storage: OrderedDictionaryStorage<_Key, _Value> { get }

  var initializedBuckets: BitMap { get }
  var bucketMap: HashBucketMap { get }

  var keysBaseAddress: UnsafeMutablePointer<_Key> { get }
  var valuesBaseAddress: UnsafeMutablePointer<_Value> { get }

  static func minimumCapacityForCount(count: Int) -> Int

}

protocol _OrderedDictionary: CollectionType, MutableCollectionType, RangeReplaceableCollectionType {
  associatedtype _Key:Hashable
  associatedtype _Value
  associatedtype _Element = (_Key, _Value)

  associatedtype Index = Int

  var count: Int { get }
  var capacity: Int { get }

  subscript(index: Index) -> _Element { get set }

  mutating func insertValue(value: _Value, forKey key: _Key)

  mutating func removeAtIndex(index: Index) -> _Element
  mutating func removeValueForKey(key: _Key) -> _Value?

  func indexForKey(key: _Key) -> Index?
  func valueForKey(key: _Key) -> _Value?

  subscript(key: _Key) -> _Value? { get set }

  var keys: LazyMapCollection<Self, _Key> { get }
  var values: LazyMapCollection<Self, _Value> { get }

}

