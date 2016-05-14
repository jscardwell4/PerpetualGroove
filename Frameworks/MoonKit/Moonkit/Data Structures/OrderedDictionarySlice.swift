//
//  OrderedDictionarySlice.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public struct OrderedDictionarySlice<Key:Hashable, Value>: _OrderedDictionary, _DestructorSafeContainer {

  typealias Buffer = OrderedDictionarySliceBuffer<Key, Value>
  typealias Storage = OrderedDictionaryStorage<Key, Value>

  public typealias Index = Int
  public typealias Element = (Key, Value)
  public typealias _Element = Element
  public typealias SubSequence = OrderedDictionarySlice<Key, Value>

  var buffer: Buffer

  var capacity: Int { return buffer.capacity }

  public var startIndex: Int { return buffer.startIndex }
  public var endIndex: Int  { return buffer.endIndex }

  /// Returns a new buffer backed by storage cloned from the existing buffer.
  /// Unreachable elements are not copied; however, `startIndex` and `endIndex` values are preserved.
  func cloneBuffer(newCapacity: Int) -> Buffer {
    let clone = Buffer(minimumCapacity: newCapacity)

    // When storage capacity has not changed, simply copy elements into the clone
    if clone.storage.capacity == buffer.storage.capacity {
      for position in buffer.indices {
        let bucket = buffer.bucketForPosition(position)
        let (key, value) = buffer.elementInBucket(bucket)
        clone.initializeKey(key, forValue: value, position: position, bucket: bucket)
      }
    }

    // Otherwise let the clone determine which buckets are filled.
    else {
      for position in buffer.indices {
        let bucket = buffer.bucketForPosition(position)
        let (key, value) = buffer.elementInBucket(bucket)
        clone.initializeKey(key, forValue: value, position: position)
      }
    }

    return clone
  }

  /// Checks that `owner` has only the one strong reference and that it's `buffer` has at least `minimumCapacity` capacity
  mutating func ensureUniqueWithCapacity(minimumCapacity: Int) -> (reallocated: Bool, capacityChanged: Bool) {
    switch (isUnique: buffer.isUniquelyReferenced(), hasCapacity: capacity >= minimumCapacity) {

      case (isUnique: true, hasCapacity: true):
        return (reallocated: false, capacityChanged: false)

      case (isUnique: true, hasCapacity: false):
        buffer = cloneBuffer(Buffer.minimumCapacityForCount(minimumCapacity))
        return (reallocated: true, capacityChanged: true)

      case (isUnique: false, hasCapacity: true):
        buffer = cloneBuffer(capacity)
        return (reallocated: true, capacityChanged: false)

      case (isUnique: false, hasCapacity: false):
        buffer = cloneBuffer(Buffer.minimumCapacityForCount(minimumCapacity))
        return (reallocated: true, capacityChanged: true)
    }

  }

  public subscript(key: Key) -> Value? {
    get { return buffer.valueForKey(key) }
    set {
      //TODO: Implement the function
      fatalError("\(#function) not yet implemented")
    }
  }

  public subscript(position: Index) -> Element {
    get { return buffer[position] }
    set {
      //TODO: Implement the function
      fatalError("\(#function) not yet implemented")
    }
  }

  public subscript(subRange: Range<Index>) -> SubSequence {
    get {
      precondition(indices.contains(subRange))
      return SubSequence(buffer: buffer[subRange])
    }
    set {
      //TODO: Implement the function
      fatalError("\(#function) not yet implemented")
    }
  }

  init(buffer: Buffer) { self.buffer = buffer }

  public func insertValue(value: Value, forKey key: Key) {
    //TODO: Implement the function
    fatalError("\(#function) not yet implemented")
  }

  public func removeValueForKey(key: Key) -> Value? {
    //TODO: Implement the function
    fatalError("\(#function) not yet implemented")
  }

  public func updateValue(value: Value, forKey key: Key) -> Value? {
    //TODO: Implement the function
    fatalError("\(#function) not yet implemented")
  }

  public func indexForKey(key: Key) -> Index? { return buffer.positionForKey(key) }

  public func valueForKey(key: Key) -> Value? {
    //TODO: Implement the function
    fatalError("\(#function) not yet implemented")
  }

}

extension OrderedDictionarySlice: RangeReplaceableCollectionType {

  public init() { buffer = Buffer() }

  public mutating func replaceRange<
    C:CollectionType where C.Generator.Element == Element
    >(subRange: Range<Index>, with newElements: C)
  {
    //TODO: Implement the function
    fatalError("\(#function) not yet implemented")
  }

}


extension OrderedDictionarySlice: CustomStringConvertible {
  public var description: String {
    guard count > 0 else { return "[:]" }

    var result = "["
    var first = true
    for (key, value) in self {
      if first { first = false } else { result += ", " }
      debugPrint(key, terminator: "", toStream: &result)
      result += ": "
      debugPrint(value, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }
}

