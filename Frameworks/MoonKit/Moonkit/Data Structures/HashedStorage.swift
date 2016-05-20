//
//  HashedStorage.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

class HashedStorage: ManagedBuffer<HashedStorageHeader, UInt8> {

  typealias Header = HashedStorageHeader

  /// Returns the number of bytes required for the bit map of initialized buckets given `capacity`
  static func bytesForInitializedBuckets(capacity: Int) -> Int {
    return BitMap.wordsFor(capacity) * sizeof(UInt) + alignof(UInt)
  }

  /// The number of bytes used to store the bit map of initialized buckets for this instance
  final var initializedBucketsBytes: Int { return HashedStorage.bytesForInitializedBuckets(capacity) }

  /// Returns the number of bytes required for the map of buckets to positions given `capacity`
  static func bytesForBucketMap(capacity: Int) -> Int {
    return HashBucketMap.bytesFor(capacity) + max(0, alignof(Int) - alignof(UInt))
  }

  /// The number of bytes used to store the bucket map for this instance.
  final var bucketMapBytes: Int { return HashedStorage.bytesForBucketMap(capacity) }

  /// The total number of buckets
  final var capacity: Int { return value.capacity }

  /// The total number of initialized buckets
  final var count: Int { get { return value.count } set { value.count = newValue } }

  /// The total number of bytes managed by this instance; equal to
  /// `initializedBucketsBytes + bucketMapBytes + keysBytes + valuesBytes`
  final var bytesAllocated: Int { return value.bytesAllocated }

  /// Pointer to the first byte in memory allocated for the bit map of initialized buckets
  final var initializedBucketsAddress: UnsafeMutablePointer<UInt8> {
    return withUnsafeMutablePointerToElements {$0}
  }

  /// A bit map corresponding to which buckets have been initialized
  final var initializedBuckets: BitMap { return value.initializedBuckets }

  /// Pointer to the first byte in memory allocated for the position map
  final var bucketMapAddress: UnsafeMutablePointer<UInt8> {
    return initializedBucketsAddress + initializedBucketsBytes
  }

  /// An index mapping buckets to positions and positions to buckets
  final var bucketMap: HashBucketMap { return value.bucketMap }

  var description: String {
    defer { _fixLifetime(self) }
    var result = "HashedStorage {\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tinitializedBuckets: \(initializedBuckets.description.indentedBy(24, preserveFirst: true, useTabs: false))\n"
    result += "\tbucketMap: \(bucketMap.debugDescription)\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tinitializedBucketsBytes: \(initializedBucketsBytes)\n"
    result += "\tbucketMapBytes: \(bucketMapBytes)\n"
    result += "\n}"
    return result
  }
}

