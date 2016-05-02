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

  static func bytesForBitMap(capacity: Int) -> Int {
    let numWords = BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) + alignof(UInt)
  }

  var bitMapBytes: Int { return Storage.bytesForBitMap(capacity) }

  static func bytesForKeyMap(capacity: Int) -> Int {

    let padding = max(0, alignof(Int) - alignof(UInt))
    return strideof(Int) * capacity + padding
  }

  var keyMapBytes: Int { return Storage.bytesForKeyMap(capacity) }

  static func bytesForKeys(capacity: Int) -> Int {

    let maxPrevAlignment = max(alignof(Int), alignof(UInt))
    let padding = max(0, alignof(Key) - maxPrevAlignment)
    return strideof(Key) * capacity + padding
  }

  var keysBytes: Int { return Storage.bytesForKeys(capacity) }

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

  static func capacityForMinimumCapacity(minimumCapacity: Int) -> Int {
    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }
    return capacity
  }

  static func create(minimumCapacity: Int) -> OrderedDictionaryStorage {
    let capacity = capacityForMinimumCapacity(minimumCapacity)
    let bitMapBytes = bytesForBitMap(capacity)
    let requiredCapacity = bitMapBytes
                         + bytesForKeys(capacity)
                         + bytesForKeyMap(capacity)
                         + bytesForValues(capacity)

    let storage = super.create(requiredCapacity) {
      $0.withUnsafeMutablePointerToElements {
        let keyMap = UnsafeMutablePointer<Int>($0 + bitMapBytes)
        for i in 0 ..< capacity { (keyMap + i).initialize(-1) }
      }
      return OrderedDictionaryStorageHeader(capacity: capacity, bytesAllocated: $0.allocatedElementCount)
    }

    return storage as! Storage
  }

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
    let count = self.count
    let keyMap = self.keyMap
    let keys = self.keys
    let values = self.values
    switch (_isPOD(Key), _isPOD(Value)) {
      case (true, true): return
      case (true, false):
        for i in 0 ..< count {
          let h = keyMap[i]
          (values + h).destroy()
        }
      case (false, true):
        for i in 0 ..< count {
          let h = keyMap[i]
          (keys + h).destroy()
        }
      case (false, false):
        for i in 0 ..< count {
          let h = keyMap[i]
          (keys + h).destroy()
          (values + h).destroy()
        }
    }
  }
}

extension OrderedDictionaryStorage {
  var description: String {
    defer { _fixLifetime(self) }
    let bitMap = BitMap(initializedStorage: self.bitMap, bitCount: capacity)
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
  internal var index: Int = 0
  internal init(buffer: Buffer) { self.buffer = buffer }
    
  public mutating func next() -> (Key, Value)? {
    guard index < buffer.count else { return nil }
    defer { index = index.successor() }
    return buffer.elementAtPosition(index)
  }
}

internal struct OrderedDictionaryBuffer<Key:Hashable, Value> {

  internal typealias Index = Int
  internal typealias Element = (Key, Value)
  internal typealias Generator = OrderedDictionaryGenerator<Key, Value>

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

  internal var capacity: Int { return storage.capacity }

  internal var count: Int {
    get { return storage.count }
    nonmutating set { storage.count = newValue }
  }

  internal var maxLoadFactorInverse: Double {
    get { return storage.maxLoadFactorInverse }
    set { storage.maxLoadFactorInverse = newValue }
  }

  // MARK: Initializing by capacity

  internal init(minimumCapacity: Int = 2) {
    storage = Storage.create(Buffer.minimumCapacityForCount(minimumCapacity, 1 / 0.75))
    bitMap = BitMap(uninitializedStorage: storage.bitMap, bitCount: storage.capacity)
    keys = storage.keys
    values = storage.values
    keyMap = storage.keyMap
    _fixLifetime(storage)
  }

