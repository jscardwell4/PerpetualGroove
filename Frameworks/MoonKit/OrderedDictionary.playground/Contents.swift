//: Playground - noun: a place where people can play

import UIKit
import MoonKit

private typealias StorageHead = (count: Int, capacity: Int, maxLoadFactorInverse: Double)
private final class OrderedDictionaryStorage<Key:Hashable, Value>: ManagedBuffer<StorageHead, UInt8> {

  static func bytesForBitMap(capacity: Int) -> Int {
    let numWords = BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) //+ alignof(UInt)
  }

  var bitMapBytes: Int { return OrderedDictionaryStorage<Key, Value>.bytesForBitMap(capacity) }

  static func bytesForKeyMap(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(Key), alignof(UInt))
    let padding = max(0, alignof(Int) - maxPrevAlignment)
    return strideof(Int) * capacity + padding
  }

  var keyMapBytes: Int { return OrderedDictionaryStorage<Key, Value>.bytesForKeyMap(capacity) }

  static func bytesForKeys(capacity: Int) -> Int {
    let padding = max(0, alignof(Key) - alignof(UInt))
    return strideof(Key) * capacity + padding
  }

  var keysBytes: Int { return OrderedDictionaryStorage<Key, Value>.bytesForKeys(capacity) }

  static func bytesForValues(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(Key), alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Key) - maxPrevAlignment)
    return strideof(Key) * capacity + padding
  }

  var valuesBytes: Int { return OrderedDictionaryStorage<Key, Value>.bytesForValues(capacity) }

  var capacity: Int { return withUnsafeMutablePointerToValue {$0.memory.capacity } }

  var count: Int {
    get { return withUnsafeMutablePointerToValue { $0.memory.count } }
    set { withUnsafeMutablePointerToValue { $0.memory.count = newValue } }
  }

  var maxLoadFactorInverse: Double {
    return withUnsafeMutablePointerToValue { $0.memory.maxLoadFactorInverse }
  }

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

  class func create(capacity: Int) -> OrderedDictionaryStorage {
    let requiredCapacity = bytesForBitMap(capacity)
                         + bytesForKeys(capacity)
                         + bytesForKeyMap(capacity)
                         + bytesForValues(capacity)

    let storage = super.create(requiredCapacity) {
      $0.withUnsafeMutablePointerToElements {
        BitMap(storage: UnsafeMutablePointer<UInt>($0), bitCount: capacity).initializeToZero()
      }
      return (count: 0, capacity: capacity, maxLoadFactorInverse: defaultMaxLoadFactorInverse)
    }

    return storage as! OrderedDictionaryStorage<Key, Value>
  }

  deinit {
    defer { _fixLifetime(self) }
//    print("deinit")
    let capacity = self.capacity
    let initializedEntries = BitMap(storage: bitMap, bitCount: capacity)
    let keys = self.keys
    let values = self.values

    for i in 0 ..< capacity where initializedEntries[i] {
      if !_isPOD(Key) {(keys+i).destroy() }
      if !_isPOD(Value) { (values + i).destroy() }
    }

    withUnsafeMutablePointerToValue {$0.destroy()}
//    _fixLifetime(self)
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
private let defaultMaxLoadFactorInverse = 1.0 / 0.75

public struct OrderedDictionaryGenerator<Key: Hashable, Value>: GeneratorType {
  private let buffer: Buffer<Key, Value>
  private var index: OrderedDictionaryIndex<Key, Value>
  private init(buffer: Buffer<Key, Value>) {
    self.buffer = buffer
    index = buffer.startIndex
  }
  public mutating func next() -> (Key, Value)? {
    guard index.orderedIndex < buffer.count else { return nil }
    defer { index = index.successor() }
    return buffer.assertingGet(index)
  }
}

public struct OrderedDictionaryGenerator2<Key: Hashable, Value>: GeneratorType {
  private let storage: OrderedDictionaryStorage<Key, Value>
  private var index: Int = 0
  private init(storage: OrderedDictionaryStorage<Key, Value>) {
    self.storage = storage
  }
  public mutating func next() -> (Key, Value)? {
    guard index < storage.count else { return nil }
    defer { index += 1 }
    let hashedIndex = storage.keyMap[index]
    return (storage.keys[hashedIndex], storage.values[hashedIndex])
  }
}

private struct Buffer<Key:Hashable, Value> {

  typealias Index = OrderedDictionaryIndex<Key, Value>
  typealias OrderedIndex = Int
  typealias HashedIndex = Int
//  typealias Element = (Key, Value)
//  typealias SubSequence = AnySequence<Element>

  var storage: OrderedDictionaryStorage<Key, Value>

  let bitMap: BitMap
  let keys: UnsafeMutablePointer<Key>
  let keyMap: UnsafeMutablePointer<Int>
  let values: UnsafeMutablePointer<Value>

  /**
   initWithCapacity:

   - parameter capacity: Int
  */
  init(capacity: Int) {
    storage = OrderedDictionaryStorage<Key, Value>.create(capacity)
    bitMap = BitMap(storage: storage.bitMap, bitCount: capacity)
    keys = storage.keys
    values = storage.values
    keyMap = storage.keyMap
    _fixLifetime(storage)
  }

  /**
   initWithMinimumCapacity:

   - parameter minimumCapacity: Int = 2
  */
  init(minimumCapacity: Int = 2) {
    // Make sure there's a representable power of 2 >= minimumCapacity
    assert(minimumCapacity <= (Int.max >> 1) + 1)

    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }

    self = Buffer(capacity: capacity)
  }

  var capacity: Int { defer { _fixLifetime(storage) }; return storage.capacity }

  var count: Int {
    get { defer { _fixLifetime(storage) }; return storage.count }
    nonmutating set(newValue) { defer { _fixLifetime(storage) }; storage.count = newValue }
  }

  var maxLoadFactorInverse: Double { defer { _fixLifetime(storage) }; return storage.maxLoadFactorInverse }

  func keyAt(i: HashedIndex) -> Key {
    precondition(i >= 0 && i < capacity)
    assert(isInitializedEntry(i))

    defer { _fixLifetime(self) }
    return (keys + i).memory
  }

  func isInitializedEntry(i: HashedIndex) -> Bool {
    precondition(i >= 0 && i < capacity, "invalid HashedIndex '\(i)' for capacity '\(capacity)'")
    return bitMap[i]
  }

  func indexForKey(key: Key) -> Index? {
    guard count > 0 else { return nil }
    return find(key, bucket(key)).0
  }

  func destroyEntryAt(index: OrderedIndex) {
    defer { _fixLifetime(self) }
    let hashedIndex = (keyMap + index).memory
    assert(isInitializedEntry(hashedIndex))
    let key = keyAt(hashedIndex)
    (keyMap + index).moveInitializeFrom(keyMap + index + 1, count: count - index - 1)
    (keys + hashedIndex).destroy()
    (values + hashedIndex).destroy()
    bitMap[hashedIndex] = false
    assert(!isInitializedEntry(hashedIndex), "should no longer be initialized")

    // If we've put a hole in a chain of contiguous elements, some
    // element after the hole may belong where the new hole is.
    var hole = hashedIndex

    // Find the first bucket in the contiguous chain
    var start = bucket(key)
    while isInitializedEntry(prev(start)) { start = prev(start) }

    // Find the last bucket in the contiguous chain
    var lastInChain = hole
    var b = next(lastInChain)
    while isInitializedEntry(b) { lastInChain = b; b = next(b) }

    // Relocate out-of-place elements in the chain, repeating until
    // none are found.
    while hole != lastInChain {
      // Walk backwards from the end of the chain looking for
      // something out-of-place.
      var b = lastInChain
      while b != hole {
        let idealBucket = bucket(keyAt(b))

        // Does this element belong between start and hole?  We need
        // two separate tests depending on whether [start,hole] wraps
        // around the end of the buffer
        let c0 = idealBucket >= start
        let c1 = idealBucket <= hole
        if start <= hole ? (c0 && c1) : (c0 || c1) {
          break // Found it
        }
        b = prev(b)
      }

      if b == hole { // No out-of-place elements found; we're done adjusting
        break
      }

      // Move the found element into the hole
      moveInitializeFrom(b, to: hole)
      hole = b
    }

//    for i in (count - index) ..< count
//      where bucket((keys + (keyMap + i).memory).memory) != (keyMap + i).memory
//    {
//      i
//      moveInitializeFrom(Index(buffer: self, orderedIndex: i, hashedIndex: (keyMap + i).memory),
//                         to: Index(buffer: self, orderedIndex: i, hashedIndex: bucket((keys + (keyMap + i).memory).memory)))
//    }

    count -= 1
  }

  func destroyEntryAt(i: Index) { destroyEntryAt(i.orderedIndex) }

  func initializeKey(k: Key, value v: Value, at i: Index) {
    assert(!isInitializedEntry(i.hashedIndex))
    defer { _fixLifetime(self) }
    (keys + i.hashedIndex).initialize(k)
    (values + i.hashedIndex).initialize(v)
    bitMap[i.hashedIndex] = true
    (keyMap + i.orderedIndex).initialize(i.hashedIndex)
  }


  func moveInitializeFrom(from: HashedIndex, to: HashedIndex) {
    //    assert(!isInitializedEntry(to.hashedIndex), "entry already initialized")
    (keys + to).initialize((keys + from).move())
    (values + to).initialize((values + from).move())
    for i in 0 ..< count {
      guard keyMap[i] != from else { keyMap[i] = to; break }
    }
    bitMap[from] = false
    bitMap[to] = true
  }

  func moveInitializeFrom(from: Index, to: Index) {
//    assert(!isInitializedEntry(to.hashedIndex), "entry already initialized")
    (keys + to.hashedIndex).initialize((keys + from.hashedIndex).move())
    (values + to.hashedIndex).initialize((values + from.hashedIndex).move())
    (keyMap + from.orderedIndex).memory = to.hashedIndex
    bitMap[from.hashedIndex] = false
    bitMap[to.hashedIndex] = true
  }

  func valueAt(i: HashedIndex) -> Value {
    assert(isInitializedEntry(i))
    defer { _fixLifetime(self) }
    return (values + i).memory
  }

  func setKey(key: Key, value: Value, at i: HashedIndex) {
    assert(isInitializedEntry(i))
    defer { _fixLifetime(self) }
    (keys + i).memory = key
    (values + i).memory = value
  }

  var bucketMask: Int { return capacity &- 1 }

  func bucket(k: Key) -> Int { return _squeezeHashValue(k.hashValue, 0..<capacity) }

  func next(bucket: Int) -> Int { return (bucket &+ 1) & bucketMask }

  func prev(bucket: Int) -> Int { return (bucket &- 1) & bucketMask }

  func find(key: Key, _ startBucket: HashedIndex) -> (position: Index, found: Bool) {
    var bucket = startBucket

    // The invariant guarantees there's always a hole, so we just loop
    // until we find one
    while true {
      guard isInitializedEntry(bucket) else {
        return (Index(buffer: self, orderedIndex: count, hashedIndex: bucket), false)
      }
      guard keyAt(bucket) != key else {
        for i in 0 ..< count {
          guard (keyMap + i).memory != bucket else {
            return (Index(buffer: self, orderedIndex: i, hashedIndex: bucket), true)
          }
        }
        fatalError("key map does not contain bucket")
      }

      bucket = next(bucket)
    }
  }

  static func minimumCapacityForCount(count: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  mutating func unsafeAddNew(key newKey: Key, value: Value) {
    let (i, found) = find(newKey, bucket(newKey))
    assert(!found, "unsafeAddNew was called, but the time is already present")
    initializeKey(newKey, value: value, at: i)
  }

  var startIndex: Index {
    guard count > 0 else { return Index(buffer: self, orderedIndex: 0, hashedIndex: -1) }
    return Index(buffer: self, orderedIndex: 0, hashedIndex: keyMap.memory)
  }

  var endIndex: Index {
    guard count > 0 else { return Index(buffer: self, orderedIndex: 0, hashedIndex: -1) }
    return Index(buffer: self, orderedIndex: count, hashedIndex: -1)
  }

  func assertingGet(i: Index) -> (Key, Value) {
    precondition(isInitializedEntry(i.hashedIndex), "Index invalid: '\(i)'")
    return (keyAt(i.hashedIndex), valueAt(i.hashedIndex))
  }

  func assertingGet(key: Key) -> Value {
    let (i, found) = find(key, bucket(key))
    precondition(found, "key not found")
    return valueAt(i.hashedIndex)
  }

  func maybeGet(key: Key) -> Value? {
    guard count > 0 else { return nil }

    let (i, found) = find(key, bucket(key))
    return found ? valueAt(i.hashedIndex) : nil
  }

//  mutating func updateValue(value: Value, forKey key: Key) -> Value? {
//    var (i, found) = find(key, bucket(key))
//    let minCapacity = found
//      ? capacity
//      : Buffer.minimumCapacityForCount(count + 1, maxLoadFactorInverse)
//
//    let (_, capacityChanged) = ensureUniqueWithCapacity(minCapacity)
//    if capacityChanged {
//      i = find(key, bucket(key)).position
//    }
//
//    let oldValue: Value? = found ? valueAt(i.hashedIndex) : nil
//    if found {
//      setKey(key, value: value, at: i.hashedIndex)
//    } else {
//      initializeKey(key, value: value, at: Index(buffer: self, orderedIndex: count, hashedIndex: i.hashedIndex))
//      count += 1
//    }
//
//    return oldValue
//  }

//  mutating func removeAtIndex(index: Index) -> (Key, Value) {
//    let (key, value) = assertingGet(index)
//
//    var index = index
//
//    let (_, capacityChanged) = ensureUniqueWithCapacity(capacity)
//    if capacityChanged {
//      let (i, found) = find(key, bucket(key))
//      assert(found, "Lost entry for key '\(key)'")
//      index = i
//    }
//
//    destroyEntryAt(index)
//    return (key, value)
//  }

//  mutating func removeValueForKey(key: Key) -> Value? {
//    let (i, found) = find(key, bucket(key))
//    guard found else { return nil }
//    return removeAtIndex(i).1
//  }

//  mutating func removeAll(keepCapacity keepCapacity: Bool) {
//    guard isUniquelyReferenced(&storage) else {
//      storage = Storage<Key, Value>.create(keepCapacity ? capacity : 2)
//      return
//    }
//
//    for i in 0 ..< count { destroyEntryAt(i) }
//    count = 0
//  }

  init(elements: [(Key, Value)]) {
    let requiredCapacity = Buffer<Key, Value>.minimumCapacityForCount(elements.count, defaultMaxLoadFactorInverse)
    let buffer = Buffer(minimumCapacity: requiredCapacity)

    for (key, value) in elements {
      let (i, found) = buffer.find(key, buffer.bucket(key))
      precondition(!found, "Dictionary literal contains duplicate keys")
      buffer.initializeKey(key, value: value, at: i)
    }
    buffer.count = elements.count

    self = buffer
  }

//  func generate() -> Generator { return Generator() }

  var description: String {
    var result = ""
//    #if INTERNAL_CHECKS_ENABLED
      for i in 0..<capacity {
        if isInitializedEntry(i) {
          let key = keyAt(i)
          result += "bucket \(i), ideal bucket = \(bucket(key)), key = \(key)\n"
        } else {
          result += "bucket \(i), empty\n"
        }
      }
//    #endif
    return result
  }
}

public struct OrderedDictionaryIndex<Key: Hashable, Value>: ForwardIndexType, Comparable {
  private let buffer: Buffer<Key, Value>
  private let orderedIndex: Int
  private var hashedIndex: Int
  public func successor() -> OrderedDictionaryIndex<Key, Value> {
//    guard orderedIndex + 1 < buffer.count else { fatalError("successor would be out of bounds") }
    return OrderedDictionaryIndex<Key, Value>(buffer: buffer,
                                              orderedIndex: orderedIndex + 1,
                                              hashedIndex: (buffer.keyMap + orderedIndex + 1).memory)
  }
}

public func ==<K:Hashable, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  assert(lhs.buffer.storage === rhs.buffer.storage)
  return lhs.orderedIndex == rhs.orderedIndex
}

