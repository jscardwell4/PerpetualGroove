//
//  OrderedDictionary.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/7/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

// MARK: - Storage
// MARK: -
internal struct OrderedDictionaryStorageHeader {
  var count: Int
  let capacity: Int
  let bytesAllocated: Int
  var maxLoadFactorInverse: Double

  init(count: Int = 0, capacity: Int, bytesAllocated: Int, maxLoadFactorInverse: Double = 1 / 0.75) {
    self.count = count
    self.capacity = capacity
    self.bytesAllocated = bytesAllocated
    self.maxLoadFactorInverse = maxLoadFactorInverse
  }
}

internal final class OrderedDictionaryStorage
<Key:Hashable, Value>: ManagedBuffer<OrderedDictionaryStorageHeader, UInt8>
{

  typealias Storage = OrderedDictionaryStorage<Key, Value>

  /**
   bytesForBitMap:

   - parameter capacity: Int

    - returns: Int
  */
  static func bytesForBitMap(capacity: Int) -> Int {
    let numWords = BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) + alignof(UInt)
  }

  var bitMapBytes: Int { return Storage.bytesForBitMap(capacity) }

  /**
   bytesForKeyMap:

   - parameter capacity: Int

    - returns: Int
  */
  static func bytesForKeyMap(capacity: Int) -> Int {

    let padding = max(0, alignof(Int) - alignof(UInt))
    return strideof(Int) * capacity + padding
  }

  var keyMapBytes: Int { return Storage.bytesForKeyMap(capacity) }

  /**
   bytesForKeys:

   - parameter capacity: Int

    - returns: Int
  */
  static func bytesForKeys(capacity: Int) -> Int {

    let maxPrevAlignment = max(alignof(Int), alignof(UInt))
    let padding = max(0, alignof(Key) - maxPrevAlignment)
    return strideof(Key) * capacity + padding
  }

  var keysBytes: Int { return Storage.bytesForKeys(capacity) }

  /**
   bytesForValues:

   - parameter capacity: Int

    - returns: Int
  */
  static func bytesForValues(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(Key), alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Value) - maxPrevAlignment)
    return strideof(Value) * capacity + padding
  }

  var valuesBytes: Int { return Storage.bytesForValues(capacity) }

  var capacity: Int { return value.capacity }

  var count: Int { get { return value.count } set { value.count = newValue } }

  var maxLoadFactorInverse: Double {
    get { return value.maxLoadFactorInverse }
    set { value.maxLoadFactorInverse = newValue }
  }

  var bytesAllocated: Int { return value.bytesAllocated }

  var bitMap: UnsafeMutablePointer<UInt> {
    return UnsafeMutablePointer<UInt>(withUnsafeMutablePointerToElements({$0}))
  }

  var keyMap: UnsafeMutablePointer<Int> {
    return UnsafeMutablePointer<Int>(UnsafePointer<UInt8>(bitMap) + bitMapBytes)
  }

  var keys: UnsafeMutablePointer<Key> {
    return UnsafeMutablePointer<Key>(UnsafePointer<UInt8>(keyMap) + keyMapBytes)
  }

  var values: UnsafeMutablePointer<Value> {
    return UnsafeMutablePointer<Value>(UnsafePointer<UInt8>(keys) + keysBytes)
  }

  /**
   capacityForMinimumCapacity:

   - parameter minimumCapacity: Int

   - returns: Int
   */
  static func capacityForMinimumCapacity(minimumCapacity: Int) -> Int {
    // Make sure there's a representable power of 2 >= minimumCapacity
    assert(minimumCapacity <= (Int.max >> 1) + 1)
    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }
    return capacity
  }

  /**
   create:

   - parameter capacity: Int

    - returns: OrderedDictionaryStorage
  */
  class func create(minimumCapacity: Int) -> OrderedDictionaryStorage {
    let capacity = capacityForMinimumCapacity(minimumCapacity)
    let bitMapBytes = bytesForBitMap(capacity)
    let requiredCapacity = bitMapBytes
                         + bytesForKeys(capacity)
                         + bytesForKeyMap(capacity)
                         + bytesForValues(capacity)

    let storage = super.create(requiredCapacity) {
      $0.withUnsafeMutablePointerToElements {
        BitMap(storage: UnsafeMutablePointer<UInt>($0), bitCount: capacity).initializeToZero()
//        let keyMap = UnsafeMutablePointer<Int>($0 + bitMapBytes)
//        for i in 0 ..< capacity { (keyMap + i).initialize(-1) }
      }
      return OrderedDictionaryStorageHeader(capacity: capacity, bytesAllocated: $0.allocatedElementCount)
    }

    return storage as! Storage
  }



  /**
   clone

    - returns: Storage
  */
  func clone() -> Storage {

    let storage = Storage.create(capacity)

    func initialize<Memory>(target: UnsafeMutablePointer<Memory>,
                       from: UnsafeMutablePointer<Memory>,
                      count: Int)
    {
      UnsafeMutablePointer<UInt8>(target).initializeFrom(UnsafeMutablePointer<UInt8>(from), count: count)
    }

    initialize(storage.bitMap, from: bitMap, count: bitMapBytes)
    initialize(storage.keyMap, from: keyMap, count: keyMapBytes)
    initialize(storage.keys, from: keys, count: keysBytes)
    initialize(storage.values, from: values, count: valuesBytes)
    storage.count = count

    return storage
  }


  deinit {
    defer { _fixLifetime(self) }
    switch (_isPOD(Key), _isPOD(Value)) {
      case (true, true): return
      case (true, false):
        (0 ..< count).map({ keyMap[$0] }).forEach { (values + $0).destroy() }
      case (false, true):
        (0 ..< count).map({ keyMap[$0] }).forEach { (keys + $0).destroy() }
      case (false, false):
        (0 ..< count).map({ keyMap[$0] }).forEach { (keys + $0).destroy()
                                                    (values + $0).destroy() }
    }
//    let capacity = self.capacity
//    let keys = self.keys
//    let values = self.values
//    let bitMap = BitMap(storage: self.bitMap, bitCount: capacity)
//    if !_isPOD(Key) {
//      for bucket in 0 ..< capacity where bitMap[bucket] {
//        (keys + bucket).destroy()
//      }
//    }
//    if !_isPOD(Value) {
//      for bucket in 0 ..< capacity where bitMap[bucket] {
//        (values + bucket).destroy()
//      }
//    }
//    keyMap.destroy(capacity)
//    withUnsafeMutablePointerToValue({$0.destroy()})
  }
}

