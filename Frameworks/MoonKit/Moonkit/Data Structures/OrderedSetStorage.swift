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
    return strideof(Int) * (capacity * 2) + max(0, alignof(Int) - alignof(UInt))
  }

  var bucketMapBytes: Int { return Storage.bytesForBucketMap(capacity) }

  static func bytesForMembers(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Element) - maxPrevAlignment)
    return strideof(Element) * capacity + padding
  }

  /// The number of bytes used to store the hash values for this instance
  var membersBytes: Int { return Storage.bytesForMembers(capacity) }

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
  var members: UnsafeMutablePointer<Element> {
    return UnsafeMutablePointer<Element>(bucketMapAddress + bucketMapBytes)
  }

  static func create(minimumCapacity: Int) -> OrderedSetStorage {
    let capacity = round2(minimumCapacity)

    let initializedBucketsBytes = bytesForInitializedBuckets(capacity)
    let bucketMapBytes = bytesForBucketMap(capacity)
    let membersBytes = bytesForMembers(capacity)
    let requiredCapacity = initializedBucketsBytes
                         + bucketMapBytes
                         + membersBytes

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
    guard !_isPOD(Element) else { return }
    defer { _fixLifetime(self) }
    let members = self.members
    for offset in initializedBuckets.nonZeroBits { (members + offset).destroy() }
  }
}

extension OrderedSetStorage {
  var description: String {
    defer { _fixLifetime(self) }
    var result = "OrderedSetStorage {\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tinitializedBucketsBytes: \(initializedBucketsBytes)\n"
    result += "\tbucketMapBytes: \(bucketMapBytes)\n"
    result += "\tmembersBytes: \(membersBytes)\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tinitializedBuckets: \(initializedBuckets)\n"
    result += "\tbucketPositionMap: \(bucketMap)\n"
    result += "\n}"
    return result
  }
}

