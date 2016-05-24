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

  /// Returns the number of bytes required for the map of buckets to positions given `capacity`
  static func bytesForBucketMap(capacity: Int) -> Int {
    return HashBucketMap.wordsFor(capacity)// + max(0, alignof(Int) - alignof(UInt))
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

  /// Pointer to the first byte in memory allocated for the position map
  final var bucketMapAddress: UnsafeMutablePointer<UInt8> {
    return withUnsafeMutablePointerToElements {$0} //initializedBucketsAddress + initializedBucketsBytes
  }

  /// An index mapping buckets to positions and positions to buckets
  final var bucketMap: HashBucketMap { return value.bucketMap }

  var description: String {
    defer { _fixLifetime(self) }
    var result = "HashedStorage {\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tbucketMap: \(bucketMap.debugDescription)\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tbucketMapBytes: \(bucketMapBytes)\n"
    result += "\n}"
    return result
  }
}

protocol ConcreteHashedStorage {
  associatedtype HashedKey: Hashable
  associatedtype HashedValue
  associatedtype Element

  var hashedKeyBaseAddress: UnsafeMutablePointer<HashedKey> { get }
  var hashedValueBaseAddress: UnsafeMutablePointer<HashedValue> { get }

  static func keyForElement(element: Element) -> HashedKey

  func elementAtOffset() -> (Int) -> Element
  func initializeAtOffset() -> (Int, Element) -> Void
  func destroyAtOffset() -> (Int) -> Void
  func moveAtOffset() -> (Int) -> Element
  func updateAtOffset() -> (Int, Element) -> Element

  static func create(minimumCapacity: Int) -> Self
}

/// Specialization of `HashedStorage` for an ordered set
final class OrderedSetStorage<Value:Hashable>: HashedStorage, ConcreteHashedStorage {

  typealias Storage = OrderedSetStorage<Value>
  typealias Header = HashedStorageHeader
  typealias HashedValue = Value
  typealias Element = Value
  typealias HashedKey = Value

  /// Returns the number of bytes required to store the elements for a given `capacity`.
  static func bytesForValues(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Value) - maxPrevAlignment)
    return strideof(Value) * capacity + padding
  }

  /// The number of bytes used to store the elements for this instance
  var valuesBytes: Int { return Storage.bytesForValues(capacity) }

  /// Pointer to the first byte in memory allocated for the hash values
  var values: UnsafeMutablePointer<Value> {
    return UnsafeMutablePointer<Value>(bucketMapAddress + bucketMapBytes)//initializedBucketsAddress + initializedBucketsBytes)
  }

  var hashedKeyBaseAddress: UnsafeMutablePointer<HashedKey> { return values }

  var hashedValueBaseAddress: UnsafeMutablePointer<HashedValue> { return values }

  @inline(__always)
  static func keyForElement(element: Element) -> HashedKey { return element }

  @inline(__always)
  func elementAtOffset() -> (Int) -> Element {
//    let values = self.values
    return {[values = self.values] in
//      defer { _fixLifetime(values) }
      return values[$0]
    }
  }

  func initializeAtOffset() -> (Int, Element) -> Void {
//    let values = self.values
    return {[values = self.values] in
//      defer { _fixLifetime(values) }
      (values + $0).initialize($1)
    }
  }

  func destroyAtOffset() -> (Int) -> Void {
//    let values = self.values
    return {[values = self.values] in
//      defer { _fixLifetime(values) }
      (values + $0).destroy()
    }
  }

  func moveAtOffset() -> (Int) -> Element {
//    let values = self.values
    return {[values = self.values] in
//      defer { _fixLifetime(values) }
      return (values + $0).move()
    }
  }

  func updateAtOffset() -> (Int, Element) -> Element {
//    let values = self.values
    return {[values = self.values] in
//      defer { _fixLifetime(values) }
      let oldValue = (values + $0).move()
      (values + $0).initialize($1)
      return oldValue
    }
  }

  /// Create a new storage instance.
  static func create(minimumCapacity: Int) -> OrderedSetStorage {
    let capacity = round2(minimumCapacity)

    let bucketMapBytes = bytesForBucketMap(capacity)
    let elementsBytes = bytesForValues(capacity)
    let requiredCapacity = bucketMapBytes + elementsBytes

    let storage = super.create(requiredCapacity) {
      let bucketMapStorage = $0.withUnsafeMutablePointerToElements {$0}//initializedBucketsStorage + initializedBucketsBytes
      let bucketMap = HashBucketMap(storage: pointerCast(bucketMapStorage), capacity: capacity)
      let bytesAllocated = $0.allocatedElementCount
      let header =  Header(capacity: capacity,
                           bytesAllocated: bytesAllocated,
                           bucketMap: bucketMap)
      return header
    }

    return storage as! Storage
  }

  deinit {
    guard count > 0 && !_isPOD(Value) else { return }
    defer { _fixLifetime(self) }
    let elements = self.values
    for bucket in bucketMap { (elements + bucket.offset).destroy() }
  }

  override var description: String {
    defer { _fixLifetime(self) }
    var components = "\n".split(super.description)[1..<8]
    components.append("\tvaluesBytes: \(valuesBytes)")
    var result = "OrderedSetStorage {\n"
    result += components.joinWithSeparator("\n")
    result += "\n}"
    return result
  }
}