extension OrderedDictionaryStorage {
  var description: String {
    defer { _fixLifetime(self) }
    let bitMap = BitMap(storage: self.bitMap, bitCount: capacity)
    var bitMapDescription = ""
    for i in 0 ..< capacity {
      let isInitialized = bitMap[i]
      bitMapDescription += isInitialized ? "1" : "0"
    }
    defer { _fixLifetime(bitMap) }
    var result = "OrderedDictionaryStorage {\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tbitMapBytes: \(bitMapBytes)\n"
    result += "\tkeyMapBytes: \(keyMapBytes)\n"
    result += "\tkeysBytes: \(keysBytes)\n"
    result += "\tvaluesBytes: \(valuesBytes)\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tbitMap: \(bitMapDescription)\n"
    result += "\tkeyMap: \(Array(UnsafeBufferPointer(start: keyMap, count: count)))\n"
    result += "\tkeys: \(Array(UnsafeBufferPointer(start: keys, count: count)))\n"
    result += "\tvalues: \(Array(UnsafeBufferPointer(start: values, count: count)))\n"
    result += "\n}"
    return result
  }
}

// MARK: - Generator
// MARK: -

public struct OrderedDictionaryGenerator<Key: Hashable, Value>: GeneratorType {
  internal typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  internal let buffer: Buffer
  internal var index: Int //OrderedDictionaryIndex<Key, Value>
  internal init(buffer: Buffer) {
    self.buffer = buffer
    index = buffer.startIndex
  }
  public mutating func next() -> (Key, Value)? {
    
    guard index < buffer.count else { return nil }
    defer { index = index.successor() }
    return buffer.elementAtPosition(index)
  }
}

// MARK: - Extension of existing types

//extension UnsafeMutablePointer {
//  subscript(position: IntValued) -> Memory {
//    get { return self[position.value] }
//    set { self[position.value] = newValue }
//  }
//}
//
//extension BitMap {
//  subscript(position: IntValued) -> Bool {
//    get { return self[position.value] }
//    set { self[position.value] = newValue }
//  }
//}

// MARK: - Buffer
// MARK: -
public struct OrderedDictionaryBuffer<Key:Hashable, Value>: SequenceType {

  public typealias Index = Int//OrderedDictionaryIndex<Key, Value>
  public typealias Element = (Key, Value)
  public typealias Generator = OrderedDictionaryGenerator<Key, Value>

  internal typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  internal typealias Storage = OrderedDictionaryStorage<Key, Value>
  internal typealias Bucket = Int

  // MARK: Pointers to the underlying memory

  internal var storage: Storage
  internal var bitMap: BitMap
  internal var keys: UnsafeMutablePointer<Key>
  internal var keyMap: UnsafeMutablePointer<Int>
  internal var values: UnsafeMutablePointer<Value>

  // MARK: Accessors for the storage header properties

  public var capacity: Int { return storage.capacity }

  public private(set) var count: Int {
    get { return storage.count }
    nonmutating set { storage.count = newValue }
  }

  var maxLoadFactorInverse: Double {
    get { return storage.maxLoadFactorInverse }
    set { storage.maxLoadFactorInverse = newValue }
  }

  // MARK: Initializing by capacity

  /**
   initWithMinimumCapacity:

   - parameter minimumCapacity: Int = 2
   */
  init(minimumCapacity: Int = 2) {
    storage = Storage.create(Buffer.minimumCapacityForCount(minimumCapacity, 1 / 0.75))
    bitMap = BitMap(storage: storage.bitMap, bitCount: storage.capacity)
    keys = storage.keys
    values = storage.values
    keyMap = storage.keyMap
    _fixLifetime(storage)
  }

