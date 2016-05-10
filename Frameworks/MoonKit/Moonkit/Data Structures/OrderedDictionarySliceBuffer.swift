//
//  OrderedDictionarySliceBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/7/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct OrderedDictionarySliceBuffer<Key:Hashable, Value>: _OrderedDictionaryBuffer {

  typealias Index = Int
  typealias Element = (Key, Value)
  typealias _Element = Element
  typealias Storage = OrderedDictionaryStorage<Key, Value>
  typealias SubSequence = OrderedDictionarySliceBuffer<Key, Value>
  typealias Buffer = OrderedDictionaryBuffer<Key, Value>

  private(set) var storage: Storage
  private(set) var initializedBuckets: BitMap
  private(set) var bucketMap: HashBucketMap
  private(set) var keysBaseAddress: UnsafeMutablePointer<Key>
  private(set) var valuesBaseAddress: UnsafeMutablePointer<Value>

  private(set) var startIndex: Index
  private(set) var endIndex: Index

  var count: Int { return endIndex - startIndex }
  var capacity: Int { return count + (storage.capacity - storage.count) }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(initializedBuckets.buffer.baseAddress) }

  static func minimumCapacityForCount(count: Int) -> Int {
    fatalError("\(#function) not yet implemented")
  }

  var buffer: Buffer { return Buffer(storage: storage) }

  mutating func isUniquelyReferenced() -> Bool { return Swift.isUniquelyReferenced(&storage) }

  func valueForKey(key: Key) -> Value? {
    fatalError("\(#function) not yet implemented")
  }

  init(storage: Storage, indices: Range<Index>) {
    self.storage = storage
    initializedBuckets = storage.initializedBuckets
    bucketMap = storage.bucketMap
    keysBaseAddress = storage.keys
    valuesBaseAddress = storage.values

    startIndex = indices.startIndex
    endIndex = indices.endIndex
  }

  init() {
    fatalError("\(#function) not yet implemented")
  }

  mutating func replaceRange<
    C:CollectionType where C.Generator.Element == Element
    >(subRange: Range<Index>, with newElements: C)
  {
    fatalError("\(#function) not yet implemented")
  }
  subscript(index: Index) -> Element {
    get {
      let offset = bucketMap[index].offset
      return (keysBaseAddress[offset], valuesBaseAddress[offset])
    }
    set {
      fatalError("\(#function) not yet implemented")
    }
  }

  subscript(subRange: Range<Index>) -> SubSequence {
    get {
      return SubSequence(storage: storage, indices: subRange)
    }
    set {
      fatalError("\(#function) not implemented")
    }
  }
}