  internal static func minimumCapacityForCount(count: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  // MARK: Initializing with data

  internal init(storage: Storage) {
    self.storage = storage
    bitMap = BitMap(initializedStorage: storage.bitMap, bitCount: storage.capacity)
    keyMap = storage.keyMap
    keys = storage.keys
    values = storage.values
  }

  internal init(elements: [Element], capacity: Int? = nil) {
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
  internal func bucketForKey(key: Key) -> Bucket { return _squeezeHashValue(key.hashValue, 0 ..< capacity) }

  internal func positionForBucket(bucket: Bucket) -> Index {
    for position in 0 ..< count { guard keyMap[position] != bucket else { return position } }
    return count
  }

  internal func bucketForPosition(position: Index) -> Bucket { return keyMap[position] }

  internal func nextBucket(bucket: Bucket) -> Bucket { return (bucket &+ 1) & bucketMask }

  internal func previousBucket(bucket: Bucket) -> Bucket { return (bucket &- 1) & bucketMask }

  internal func find(key: Key) -> (position: Bucket, found: Bool) {

    let startBucket = bucketForKey(key)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard keyInBucket(bucket) != key  else { return (bucket, true) }
      bucket = nextBucket(bucket)
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  internal func keyInBucket(bucket: Bucket) -> Key { return keys[bucket] }

  internal func valueInBucket(bucket: Bucket) -> Value { return values[bucket] }

  internal func valueForKey(key: Key) -> Value? {
    guard count > 0 else { return nil }
    let (bucket, found) = find(key)
    return found ? valueInBucket(bucket) : nil
  }

  internal func elementInBucket(bucket: Bucket) -> Element {
    return (keyInBucket(bucket), valueInBucket(bucket))
  }

  internal func elementAtPosition(position: Index) -> Element {
    return elementInBucket(bucketForPosition(position))
  }

  internal func isInitializedBucket(bucket: Bucket) -> Bool { return bitMap[bucket] }

  internal func indexForKey(key: Key) -> Index? {
    guard count > 0 else { return nil }
    let (bucket, found) = find(key)
    guard found else { return nil }
    return positionForBucket(bucket)
  }

  // MARK: Removing data

  internal func destroyEntryAt(position: Index) {
    defer { _fixLifetime(self) }
    var bucket = bucketForPosition(position)

    assert(bitMap[bucket], "bucket empty")
    var idealBucket = bucketForKey((keys + bucket).move())

    (values + bucket).destroy()
    keyMap[position] = -1
    bitMap[bucket] = false

    if position + 1 < count {
      let from = keyMap + position + 1
      let moveCount = count - position - 1
      (keyMap + position).moveInitializeFrom(from, count: moveCount)
    }

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

  internal func initializeKey(key: Key, value: Value, position: Int, bucket: Int) {
    defer { _fixLifetime(self) }
    (keys + bucket).initialize(key)
    (values + bucket).initialize(value)
    bitMap[bucket] = true
    (keyMap + position).initialize(bucket)
  }


  internal func initializeKey(key: Key, value: Value, bucket: Bucket) {
    initializeKey(key, value: value, position: count, bucket: bucket)
  }

  // MARK: Assigning into already initialized data
  internal func setValue(value: Value, at position: Index) {
    setValue(value, inBucket: bucketForPosition(position))
  }

  internal func setValue(value: Value, inBucket bucket: Bucket) {
    (values + bucket).initialize(value)
  }

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension OrderedDictionaryBuffer : CustomStringConvertible, CustomDebugStringConvertible {
    
  private var elementsDescription: String {
    if count == 0 { return "[:]" }

    var result = "["
    var first = true
    for bucket in UnsafeBufferPointer(start: keyMap, count: count) {
      if first { first = false } else { result += ", " }
      debugPrint(keys[bucket], terminator: ": ", toStream: &result)
      debugPrint(values[bucket], terminator: "",   toStream: &result)
    }
    result += "]"
    return result
  }

  internal var description: String { return elementsDescription }

  internal var debugDescription: String {
    var result = elementsDescription + "\n"
    result += "count = \(count)\n"
    result += "capacity = \(capacity)\n"
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

  public typealias Index = Int
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

  internal mutating func ensureUniqueWithCapacity(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool)
  {
    
    if capacity >= minimumCapacity {
      guard !isUniquelyReferenced(&owner) else { return(reallocated: false, capacityChanged: false) }
      owner = Owner(buffer: Buffer(storage: buffer.storage.clone()))
      return (reallocated: true, capacityChanged: false)
    }

    let newBuffer = Buffer(minimumCapacity: minimumCapacity)
    for position in 0 ..< count {
      let oldBucket = buffer.keyMap[position]
      let key = buffer.keys[oldBucket]
      let value = buffer.values[oldBucket]
      let (bucket, _) = newBuffer.find(key)
      newBuffer.initializeKey(key, value: value, position: position, bucket: bucket)
    }
    newBuffer.count = buffer.count
    owner = Owner(buffer: newBuffer)
    return (reallocated: true, capacityChanged: true)

  }

  public init() { owner = Owner(minimumCapacity: 0) }

  public init(minimumCapacity: Int) { owner = Owner(minimumCapacity: minimumCapacity) }

  internal init(buffer: Buffer) { owner = Owner(buffer: buffer) }

  public var startIndex: Index { return 0 }

  public var endIndex: Index { return count }

  public func indexForKey(key: Key) -> Index? { return buffer.indexForKey(key) }

  public subscript(position: Index) -> (Key, Value) { return buffer.elementAtPosition(position) }

  public subscript(key: Key) -> Value? {
    get { return buffer.valueForKey(key) }
    set {
      if let value = newValue { _updateValue(value, forKey: key, oldValue: nil, oldKey: nil) }
      else { _removeValueForKey(key, oldValue: nil) }
    }
  }

  internal mutating func _updateValue(value: Value,
                              forKey key: Key,
                            oldValue: UnsafeMutablePointer<Value?>,
                              oldKey: UnsafeMutablePointer<Key?>)
  {
    var (bucket, found) = buffer.find(key)

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

    let (_, capacityChanged) = ensureUniqueWithCapacity(minCapacity)
    if capacityChanged { (bucket, found) = buffer.find(key) }

    if found {
      buffer.setValue(value, inBucket: bucket)
    } else {
      buffer.initializeKey(key, value: value, bucket: bucket)
      buffer.count += 1
    }
  }

  public mutating func updateValue(value: Value, forKey key: Key) -> Value? {
    let oldValue = UnsafeMutablePointer<Value?>.alloc(1)
    _updateValue(value, forKey: key, oldValue: oldValue, oldKey: nil)
    return oldValue.memory
  }

  internal mutating func _removeAtIndex(index: Index, oldElement: UnsafeMutablePointer<Element>) {
    if oldElement != nil { oldElement.initialize(buffer.elementInBucket(index)) }
    ensureUniqueWithCapacity(capacity)
    buffer.destroyEntryAt(index)
  }

  public mutating func removeAtIndex(index: Index) -> (Key, Value) {
    let oldElement = UnsafeMutablePointer<Element>.alloc(1)
    _removeAtIndex(index, oldElement: oldElement)
    return oldElement.memory
  }

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

  public mutating func removeValueForKey(key: Key) -> Value? {
    let oldValue = UnsafeMutablePointer<Value?>.alloc(1)
    _removeValueForKey(key, oldValue: oldValue)
    return oldValue.memory
  }

  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {

    let capacity = keepCapacity ? self.capacity : 0
    owner = Owner(buffer: Buffer(storage: Storage.create(capacity)))
  }

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public func generate() -> Generator { return Generator(buffer: buffer) }

  public init(elements: [Element]) {
    var keys: Set<Int> = []
    var filteredElements: [Element] = []
    for element in elements where !keys.contains(element.0.hashValue) {
      keys.insert(element.0.hashValue)
      filteredElements.append(element)
    }
    let buffer = Buffer(elements: filteredElements)
    self.init(buffer: buffer)
  }

  public init(dictionaryLiteral elements: Element...) {
    self.init(elements: elements)
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

  public var description: String { return elementsDescription }
  
  public var debugDescription: String { return elementsDescription }
}

extension OrderedDictionary: Equatable {}

public func == <Key: Hashable, Value>
  (lhs: OrderedDictionary<Key, Value>, rhs: OrderedDictionary<Key, Value>) -> Bool
{

  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }

  for ((k1, _), (k2, _)) in zip(lhs, rhs) {
    guard k1 == k2 else { return false }
  }

  return true
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