  /**
   minimumCapacityForCount:maxLoadFactorInverse:

   - parameter count: Int
   - parameter maxLoadFactorInverse: Double

    - returns: Int
  */
  static func minimumCapacityForCount(count: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

    // MARK: Initializing with data

  /**
   initWithStorage:

   - parameter storage: Storage
  */
  internal init(storage: Storage) {
    self.storage = storage
    bitMap = BitMap(storage: storage.bitMap, bitCount: storage.capacity)
    keyMap = storage.keyMap
    keys = storage.keys
    values = storage.values
  }

  /**
   initWithElements:capacity:

   - parameter elements: [Element]
   - parameter capacity: Int? = nil
  */
  init(elements: [Element], capacity: Int? = nil) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.count, 1 / 0.75)
    let requiredCapacity = max(minimumCapacity, capacity ?? 0)
    let buffer = Buffer(minimumCapacity: requiredCapacity)

    for (position, (key, value)) in elements.enumerate() {
      let (bucket, found) = buffer.find(key)
      precondition(!found, "Dictionary literal contains duplicate keys")
      buffer.initializeKey(key, value: value, position: position, bucket: bucket)
    }
    buffer.count = elements.count

    self = buffer
  }


  // MARK: Queries

  internal var bucketMask: Int { return capacity &- 1 }

  /**
   bucketForKey:

   - parameter key: Key

    - returns: Bucket
  */
  internal func bucketForKey(key: Key) -> Bucket { return _squeezeHashValue(key.hashValue, 0 ..< capacity) }


  /**
   positionForBucket:

   - parameter bucket: Bucket

    - returns: Index
  */
  internal func positionForBucket(bucket: Bucket) -> Index {
    for position in 0 ..< count { guard keyMap[position] != bucket else { return position } }
    return count
  }

  /**
   bucketForPosition:

   - parameter position: Index

    - returns: Bucket
  */
  internal func bucketForPosition(position: Index) -> Bucket { return keyMap[position] }

  /**
   nextBucket:

   - parameter bucket: Bucket

    - returns: Bucket
  */
  internal func nextBucket(bucket: Bucket) -> Bucket { return (bucket &+ 1) & bucketMask }

  /**
   previousBucket:

   - parameter bucket: Bucket

    - returns: Bucket
  */
  internal func previousBucket(bucket: Bucket) -> Bucket { return (bucket &- 1) & bucketMask }

  /**
   find:

   - parameter key: Key

    - returns: (position: Bucket, found: Bool)
  */
  internal func find(key: Key) -> (position: Bucket, found: Bool) {
    
    let startBucket = bucketForKey(key)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard keyInBucket(bucket) != key  else { return (bucket, true)  }
      bucket = nextBucket(bucket)
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }
  /**
   keyInBucket:

   - parameter bucket: Bucket

    - returns: Key
  */
  internal func keyInBucket(bucket: Bucket) -> Key { return keys[bucket] }

  /**
   valueInBucket:

   - parameter bucket: Bucket

    - returns: Value
  */
  internal func valueInBucket(bucket: Bucket) -> Value { return values[bucket] }

  /**
   valueForKey:

   - parameter key: Key

    - returns: Value?
  */
  internal func valueForKey(key: Key) -> Value? {
    guard count > 0 else { return nil }
    let (bucket, found) = find(key)
    return found ? valueInBucket(bucket) : nil
  }

  /**
   elementInBucket:

   - parameter bucket: Bucket

    - returns: Element
  */
  internal func elementInBucket(bucket: Bucket) -> Element { return (keyInBucket(bucket), valueInBucket(bucket)) }

  /**
   elementAtPosition:

   - parameter position: Index

    - returns: Element
  */
  internal func elementAtPosition(position: Index) -> Element {
    return elementInBucket(bucketForPosition(position))
  }

  /**
   isInitializedBucket:

   - parameter index: Index

    - returns: Bool
  */
  internal func isInitializedBucket(bucket: Bucket) -> Bool { return bitMap[bucket] }

  /**
   indexForKey:

   - parameter key: Key

    - returns: Index?
  */
  internal func indexForKey(key: Key) -> Index? {
    guard count > 0 else { return nil }
    let (bucket, found) = find(key)
    guard found else { return nil }
    return positionForBucket(bucket)
  }

  // MARK: Removing data

  /**
   destroyEntryAt:

   - parameter index: Index
  */
  internal func destroyEntryAt(position: Index) {
    defer { _fixLifetime(self) }
    var bucket = bucketForPosition(position)
    var idealBucket = bucketForKey((keys + bucket).move())
    (values + bucket).destroy()
    keyMap[position] = -1
    bitMap[bucket] = false

    let from = keyMap + position + 1
    let moveCount = count - position - 1
    (keyMap + position).moveInitializeFrom(from, count: moveCount)

    //TODO: rework to use position-based bucket checks

    // If we've put a hole in a chain of contiguous elements, some
    // element after the hole may belong where the new hole is.
    var hole = bucket

    // Find the first bucket in the contiguous chain
    var start = idealBucket
    while isInitializedBucket(previousBucket(start)) { start = previousBucket(start) }

    // Find the last bucket in the contiguous chain
    var lastInChain = hole
    bucket = nextBucket(lastInChain)
    while isInitializedBucket(bucket) { lastInChain = bucket; bucket = nextBucket(bucket) }

    // Relocate out-of-place elements in the chain, repeating until
    // none are found.
    while hole != lastInChain {
      // Walk backwards from the end of the chain looking for
      // something out-of-place.
      bucket = lastInChain
      while bucket != hole {
        idealBucket = bucketForKey(keyInBucket(bucket))

        // Does this element belong between start and hole?  We need
        // two separate tests depending on whether [start,hole] wraps
        // around the end of the buffer
        let c0 = idealBucket >= start
        let c1 = idealBucket <= hole
        if start <= hole ? (c0 && c1) : (c0 || c1) {
          break // Found it
        }
        bucket = previousBucket(bucket)
      }

      if bucket == hole { // No out-of-place elements found; we're done adjusting
        break
      }

      // Move the found element into the hole
      (keys + hole).initialize((keys + bucket).move())
      (values + hole).initialize((values + bucket).move())
      bitMap[hole] = true
      bitMap[bucket] = false
      keyMap[positionForBucket(bucket)] = hole
      hole = bucket
    }

    count -= 1
  }

  // MARK: Initializing with data

  /**
   initializeKey:value:position:bucket:

   - parameter key: Key
   - parameter value: Value
   - parameter position: Int
   - parameter bucket: Int
  */
  internal func initializeKey(key: Key, value: Value, position: Int, bucket: Int) {
    defer { _fixLifetime(self) }
//    let r = 0 ..< capacity
//    guard r ∋ bucket else { fatalError("Invalid bucket: \(bucket)") }
//    guard !bitMap[bucket] else { fatalError("Expected uninitialized bucket") }
//    guard r ∋ position else { fatalError("Invalid postion: \(position)") }
    (keys + bucket).initialize(key)
    (values + bucket).initialize(value)
    bitMap[bucket] = true
    (keyMap + position).initialize(bucket)
  }


  /**
   initializeKey:value:at:

   - parameter key: Key
   - parameter value: Value
   - parameter bucket: Bucket
  */
  internal func initializeKey(key: Key, value: Value, bucket: Bucket) {
    initializeKey(key, value: value, position: count, bucket: bucket)
  }

  /**
   uncheckedMoveInitializeFrom:to:forPosition:

   - parameter b1: Int
   - parameter b2: Int
   - parameter p: Int
  */
