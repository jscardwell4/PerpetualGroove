//
//  OrderedSetStorage.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

final class OrderedSetStorage<Element:Hashable>: HashedStorage {

  typealias Storage = OrderedSetStorage<Element>
  typealias Header = HashedStorageHeader

  /// Returns the number of bytes required to store the elements for a given `capacity`.
  static func bytesForElements(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Element) - maxPrevAlignment)
    return strideof(Element) * capacity + padding
  }

  /// The number of bytes used to store the elements for this instance
  var elementsBytes: Int { return Storage.bytesForElements(capacity) }

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

  deinit {
    guard count > 0 && !_isPOD(Element) else { return }
    defer { _fixLifetime(self) }
    let elements = self.elements
    for offset in initializedBuckets.nonZeroBits { (elements + offset).destroy() }
  }

  override var description: String {
    defer { _fixLifetime(self) }
    var components = "\n".split(super.description)[1..<8]
    components.append("\telementsBytes: \(elementsBytes)")
    var result = "OrderedSetStorage {\n"
    result += components.joinWithSeparator("\n")
    result += "\n}"
    return result
  }
}

