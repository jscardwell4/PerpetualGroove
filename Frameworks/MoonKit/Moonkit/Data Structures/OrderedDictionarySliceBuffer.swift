//
//  OrderedDictionarySliceBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/7/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct OrderedDictionarySliceBuffer<Key:Hashable, Value>: CollectionType {

  typealias Index = Int
  typealias Element = (Key, Value)
  typealias Storage = OrderedDictionaryStorage<Key, Value>
  typealias SubSequence = OrderedDictionarySliceBuffer<Key, Value>
  typealias Buffer = OrderedDictionaryBuffer<Key, Value>

  private(set) var storage: Storage
  private(set) var initializedBuckets: BitMap
  private(set) var bucketMap: HashBucketMap
  private(set) var keys: UnsafeMutablePointer<Key>
  private(set) var values: UnsafeMutablePointer<Value>

  private(set) var startIndex: Index
  private(set) var endIndex: Index

  var count: Int { return endIndex - startIndex }
  var capacity: Int { return count + (storage.capacity - storage.count) }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(initializedBuckets.buffer.baseAddress) }

  var buffer: Buffer { return Buffer(storage: storage) }

  mutating func isUniquelyReferenced() -> Bool { return Swift.isUniquelyReferenced(&storage) }

  init(storage: Storage, indices: Range<Index>) {
    self.storage = storage
    initializedBuckets = storage.initializedBuckets
    bucketMap = storage.bucketMap
    keys = storage.keys
    values = storage.values

    startIndex = indices.startIndex
    endIndex = indices.endIndex
  }

  subscript(index: Index) -> Element {
    let offset = bucketMap[index].offset
    return (keys[offset], values[offset])
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