public func <<K:Hashable, V>(lhs: OrderedDictionaryIndex<K, V>, rhs: OrderedDictionaryIndex<K, V>) -> Bool {
  assert(lhs.buffer.storage === rhs.buffer.storage)
  return lhs.orderedIndex < rhs.orderedIndex
}

private final class Owner: NonObjectiveCBase {}

/// A hash-based mapping from `Key` to `Value` instances that preserves elment order.
public struct __OrderedDictionary__<Key: Hashable, Value>: CollectionType, DictionaryLiteralConvertible {

  public typealias Index = OrderedDictionaryIndex<Key, Value>

  private var buffer: Buffer<Key, Value>

  private var owner = Owner()

  mutating func ensureUniqueWithCapacity(minimumCapacity: Int) -> (reallocated: Bool, capacityChanged: Bool) {
    let oldCapacity = capacity
    if /*isUniquelyReferenced(&owner) &&*/ oldCapacity >= minimumCapacity {
      return (reallocated: false, capacityChanged: false)
    }

    isUniquelyReferenced(&owner)
    minimumCapacity
    oldCapacity
    let oldStorage = buffer.storage
    let newStorage = OrderedDictionaryStorage<Key, Value>.create(max(oldCapacity, minimumCapacity))
    let newCapacity = newStorage.capacity
    let newBitMap = BitMap(storage: newStorage.bitMap, bitCount: oldCapacity)

    for (i, hashedIndex) in UnsafeBufferPointer(start: oldStorage.keyMap, count: oldStorage.count).enumerate() {
      (newStorage.keyMap + i).initialize(hashedIndex)
      (newStorage.keys + hashedIndex).initialize((oldStorage.keys + hashedIndex).memory)
      (newStorage.values + hashedIndex).initialize((oldStorage.values + hashedIndex).memory)
      newBitMap[hashedIndex] = true
      newStorage.count = oldStorage.count
    }
    buffer.storage = newStorage
    if !isUniquelyReferenced(&owner) { owner = Owner() }
    return (reallocated: true, capacityChanged: oldCapacity != newCapacity)

  }

