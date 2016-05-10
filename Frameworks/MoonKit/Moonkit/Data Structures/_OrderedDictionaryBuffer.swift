//
//  _OrderedDictionaryBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/9/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

protocol _OrderedDictionaryBuffer: CollectionType, MutableCollectionType, RangeReplaceableCollectionType {
  associatedtype Key:Hashable
  associatedtype Value

  var storage: OrderedDictionaryStorage<Key, Value> { get }

  
  var initializedBuckets: BitMap { get }
  var bucketMap: HashBucketMap { get }

  var keysBaseAddress: UnsafeMutablePointer<Key> { get }
  var valuesBaseAddress: UnsafeMutablePointer<Value> { get }

  var identity: UnsafePointer<Void> { get }

  static func minimumCapacityForCount(count: Int) -> Int

  mutating func isUniquelyReferenced() -> Bool

  func valueForKey(key: Key) -> Value?
}

