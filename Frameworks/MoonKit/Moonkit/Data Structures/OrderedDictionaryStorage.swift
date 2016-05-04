//
//  OrderedDictionaryStorage.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

final class OrderedDictionaryStorage <Key:Hashable, Value>: ManagedBuffer<HashedStorageHeader, UInt8> {

  typealias Storage = OrderedDictionaryStorage<Key, Value>
  typealias Header = HashedStorageHeader

  /// Returns the number of bytes required for the bit map of initialized buckets given `capacity`
  static func bytesForInitializedBuckets(capacity: Int) -> Int {
    return BitMap.wordsFor(capacity) * sizeof(UInt) + alignof(UInt)
  }

  /// The number of bytes used to store the bit map of initialized buckets for this instance
  var initializedBucketsBytes: Int { return Storage.bytesForInitializedBuckets(capacity) }
  
  /// Returns the number of bytes required for the map of buckets to positions given `capacity`
  static func bytesForBucketMap(capacity: Int) -> Int {
    return strideof(Int) * (capacity * 2) + max(0, alignof(Int) - alignof(UInt))
  }

  /// The number of bytes used to store the bucket map for this instance.
  var bucketMapBytes: Int { return Storage.bytesForBucketMap(capacity) }

  /// Returns the number of bytes required to store the keys for a given `capacity`.
  static func bytesForKeys(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Key) - maxPrevAlignment)
    return strideof(Key) * capacity + padding
  }

  /// The number of bytes used to store the keys for this instance
  var keysBytes: Int { return Storage.bytesForKeys(capacity) }

  /// Returns the number of bytes required to store the values for a given `capacity`.
  static func bytesForValues(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(Key), alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Value) - maxPrevAlignment)
    return strideof(Value) * capacity + padding
  }

  /// The number of bytes used to store the values for this instance
  var valuesBytes: Int { return Storage.bytesForValues(capacity) }

  /// The total number of buckets
  var capacity: Int { return value.capacity }

  /// The total number of initialized buckets
  var count: Int { get { return value.count } set { value.count = newValue } }

  /// The total number of bytes managed by this instance; equal to
  /// `initializedBucketsBytes + bucketMapBytes + keysBytes + valuesBytes`
  var bytesAllocated: Int { return value.bytesAllocated }
  
  /// Pointer to the first byte in memory allocated for the bit map of initialized buckets
  var initializedBucketsAddress: UnsafeMutablePointer<UInt8> {
    return withUnsafeMutablePointerToElements {$0}
  }

  /// A bit map corresponding to which buckets have been initialized
  var initializedBuckets: BitMap { return value.initializedBuckets }

  /// Pointer to the first byte in memory allocated for the position map
  var bucketMapAddress: UnsafeMutablePointer<UInt8> {
    return initializedBucketsAddress + initializedBucketsBytes
  }

  /// An index mapping buckets to positions and positions to buckets
  var bucketMap: HashBucketMap { return value.bucketMap }

  /// Pointer to the first byte in memory allocated for the keys
  var keys: UnsafeMutablePointer<Key> {
    return UnsafeMutablePointer<Key>(bucketMapAddress + bucketMapBytes)
  }

  /// Pointer to the first byte in memory allocated for the values
  var values: UnsafeMutablePointer<Value> {
    // Conversion back to UInt8 pointer necessary for `+` operator to advance by byte
    return UnsafeMutablePointer<Value>(UnsafeMutablePointer<UInt8>(keys) + keysBytes)
  }

  /// Create a new storage instance.
  static func create(minimumCapacity: Int) -> OrderedDictionaryStorage {
    let capacity = round2(minimumCapacity)

    let initializedBucketsBytes = bytesForInitializedBuckets(capacity)
    let bucketMapBytes = bytesForBucketMap(capacity)
    let keysBytes = bytesForKeys(capacity)
    let valuesBytes = bytesForValues(capacity)
    let requiredCapacity = initializedBucketsBytes
                         + bucketMapBytes
                         + keysBytes
                         + valuesBytes

    let storage = super.create(requiredCapacity) {
      let initializedBucketsStorage = $0.withUnsafeMutablePointerToElements {$0}
      let initializedBuckets = BitMap(uninitializedStorage: pointerCast(initializedBucketsStorage),
                                      bitCount: capacity)
      let bucketMapStorage = initializedBucketsStorage + initializedBucketsBytes
      let bucketMap = HashBucketMap(storage: pointerCast(bucketMapStorage), capacity: capacity)
      let bytesAllocated = $0.allocatedElementCount
      let header =  Header(capacity: capacity,
                           bytesAllocated: bytesAllocated,
                           initializedBuckets: initializedBuckets,
                           bucketMap: bucketMap)
      return header
    }


    return storage as! Storage
  }

  deinit {
    guard count > 0 else { return }

    switch (_isPOD(Key), _isPOD(Value)) {
      case (true, true): return
      case (true, false):
        for offset in initializedBuckets.nonZeroBits { (values + offset).destroy() }
      case (false, true):
        for offset in initializedBuckets.nonZeroBits { (keys + offset).destroy() }
      case (false, false):
        for offset in initializedBuckets.nonZeroBits { (keys + offset).destroy(); (values + offset).destroy() }
    }
  }
}

extension OrderedDictionaryStorage {
  var description: String {
    defer { _fixLifetime(self) }
    var result = "OrderedDictionaryStorage {\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tinitializedBucketsBytes: \(initializedBucketsBytes)\n"
    result += "\tbucketMapBytes: \(bucketMapBytes)\n"
    result += "\tkeysBytes: \(keysBytes)\n"
    result += "\tvaluesBytes: \(valuesBytes)\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tinitializedBuckets: \(initializedBuckets.description.indentedBy(24, preserveFirst: true, useTabs: false))\n"
    result += "\tbucketPositionMap: \(bucketMap)\n"
    result += "\n}"
    return result
  }
}