  /// Create an empty dictionary.
  public init() { self.init(minimumCapacity: 0) }

  public init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }

  private init(buffer: Buffer<Key, Value>) { self.buffer = buffer }

  public var startIndex: Index { return buffer.startIndex }

  public var endIndex: Index { return buffer.endIndex }

  public func indexForKey(key: Key) -> Index? { return buffer.indexForKey(key) }

  public subscript(position: Index) -> (Key, Value) {
    return buffer.assertingGet(position)
  }

  public subscript(key: Key) -> Value? {
    get { return buffer.maybeGet(key) }
    set {
      if let value = newValue { _updateValue(value, forKey: key) }
      else { _removeValueForKey(key) }
    }
  }

  private mutating func _updateValue(value: Value, forKey key: Key) {
    var (i, found) = buffer.find(key, buffer.bucket(key))
    let minCapacity = found
      ? capacity
      : Buffer<Key, Value>.minimumCapacityForCount(buffer.count + 1, buffer.maxLoadFactorInverse)

    let (_, capacityChanged) = ensureUniqueWithCapacity(minCapacity)
    if capacityChanged {
      i = buffer.find(key, buffer.bucket(key)).position
    }
    
    if found {
      buffer.setKey(key, value: value, at: i.hashedIndex)
    } else {
      buffer.initializeKey(key, value: value, at: Index(buffer: buffer, orderedIndex: count, hashedIndex: i.hashedIndex))
      buffer.count += 1
    }
  }

  public mutating func updateValue(value: Value, forKey key: Key) -> Value? {
    let oldValue = buffer.maybeGet(key)
    _updateValue(value, forKey: key)
    return oldValue
  }

  private mutating func _removeAtIndex(index: Index) {
    var index = index

    let (_, capacityChanged) = ensureUniqueWithCapacity(capacity)
    if capacityChanged {
      let hashedIndex = buffer.keyMap[index.orderedIndex]
      assert(buffer.isInitializedEntry(hashedIndex), "Lost entry for index '\(index)'")
      index = Index(buffer: buffer, orderedIndex: index.orderedIndex, hashedIndex: hashedIndex)
    }

    buffer.destroyEntryAt(index)
  }

  public mutating func removeAtIndex(index: Index) -> (Key, Value) {
    let (key, value) = buffer.assertingGet(index)
    _removeAtIndex(index)
    return (key, value)
  }

  private mutating func _removeValueForKey(key: Key) {
    key
    guard let index = buffer.indexForKey(key) else { return }
    index
    _removeAtIndex(index)
  }

  public mutating func removeValueForKey(key: Key) -> Value? {
    let oldValue = buffer.maybeGet(key)
    _removeValueForKey(key)
    return oldValue
  }

  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    guard isUniquelyReferenced(&owner) else {
      buffer.storage = OrderedDictionaryStorage<Key, Value>.create(keepCapacity ? capacity : 2)
      return
    }

    for i in 0 ..< count { buffer.destroyEntryAt(i) }
    buffer.count = 0
  }

  /// The number of entries in the dictionary.
  ///
  /// - Complexity: O(1).
  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public func generate() -> OrderedDictionaryGenerator<Key, Value> {
    return OrderedDictionaryGenerator<Key, Value>(buffer: buffer)
  }

