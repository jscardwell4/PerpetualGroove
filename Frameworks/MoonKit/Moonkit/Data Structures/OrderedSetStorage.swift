//
//  OrderedSetStorage.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

final class OrderedSetStorage<Element:Hashable>: ManagedBuffer<HashedStorageHeader, UInt8> {

  typealias Storage = OrderedSetStorage<Element>
  typealias Header = HashedStorageHeader

  /// Returns the number of bytes required for the bit map of initialized buckets given `capacity`
  static func bytesForInitializedBuckets(capacity: Int) -> Int {
    return BitMap.wordsFor(capacity) * sizeof(UInt) + alignof(UInt)
  }

  /// The number of bytes used to store the bit map of initialized buckets for this instance
  var initializedBucketsBytes: Int { return Storage.bytesForInitializedBuckets(capacity) }

  /// Returns the number of bytes required for the map of buckets to positions given `capacity`
  static func bytesForBucketMap(capacity: Int) -> Int {
    return HashBucketMap.bytesFor(capacity) + max(0, alignof(Int) - alignof(UInt))
  }

  /// The number of bytes used to store the bucket map for this instance.
  var bucketMapBytes: Int { return Storage.bytesForBucketMap(capacity) }

  /// Returns the number of bytes required to store the elements for a given `capacity`.
  static func bytesForElements(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Element) - maxPrevAlignment)
    return strideof(Element) * capacity + padding
  }

  /// The number of bytes used to store the elements for this instance
  var elementsBytes: Int { return Storage.bytesForElements(capacity) }

  /// The total number of buckets
  var capacity: Int { return value.capacity }

  /// The total number of initialized buckets
  var count: Int { get { return value.count } set { value.count = newValue } }

  /// The total number of bytes managed by this instance; equal to 
  /// `initializedBucketsBytes + bucketMapBytes + membersBytes`
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

  /// Pointer to the first byte in memory allocated for the hash values
  var elements: UnsafeMutablePointer<Element> {
    return UnsafeMutablePointer<Element>(bucketMapAddress + bucketMapBytes)
  }

  /// Create a new storage instance.
  static func create(minimumCapacity: Int) -> OrderedSetStorage {
    let capacity = round2(minimumCapacity)

    let initializedBucketsBytes = bytesForInitializedBuckets(capacity)
    let bucketMapBytes = bytesForBucketMap(capacity)
    let elementsBytes = bytesForElements(capacity)
    let requiredCapacity = initializedBucketsBytes
                         + bucketMapBytes
                         + elementsBytes

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

//  deinit {
//    guard count > 0 && !_isPOD(Element) else { return }
//    defer { _fixLifetime(self) }
//    let elements = self.elements
//    for offset in initializedBuckets.nonZeroBits { (elements + offset).destroy() }
//  }
}

extension OrderedSetStorage {
  var description: String {
    defer { _fixLifetime(self) }
    var result = "OrderedSetStorage {\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tinitializedBucketsBytes: \(initializedBucketsBytes)\n"
    result += "\tbucketMapBytes: \(bucketMapBytes)\n"
    result += "\telementsBytes: \(elementsBytes)\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tinitializedBuckets: \(initializedBuckets)\n"
    result += "\tbucketPositionMap: \(bucketMap)\n"
    result += "\n}"
    return result
  }
}