/// Specialization of `HashedStorage` for an ordered dictionary

final class OrderedDictionaryStorage<Key:Hashable, Value>: HashedStorage, ConcreteHashedStorage {

  typealias Storage = OrderedDictionaryStorage<Key, Value>
  typealias Header = HashedStorageHeader
  typealias Element = (Key, Value)
  typealias HashedKey = Key
  typealias HashedValue = Value

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

  /// Pointer to the first byte in memory allocated for the keys
  var keys: UnsafeMutablePointer<Key> {
    return UnsafeMutablePointer<Key>(bucketMapAddress + bucketMapBytes)//initializedBucketsAddress + initializedBucketsBytes)
  }

  var hashedKeyBaseAddress: UnsafeMutablePointer<HashedKey> { return keys }

  @inline(__always)
  static func keyForElement(element: Element) -> HashedKey { return element.0 }

  /// Pointer to the first byte in memory allocated for the values
  var values: UnsafeMutablePointer<Value> {
    // Conversion back to UInt8 pointer necessary for `+` operator to advance by byte
    return UnsafeMutablePointer<Value>(UnsafeMutablePointer<UInt8>(keys) + keysBytes)
  }

  var hashedValueBaseAddress: UnsafeMutablePointer<HashedValue> { return values }

  @inline(__always)
  func elementAtOffset() -> (Int) -> Element {
//    let keys = self.keys
//    let values = self.values
    return {[keys = self.keys, values = self.values] in
//      defer { _fixLifetime(keys); _fixLifetime(values) }
      return (keys[$0], values[$0])
    }
  }

  func initializeAtOffset() -> (Int, Element) -> Void {
//    let keys = self.keys
//    let values = self.values
    return {[keys = self.keys, values = self.values] in
//      defer { _fixLifetime(keys); _fixLifetime(values) }
      (keys + $0).initialize($1.0)
      (values + $0).initialize($1.1)
    }
  }

  func destroyAtOffset() -> (Int) -> Void {
//    let keys = self.keys
//    let values = self.values
    return {[keys = self.keys, values = self.values] in
//      defer { _fixLifetime(keys); _fixLifetime(values) }
      (keys + $0).destroy()
      (values + $0).destroy()
    }
  }

  func moveAtOffset() -> (Int) -> Element {
//    let keys = self.keys
//    let values = self.values
    return {[keys = self.keys, values = self.values] in
//      defer { _fixLifetime(keys); _fixLifetime(values) }
      return ((keys + $0).move(), (values + $0).move())
    }
  }

  func updateAtOffset() -> (Int, Element) -> Element {
//    let keys = self.keys
//    let values = self.values
    return {[keys = self.keys, values = self.values] in
//      defer { _fixLifetime(keys); _fixLifetime(values) }
      assert(keys[$0] == $1.0, "keys do not match")
      let oldKey = (keys + $0).move()
      (keys + $0).initialize($1.0)
      let oldValue = (values + $0).move()
      (values + $0).initialize($1.1)
      return (oldKey, oldValue)
    }
  }

  /// Create a new storage instance.
  static func create(minimumCapacity: Int) -> OrderedDictionaryStorage {
    let capacity = round2(minimumCapacity)

    let bucketMapBytes = bytesForBucketMap(capacity)
    let keysBytes = bytesForKeys(capacity)
    let valuesBytes = bytesForValues(capacity)
    let requiredCapacity = bucketMapBytes + keysBytes + valuesBytes

    let storage = super.create(requiredCapacity) {
      let bucketMapStorage = $0.withUnsafeMutablePointerToElements {$0}//initializedBucketsStorage + initializedBucketsBytes
      let bucketMap = HashBucketMap(storage: pointerCast(bucketMapStorage), capacity: capacity)
      let bytesAllocated = $0.allocatedElementCount
      let header =  Header(capacity: capacity,
                           bytesAllocated: bytesAllocated,
                           bucketMap: bucketMap)
      return header
    }


    return storage as! Storage
  }

  deinit {
    guard count > 0 else { return }

    let (keys, values) = (self.keys, self.values)
    let offsets = Array(bucketMap.generate())
    print("offsets = \(offsets)")

    switch (_isPOD(Key), _isPOD(Value)) {
      case (true, true): return
      case (true, false):
        for bucket in bucketMap { (values + bucket.offset).destroy() }
      case (false, true):
        for bucket in bucketMap { (keys + bucket.offset).destroy() }
      case (false, false):
        for bucket in bucketMap { (keys + bucket.offset).destroy(); (values + bucket.offset).destroy() }
    }
  }

  override var description: String {
    defer { _fixLifetime(self) }
    var components = "\n".split(super.description)[1..<8]
    components.append("\tkeysBytes: \(keysBytes)")
    components.append("\tvaluesBytes: \(valuesBytes)")
    var result = "OrderedDictionaryStorage {\n"
    result += components.joinWithSeparator("\n")
    result += "\n}"
    return result
  }
}


