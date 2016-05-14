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

//  var capacity: Int { get }
//  var count: Int { get }

  var initializedBuckets: BitMap { get }
  var bucketMap: HashBucketMap { get }

  var keysBaseAddress: UnsafeMutablePointer<Key> { get }
  var valuesBaseAddress: UnsafeMutablePointer<Value> { get }

  var identity: UnsafePointer<Void> { get }

  static func minimumCapacityForCount(count: Int) -> Int

  mutating func isUniquelyReferenced() -> Bool

//  func valueForKey(key: Key) -> Value?
//
//  /// Returns the bucket for `key` diregarding collisions
//  func idealBucketForKey(key: Key) -> HashBucket
//
//  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
//  func positionForBucket(bucket: HashBucket) -> Int?
//
//  /// Returns the bucket for the member assigned to `position`.
//  /// - requires: A bucket has been assigned to `position`
//  func bucketForPosition(position: Int) -> HashBucket
//
//  /// Returns the key inserted into `bucket`
//  func keyInBucket(bucket: HashBucket) -> Key
//
//  /// Returns the key assigned to `position`
//  func keyAtPosition(position: Int) -> Key
//
//  /// Returns `false` when `bucket` is empty and `true` otherwise.
//  func isInitializedBucket(bucket: HashBucket) -> Bool
//
//  /// Returns the value inserted into `bucket`
//  func valueInBucket(bucket: HashBucket) -> Value
//
//  /// Returns the value assigned to `position`
//  func valueAtPosition(position: Int) -> Value
//
//  /// Convenience for retrieving both the key and value for a bucket.
//  func elementInBucket(bucket: HashBucket) -> (Key, Value)
//
//  /// Convenience for retrieving both the key and value for a position.
//  func elementAtPosition(position: Int) -> (Key, Value)
}