//  internal func uncheckedMoveInitializeFrom(bucket1: Bucket, to bucket2: Bucket, forPosition position: Index) {
//    (keys + bucket2).initialize((keys + bucket1).move())
//    (values + bucket2).initialize((values + bucket1).move())
//    keyMap[position] = bucket2
//    bitMap[bucket1] = false
//    bitMap[bucket2] = true
//  }

  /**
   moveInitializeFrom:to:forPosition:

   - parameter bucket1: Bucket
   - parameter bucket2: Bucket
   - parameter position: Index
  */
//  internal func moveInitializeFrom(bucket1: Bucket, to bucket2: Bucket, forPosition position: Index) {
//    let r = 0 ..< capacity
//    guard r ∋ bucket1 && bitMap[bucket1] else { fatalError("from bucket invalid or uninitialized: \(bucket1)") }
//    guard r ∋ bucket2 && !bitMap[bucket2] else { fatalError("to bucket invalid or already initialized: \(bucket1)") }
//    guard r ∋ position && keyMap[position] == bucket1 else { fatalError("position invalid: \(position)") }
//    uncheckedMoveInitializeFrom(bucket1, to: bucket2, forPosition: position)
//  }

  /**
   moveInitializeFrom:to:

   - parameter from: Index
   - parameter to: Index
  */