//  @effects(readonly)
  public init(dictionaryLiteral elements: (Key, Value)...) {
    self.init(buffer: Buffer(elements: elements))
  }

//  var keys: LazyMapCollection<_MIDIEventContainer, Key> { return buffer.lazy.map { $0.0 } }
//  var values: LazyMapCollection<_MIDIEventContainer, Value> { return buffer.lazy.map { $0.1 } }

  public var isEmpty: Bool { return count == 0 }

}

extension __OrderedDictionary__: CustomStringConvertible, CustomDebugStringConvertible {
  func _makeDescription() -> String {
    if count == 0 {
      return "[:]"
    }

    var result = "["
    var first = true
    for (k, v) in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(k, terminator: "", toStream: &result)
      result += ": "
      debugPrint(v, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  /// A textual representation of `self`.
  public var description: String {
    return _makeDescription()
  }

  /// A textual representation of `self`, suitable for debugging.
  public var debugDescription: String {
    return _makeDescription()
  }
}
/*
 public func == <Key : Equatable, Value : Equatable>(
  lhs: [Key : Value],
  rhs: [Key : Value]
) -> Bool {
  switch (lhs._variantStorage, rhs._variantStorage) {
  case (.Native(let lhsNativeOwner), .Native(let rhsNativeOwner)):
    let lhsNative = lhsNativeOwner.nativeStorage
    let rhsNative = rhsNativeOwner.nativeStorage

    if lhsNativeOwner === rhsNativeOwner {
      return true
    }

    if lhsNative.count != rhsNative.count {
      return false
    }

    for (k, v) in lhs {
      let (pos, found) = rhsNative._find(k, rhsNative._bucket(k))
      // FIXME: Can't write the simple code pending
      // <rdar://problem/15484639> Refcounting bug
      /*
      if !found || rhs[pos].value != lhsElement.value {
        return false
      }
      */
      if !found {
        return false
      }
      if rhsNative.valueAt(pos.offset) != v {
        return false
      }
    }
    return true

  case (.Cocoa(let lhsCocoa), .Cocoa(let rhsCocoa)):
#if _runtime(_ObjC)
    return _stdlib_NSObject_isEqual(
      lhsCocoa.cocoaDictionary, rhsCocoa.cocoaDictionary)
#else
      _sanityCheckFailure("internal error: unexpected cocoa dictionary")
#endif

  case (.Native(let lhsNativeOwner), .Cocoa(let rhsCocoa)):
#if _runtime(_ObjC)
    let lhsNative = lhsNativeOwner.nativeStorage

    if lhsNative.count != rhsCocoa.count {
      return false
    }

    let endIndex = lhsNative.endIndex
    var index = lhsNative.startIndex
    while index != endIndex {
      let (key, value) = lhsNative.assertingGet(index)
      let optRhsValue: AnyObject? =
        rhsCocoa.maybeGet(_bridgeToObjectiveCUnconditional(key))
      if let rhsValue = optRhsValue {
        if value == _forceBridgeFromObjectiveC(rhsValue, Value.self) {
          index._successorInPlace()
          continue
        }
      }
      index._successorInPlace()
      return false
    }
    return true
#else
      _sanityCheckFailure("internal error: unexpected cocoa dictionary")
#endif

  case (.Cocoa, .Native):
#if _runtime(_ObjC)
    return rhs == lhs
#else
      _sanityCheckFailure("internal error: unexpected cocoa dictionary")
#endif
  }
}
*/

var dictionary = ["one": 1, "two": 2, "three": 3]
var orderedDictionary = __OrderedDictionary__<String, Int>(minimumCapacity: 8)
print(orderedDictionary.buffer.description)
orderedDictionary["one"] = 1
orderedDictionary
print(orderedDictionary.buffer.description)
orderedDictionary["two"] = 2
orderedDictionary
print(orderedDictionary.buffer.description)
orderedDictionary["three"] = 3
orderedDictionary
print(orderedDictionary.buffer.description)
orderedDictionary["two"] = nil
orderedDictionary
print(orderedDictionary.buffer.description)
orderedDictionary["one"] = nil
orderedDictionary
print(orderedDictionary.buffer.description)
orderedDictionary