//  internal func moveInitializeFrom(from: Index, to: Index) {
//    uncheckedMoveInitializeFrom(bucketForPosition(from), to: bucketForPosition(to), forPosition: from)
//  }

  // MARK: Assigning into already initialized data

  /**
   setValue:at:

   - parameter value: Value
   - parameter idx: Index
  */
  internal func setValue(value: Value, at position: Index) {
    values[bucketForPosition(position)] = value
  }

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension OrderedDictionaryBuffer : CustomStringConvertible, CustomDebugStringConvertible {
    
  private var elementsDescription: String {
    if count == 0 { return "[:]" }

    var result = "["
    var first = true
    for (key, value) in self {
      if first { first = false } else { result += ", " }
      debugPrint(key, terminator: ": ", toStream: &result)
      debugPrint(value, terminator: "",   toStream: &result)
    }
    result += "]"
    return result
  }

  /// A textual representation of `self`.
  public var description: String { return elementsDescription }

  /// A textual representation of `self`, suitable for debugging.
  public var debugDescription: String {
    var result = elementsDescription + "\n"
    for position in 0 ..< capacity {
      let bucket = keyMap[position]
      if bucket > -1 {
        result += "position \(position) ➞ bucket \(bucket)\n"
      } else {
        result += "position \(position), empty\n"
      }
    }
    for bucket in 0 ..< capacity {
      if isInitializedBucket(bucket) {
        let key = keyInBucket(bucket)
        result += "bucket \(bucket), ideal bucket = \(bucketForKey(key)), key = \(key)\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }
}

// MARK: CollectionType
extension OrderedDictionaryBuffer: CollectionType {

  public typealias _Element = Element

  public var startIndex: Index { return 0 }

  public var endIndex: Index { return count }


  public subscript(position: Index) -> Element {
    return elementInBucket(position)
  }

  public func generate() -> Generator { return Generator(buffer: self) }
}

// MARK: - Index
// MARK: -
//public enum OrderedDictionaryIndex<Key: Hashable, Value>: Comparable {
//  public typealias Buffer = OrderedDictionaryBuffer<Key, Value>
//
//  case Ordered(Int, Buffer)
//  case Hashed (Int, Buffer)
//
//  var buffer: Buffer {
//    switch self {
//      case .Ordered(_, let bucket): return bucket
//      case .Hashed (_, let bucket): return bucket
//    }
//  }
//
//  /**
//   init:buffer:
//
//   - parameter key: Key
//   - parameter buffer: Buffer
//  */
//  internal init(_ key: Key, _ buffer: Buffer) {
//    self = .Hashed(_squeezeHashValue(key.hashValue, 0 ..< buffer.capacity), buffer)
//  }
//
//  internal typealias Index = OrderedDictionaryIndex<Key, Value>
//
//  internal var ordered: Index? {
//    if case .Hashed(let h, let buffer) = self {
//      for i in 0 ..< buffer.count {
//        guard buffer.keyMap[i] != h else { return .Ordered(i, buffer) }
//      }
//      return .Ordered(buffer.count, buffer)
//    } else {
//      return self
//    }
//  }
//
//  internal var orderedInitialized: Index? {
//    if case .Hashed(let h, let buffer) = self {
//      guard buffer.isInitializedEntry(self) else { return nil }
//      for i in 0 ..< buffer.count {
//        guard buffer.keyMap[i] != h else { return .Ordered(i, buffer) }
//      }
//      return nil
//    } else if case .Ordered(let value, let bucket) = self where bucket.count > value {
//      return self
//    } else { return nil }
//  }
//
//  internal var orderedUninitialized: Index? {
//    if case .Hashed(_, let buffer) = self {
//      guard !buffer.isInitializedEntry(self) else { return nil }
//      return .Ordered(buffer.count, buffer)
//    } else if case .Ordered(let value, let bucket) = self where value == bucket.count {
//      return self
//    } else {
//      return nil
//    }
//  }
//
//  internal var hashed: Index? {
//    if case .Ordered(let o, let buffer) = self {
//      guard o < buffer.count else { fatalError("ordered index greater than buffer count") }
//      let h = buffer.keyMap[o]
//      guard (0 ..< buffer.capacity) ∋ h else { return nil }
//      return .Hashed(h, buffer)
//    } else {
//      return self
//    }
//  }
//
//  internal var hashedInitialized: Index? {
//    guard let h = hashed where buffer.isInitializedEntry(h) else { return nil }
//    return h
//  }
//
//  internal var hashedUninitialized: Index? {
//    guard let h = hashed where !buffer.isInitializedEntry(h) else { return nil }
//    return h
//  }
//
//}

// MARK: BidirectionalIndexType
//extension OrderedDictionaryIndex: BidirectionalIndexType {
//  public func successor() -> OrderedDictionaryIndex {
//    switch self {
//      case .Ordered(let i, let buffer): return .Ordered(i.successor(), buffer)
//      case .Hashed (let i, let buffer): return .Hashed (i.successor() & (buffer.capacity &- 1), buffer)
//    }
//  }
//
//  public func predecessor() -> OrderedDictionaryIndex {
//    switch self {
//      case .Ordered(let i, let buffer): return .Ordered(i.predecessor(), buffer)
//      case .Hashed (let i, let buffer): return .Hashed (i.predecessor() & (buffer.capacity &- 1), buffer)
//    }
//  }
//
//}
//
//// MARK: IntValued
//extension OrderedDictionaryIndex: IntValued {
//  public var value: Int {
//    switch self {
//      case .Ordered(let i, _): return i
//      case .Hashed (let i, _): return i
//    }
//  }
//}
//
//// MARK: CustomStringConvertible
//extension OrderedDictionaryIndex: CustomStringConvertible {
//  public var description: String {
//    switch self {
//      case .Ordered(let value, _): return "Ordered(\(value))"
//      case .Hashed(let value, _): return "Hashed(\(value))"
//    }
//  }
//}
//
//// MARK: Comparable and arithemtic functions
//
//public func <<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> Bool {
//  return lhs.value < numericCast(rhs)
//}
//
//public func ><K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> Bool {
//  return lhs.value > numericCast(rhs)
//}
//
//public func <=<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> Bool {
//  return lhs.value <= numericCast(rhs)
//}
//
//public func >=<K, V, T:SignedIntegerType>(lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> Bool {
//  return lhs.value >= numericCast(rhs)
//}
//
//public func <<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
//  return numericCast(lhs) < rhs.value
//}
//
//public func ><K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
//  return numericCast(lhs) > rhs.value
//}
//
//public func <=<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
//  return numericCast(lhs) <= rhs.value
//}
//
//public func >=<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
//  return numericCast(lhs) >= rhs.value
//}
//
//private func compareIndices<K, V>
//  (lhs: OrderedDictionaryIndex<K, V>,
//   rhs: OrderedDictionaryIndex<K, V>,
//   operation: (Int, Int) -> Bool) -> Bool
//{
//  if case .Hashed = lhs {
//    guard let rhsHashed = rhs.hashed else { return false }
//    return operation(lhs.value, rhsHashed.value)
//  } else {
//    guard let rhsOrdered = rhs.ordered else { return false }
//    return operation(lhs.value, rhsOrdered.value)
//  }
//}
//public func <<K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
//  return compareIndices(lhs, rhs: rhs, operation: <)
//}
//
//public func ><K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
//  return compareIndices(lhs, rhs: rhs, operation: >)
//}
//
//public func <=<K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
//  return compareIndices(lhs, rhs: rhs, operation: <=)
//}
//
//public func >=<K, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
//  return compareIndices(lhs, rhs: rhs, operation: >=)
//}
//
//public func +<K, V, Memory>
//  (lhs: UnsafeMutablePointer<Memory>, rhs: OrderedDictionaryIndex<K, V>) -> UnsafeMutablePointer<Memory>
//{
//  return lhs + rhs.value
//}
//
//public func +<K, V, Memory>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Memory>
//{
//  return rhs + lhs
//}
//
//public func -<K, V, Memory>
//  (lhs: UnsafeMutablePointer<Memory>, rhs: OrderedDictionaryIndex<K, V>) -> UnsafeMutablePointer<Memory>
//{
//  return lhs - rhs.value
//}
//public func -<K, V, Memory>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: UnsafeMutablePointer<Memory>) -> UnsafeMutablePointer<Memory>
//{
//  
//  return rhs - lhs
//}
//
//public func +<K, V, Memory>
//  (lhs: UnsafePointer<Memory>, rhs: OrderedDictionaryIndex<K, V>) -> UnsafePointer<Memory>
//{
//  return lhs + rhs.value
//}
//
//public func +<K, V, Memory>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: UnsafePointer<Memory>) -> UnsafePointer<Memory>
//{
//  return rhs + lhs
//}
//
//public func -<K, V, Memory>
//  (lhs: UnsafePointer<Memory>, rhs: OrderedDictionaryIndex<K, V>) -> UnsafePointer<Memory>
//{
//  return lhs - rhs.value
//}
//public func -<K, V, Memory>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: UnsafePointer<Memory>) -> UnsafePointer<Memory>
//{
//  return rhs - lhs
//}
//
//public func +<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
//  return lhs + numericCast(rhs.value)
//}
//
//public func +<K, V, T:SignedIntegerType>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V>
//{
//  switch lhs {
//    case let .Ordered(value, bucket): return .Ordered(value + numericCast(rhs), bucket)
//    case let .Hashed(value, bucket):  return .Hashed(value + numericCast(rhs), bucket)
//  }
//}
//
//public func -<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
//  return lhs - numericCast(rhs.value)
//}
//public func -<K, V, T:SignedIntegerType>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V>
//{
//  switch lhs {
//    case let .Ordered(value, bucket): return .Ordered(value - numericCast(rhs), bucket)
//    case let .Hashed(value, bucket):  return .Hashed(value - numericCast(rhs), bucket)
//  }
//}
//
//public func &<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
//  return lhs & numericCast(rhs.value)
//}
//
//public func &<K, V, T:SignedIntegerType>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V>
//{
//  switch lhs {
//    case let .Ordered(value, bucket): return .Ordered(value & numericCast(rhs), bucket)
//    case let .Hashed(value, bucket):  return .Hashed(value & numericCast(rhs), bucket)
//  }
//}
//
//public func |<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
//  return lhs | numericCast(rhs.value)
//}
//
//public func |<K, V, T:SignedIntegerType>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V>
//{
//  switch lhs {
//    case let .Ordered(value, bucket): return .Ordered(value | numericCast(rhs), bucket)
//    case let .Hashed(value, bucket):  return .Hashed(value | numericCast(rhs), bucket)
//  }
//}
//
//public func &+<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
//  return lhs &+ numericCast(rhs.value)
//}
//
//public func &+<K, V, T:SignedIntegerType>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V>
//{
//  switch lhs {
//    case let .Ordered(value, bucket): return .Ordered(value &+ numericCast(rhs), bucket)
//    case let .Hashed(value, bucket):  return .Hashed(value &+ numericCast(rhs), bucket)
//  }
//}
//
//public func &-<K, V, T:SignedIntegerType>(lhs: T, rhs: OrderedDictionaryIndex<K, V>) -> T {
//  return lhs &- numericCast(rhs.value)
//}
//
//public func &-<K, V, T:SignedIntegerType>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: T) -> OrderedDictionaryIndex<K, V>
//{
//  switch lhs {
//    case let .Ordered(value, bucket): return .Ordered(value &- numericCast(rhs), bucket)
//    case let .Hashed(value, bucket):  return .Hashed(value &- numericCast(rhs), bucket)
//  }
//}
//
//public func ==<K:Hashable, V>
//  (lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool
//{
//  switch (lhs, rhs) {
//    case (.Ordered(let v1, let buffer1), .Ordered(let v2, let buffer2))
//      where v1 == v2 && buffer1.storage === buffer2.storage:
//      return true
//    case (.Hashed(let v1, let buffer1), .Hashed(let v2, let buffer2))
//      where v1 == v2 && buffer1.storage === buffer2.storage:
//      return true
//    default: return false
//  }
//}

// MARK: - Owner
// MARK: -

internal final class OrderedDictionaryStorageOwner<Key: Hashable, Value>: NonObjectiveCBase {

  typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  var buffer: Buffer
  init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }
  init(buffer: Buffer) { self.buffer = buffer }
}

// MARK: - OrderedDictionary
// MARK: -

/// A hash-based mapping from `Key` to `Value` instances that preserves elment order.
public struct OrderedDictionary<Key: Hashable, Value>: CollectionType, DictionaryLiteralConvertible {

  public typealias Index = Int//OrderedDictionaryIndex<Key, Value>
  public typealias Generator = OrderedDictionaryGenerator<Key, Value>
  public typealias Element = (Key, Value)
  public typealias _Element = Element
  internal typealias Storage = OrderedDictionaryStorage<Key, Value>
  internal typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  internal typealias Owner = OrderedDictionaryStorageOwner<Key, Value>

  internal var buffer: Buffer {
    get { return owner.buffer }
    set { owner.buffer = newValue }
  }

  internal var owner: Owner

  /**
   ensureUniqueWithCapacity:

   - parameter minimumCapacity: Int

    - returns: (reallocated: Bool, capacityChanged: Bool)
  */
  internal mutating func ensureUniqueWithCapacity(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool)
  {
    
    if capacity >= minimumCapacity {
      guard !isUniquelyReferenced(&owner) else { return(reallocated: false, capacityChanged: false) }
      owner = Owner(buffer: Buffer(storage: buffer.storage.clone()))
      return (reallocated: true, capacityChanged: false)
    }

    let newBuffer = Buffer(minimumCapacity: minimumCapacity)
    for (position, (key, value)) in buffer.enumerate() {
      let (bucket, _) = newBuffer.find(key)
      newBuffer.initializeKey(key, value: value, position: position, bucket: bucket)
    }
    newBuffer.count = buffer.count
    owner = Owner(buffer: newBuffer)
    return (reallocated: true, capacityChanged: true)

  }

  /// Create an empty dictionary.
  public init() { owner = Owner(minimumCapacity: 0) }

  /**
   initWithMinimumCapacity:

   - parameter minimumCapacity: Int
  */
  public init(minimumCapacity: Int) { owner = Owner(minimumCapacity: minimumCapacity) }

  /**
   initWithBuffer:

   - parameter buffer: Buffer
  */
  internal init(buffer: Buffer) { owner = Owner(buffer: buffer) }

  public var startIndex: Index { return buffer.startIndex }

  public var endIndex: Index { return buffer.endIndex }

  /**
   indexForKey:

   - parameter key: Key

    - returns: Index?
  */
  public func indexForKey(key: Key) -> Index? { return buffer.indexForKey(key) }

  /**
   subscript:

   - parameter position: Index

    - returns: (Key, Value)
  */
  public subscript(position: Index) -> (Key, Value) { return buffer.elementAtPosition(position) }

  /**
   subscript:

   - parameter position: Int

    - returns: Value
  */
//  public subscript(position: Int) -> Value {
//    get {
//      guard let h = Index.Ordered(position, buffer).hashedInitialized else {
//        fatalError("Index out of bounds: \(position)")
//      }
//      return buffer.valueAt(h)
//    }
//    set {
//      guard let h = Index.Ordered(position, buffer).hashedInitialized else {
//        fatalError("Index out of bounds: \(position)")
//      }
//      buffer.setValue(newValue, at: h)
//    }
//  }

  /**
   subscript:

   - parameter key: Key

    - returns: Value?
  */
  public subscript(key: Key) -> Value? {
    get { return buffer.valueForKey(key) }
    set {
      if let value = newValue { _updateValue(value, forKey: key, oldValue: nil, oldKey: nil) }
      else { _removeValueForKey(key, oldValue: nil) }
    }
  }

  /**
   _updateValue:forKey:oldValue:oldKey:

   - parameter value: Value
   - parameter key: Key
   - parameter oldValue: UnsafeMutablePointer<Value?>
   - parameter oldKey: UnsafeMutablePointer<Key?>
  */
  internal mutating func _updateValue(value: Value,
                              forKey key: Key,
                            oldValue: UnsafeMutablePointer<Value?>,
                              oldKey: UnsafeMutablePointer<Key?>)
  {
    let (bucket, found) = buffer.find(key)

    if oldValue != nil || oldKey != nil {
      if found {
        let (key, value) = buffer.elementInBucket(bucket)
        if oldKey != nil { oldKey.initialize(key) }
        if oldValue != nil { oldValue.initialize(value) }
      } else {
        if oldKey != nil { oldKey.initialize(nil) }
        if oldValue != nil { oldValue.initialize(nil) }
      }
    }

    let minCapacity = found
      ? capacity
      : Buffer.minimumCapacityForCount(buffer.count + 1, buffer.maxLoadFactorInverse)

    ensureUniqueWithCapacity(minCapacity)

    if found {
      buffer.setValue(value, at: bucket)
    } else {
      buffer.initializeKey(key, value: value, bucket: bucket)
      buffer.count += 1
    }
  }

  /**
   updateValue:forKey:

   - parameter value: Value
   - parameter key: Key

    - returns: Value?
  */
  public mutating func updateValue(value: Value, forKey key: Key) -> Value? {
    let oldValue = UnsafeMutablePointer<Value?>.alloc(1)
    _updateValue(value, forKey: key, oldValue: oldValue, oldKey: nil)
    return oldValue.memory
  }

  /**
   _removeAtIndex:oldElement:

   - parameter index: Index
   - parameter oldElement: UnsafeMutablePointer<Element>
  */
  internal mutating func _removeAtIndex(index: Index, oldElement: UnsafeMutablePointer<Element>) {
    if oldElement != nil { oldElement.initialize(buffer.elementInBucket(index)) }
    ensureUniqueWithCapacity(capacity)
    buffer.destroyEntryAt(index)
  }

  /**
   removeAtIndex:

   - parameter index: Index

    - returns: (Key, Value)
  */
  public mutating func removeAtIndex(index: Index) -> (Key, Value) {
    let oldElement = UnsafeMutablePointer<Element>.alloc(1)
    _removeAtIndex(index, oldElement: oldElement)
    return oldElement.memory
  }

  /**
   _removeValueForKey:oldValue:

   - parameter key: Key
   - parameter oldValue: UnsafeMutablePointer<Value?>
  */
  internal mutating func _removeValueForKey(key: Key, oldValue: UnsafeMutablePointer<Value?>) {
    guard let index = buffer.indexForKey(key) else {
      if oldValue != nil { oldValue.initialize(nil) }
      return
    }
    if oldValue != nil {
      let oldElement = UnsafeMutablePointer<Element>.alloc(1)
      _removeAtIndex(index, oldElement: oldElement)
      oldValue.initialize(oldElement.memory.1)
    } else {
      _removeAtIndex(index, oldElement: nil)
    }
  }

  /**
   removeValueForKey:

   - parameter key: Key

    - returns: Value?
  */
  public mutating func removeValueForKey(key: Key) -> Value? {
    let oldValue = UnsafeMutablePointer<Value?>.alloc(1)
    _removeValueForKey(key, oldValue: oldValue)
    return oldValue.memory
  }

  /**
   removeAll:

   - parameter keepCapacity: Bool = false
  */
  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {

    guard isUniquelyReferenced(&owner) else {
      owner = Owner(minimumCapacity: keepCapacity ? capacity : 0)
      return
    }

    guard keepCapacity else { owner.buffer = Buffer(minimumCapacity: 0); return }

    for i in startIndex ..< endIndex { buffer.destroyEntryAt(i) }
    buffer.count = 0
  }

  /// The number of entries in the dictionary.
  ///
  /// - Complexity: O(1).
  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  /**
   generate

    - returns: Generator<Key, Value>
  */
  public func generate() -> Generator { return Generator(buffer: buffer) }

  /**
   init:

   - parameter elements: Element...
  */
  public init(dictionaryLiteral elements: Element...) {
    self.init(buffer: Buffer(elements: elements))
  }

  public var keys: LazyMapCollection<OrderedDictionary<Key, Value>, Key> {
    return lazy.map { $0.0 }
  }

  public var values: LazyMapCollection<OrderedDictionary<Key, Value>, Value> {
    return lazy.map { $0.1 }
  }

  public var isEmpty: Bool { return count == 0 }

}

extension OrderedDictionary: CustomStringConvertible, CustomDebugStringConvertible {
  /**
   _makeDescription

    - returns: String
  */
  private var elementsDescription: String {
    guard count > 0 else { return "[:]" }

    var result = "["
    var first = true
    for (key, value) in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(key, terminator: "", toStream: &result)
      result += ": "
      debugPrint(value, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  /// A textual representation of `self`.
  public var description: String { return elementsDescription }
  
  /// A textual representation of `self`, suitable for debugging.
  public var debugDescription: String { return elementsDescription }
}

public func == <Key: Hashable, Value: Equatable>
  (lhs: OrderedDictionary<Key, Value>, rhs: OrderedDictionary<Key, Value>) -> Bool
{
    
  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }
  
  for ((k1, v1), (k2, v2)) in zip(lhs, rhs) {
    guard k1 == k2 && v1 == v2 else { return false }
  }
  
  return true
}
