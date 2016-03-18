//
//  OrderedSet.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

extension SequenceType where Self.Generator.Element:Hashable {
  var hashValues: [Int] { return map {$0.hashValue} }
}

internal struct OrderedSetHashMapStorageHeader {
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

internal final class OrderedSetHashMapStorage: ManagedBuffer<OrderedSetHashMapStorageHeader, UInt8> {
  typealias Storage = OrderedSetHashMapStorage
  typealias Header = OrderedSetHashMapStorageHeader
  typealias BufferPointer = ManagedBufferPointer<Header, UInt8>
  static func bytesForBitMap(capacity: Int) -> Int {
    let numWords = BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) + alignof(UInt)
  }

  var bitMapBytes: Int { return Storage.bytesForBitMap(capacity) }

  static func bytesForValues(capacity: Int) -> Int {
    let padding = max(0, alignof(Int) - alignof(UInt))
    return strideof(Int) * capacity + padding
  }

  var valuesBytes: Int { return Storage.bytesForValues(capacity) }

  var bytesAllocated: Int { return value.bytesAllocated }

  var maxLoadFactorInverse: Double { return header.maxLoadFactorInverse }

  var buffer: BufferPointer { return BufferPointer(unsafeBufferObject: self) }

  var header: Header {
    unsafeAddress { return buffer.withUnsafeMutablePointerToValue {UnsafePointer($0)} }
    unsafeMutableAddress { return buffer.withUnsafeMutablePointerToValue {$0} }
  }


  var capacity: Int { return header.capacity }

  var count: Int { get { return header.count } set { header.count = newValue } }

  var bitMap: UnsafeMutablePointer<UInt> {
    return UnsafeMutablePointer<UInt>(withUnsafeMutablePointerToElements({$0}))
  }

  var values: UnsafeMutablePointer<Int> {
    return UnsafeMutablePointer<Int>(UnsafePointer<UInt8>(bitMap) + bitMapBytes)
  }

  static func capacityForMinimumCapacity(minimumCapacity: Int) -> Int {
    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }
    return capacity
  }

  static func create(minimumCapacity: Int) -> Storage {
    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }

    let requiredCapacity = bytesForBitMap(capacity) + bytesForValues(capacity)

    let storage = super.create(requiredCapacity) {
      return Header(capacity: capacity, bytesAllocated: $0.allocatedElementCount)
    }

    let downCastStorage = storage as! Storage

    let bitMap = BitMap(storage: downCastStorage.bitMap, bitCount: capacity)
    bitMap.initializeToZero()

    return downCastStorage
  }

  deinit {
    withUnsafeMutablePointerToValue { $0.destroy() }
  }
}


internal struct OrderedSetHashMapBuffer {

  internal typealias Index = Int
  internal typealias Element = Int

  internal typealias Buffer = OrderedSetHashMapBuffer
  internal typealias Storage = OrderedSetHashMapStorage
  internal typealias Bucket = Int

  internal var storage: Storage
  internal var bitMap: BitMap
  internal var values: UnsafeMutablePointer<Int>

  internal var capacity: Int { defer { _fixLifetime(storage) }; return storage.capacity }

  internal var count: Int {
    get { defer { _fixLifetime(storage) }; return storage.count }
    nonmutating set { defer { _fixLifetime(storage) }; storage.count = newValue }
  }

  internal var maxLoadFactorInverse: Double {
    defer { _fixLifetime(storage) }
    return storage.maxLoadFactorInverse
  }

  internal init(capacity: Int) {
    self = Buffer(storage: Storage.create(capacity))
  }

  internal init(minimumCapacity: Int = 2) {
    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }
    self = Buffer(capacity: capacity)
  }

  internal static func minimumCapacityForCount(count: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  internal init(storage: Storage) {
    self.storage = storage
    bitMap = BitMap(storage: storage.bitMap, bitCount: storage.capacity)
    values = storage.values
    _fixLifetime(storage)
  }

  internal var bucketMask: Int { return capacity &- 1 }

  internal func bucketForValue(value: Int) -> Bucket {
    return _squeezeHashValue(value.hashValue, 0 ..< capacity)
  }

  internal func currentBucketForValue(value: Int) -> Bucket? {
    guard count > 0 else { return nil }
    let (bucket, found) = find(value)
    return found ? bucket : nil
  }

  internal func nextBucket(bucket: Bucket) -> Bucket { return (bucket &+ 1) & bucketMask }

  internal func previousBucket(bucket: Bucket) -> Bucket { return (bucket &- 1) & bucketMask }

  internal func find(value: Int, _ startBucket: Int? = nil) -> (bucket: Bucket, found: Bool) {
    let startBucket = startBucket ?? bucketForValue(value)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard valueInBucket(bucket) != value  else { return (bucket, true) }
      bucket = nextBucket(bucket)
    } while true
  }

  /// - requires: `bucket` is initialized
  internal func valueInBucket(bucket: Bucket) -> Int {
    defer { _fixLifetime(self) }
    return (values + bucket).memory
  }

  internal func maybeValueInBucket(bucket: Bucket) -> Int? {
    guard count > 0 && isInitializedBucket(bucket) else { return nil }
    return valueInBucket(bucket)
  }

  /// Returns whether `bucket` is initialized
  internal func isInitializedBucket(bucket: Bucket) -> Bool { return bitMap[bucket] }

  /// - requires: `bucket` is initialized
  internal func destroyValueInBucket(bucket: Bucket) {
    defer { _fixLifetime(self) }
    assert(isInitializedBucket(bucket), "uninitialized bucket: \(bucket)")
    (values + bucket).destroy()
    bitMap[bucket] = false
    assert(!isInitializedBucket(bucket), "malfunctioning bitMap")
  }

  internal func initializeValue(value: Int, bucket: Int) {
    defer { _fixLifetime(self) }
    (values + bucket).initialize(value)
    bitMap[bucket] = true
    assert(isInitializedBucket(bucket), "malfunctioning bitMap")
  }


  /// - requires: `bucket` is initialized
  internal func setValue(value: Int, inBucket bucket: Bucket) {
    defer { _fixLifetime(self) }
    (values + bucket).initialize(value)
  }

//  internal func moveInitializeFrom(from: Buffer, at: Int, toEntryAt: Int) {
//    (values + toEntryAt).initialize((from.values + at).move())
//    from.bitMap[at] = false
//    bitMap[toEntryAt] = true
//  }

}

extension OrderedSetHashMapBuffer : CustomStringConvertible, CustomDebugStringConvertible {

  internal var elementsDescription: String {
    if count == 0 { return "[]" }

    var result = "["
    var first = true
    for bucket in 0 ..< capacity where isInitializedBucket(bucket) {
      if first { first = false } else { result += ", " }
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
    for bucket in 0 ..< capacity {
      if isInitializedBucket(bucket) {
        let value = valueInBucket(bucket)
        result += "bucket \(bucket), ideal bucket = \(bucketForValue(value)), value: \(value)\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }
}

internal final class OrderedSetHashMapStorageOwner: NonObjectiveCBase {

  typealias Buffer = OrderedSetHashMapBuffer

  var buffer: Buffer

  init(minimumCapacity: Int) {
    buffer = Buffer(minimumCapacity: minimumCapacity)
  }

  init(buffer: Buffer) {
    self.buffer = buffer
  }

}

internal struct OrderedSetHashMapGenerator: GeneratorType {
  typealias Index = OrderedSetHashMapIndex
  typealias Buffer = OrderedSetHashMapBuffer
  typealias Owner = OrderedSetHashMapStorageOwner
  var index: Index
  let buffer: Buffer
  init(buffer: Buffer) { self.buffer = buffer; index = Index(buffer: buffer, bucket: -1).successor() }
  mutating func next() -> Int? {
    guard index.bucket < buffer.capacity else { return nil }
    defer { index._successorInPlace() }
    return index.buffer.valueInBucket(index.bucket)
  }
}

internal struct OrderedSetHashMapIndex: ForwardIndexType, Comparable {

  typealias Buffer = OrderedSetHashMapBuffer
  typealias Index = OrderedSetHashMapIndex

  var buffer: Buffer
  var bucket: Int

  /// Returns the next consecutive value after `self`.
  ///
  /// - Requires: The next value is representable.
  @warn_unused_result
  func successor() -> Index {
    var nextBucket = bucket + 1
    while nextBucket < buffer.capacity {
      guard !buffer.isInitializedBucket(nextBucket) else { break }
      nextBucket += 1
    }
    return Index(buffer: buffer, bucket: nextBucket)
  }
}

internal func ==(lhs: OrderedSetHashMapIndex, rhs: OrderedSetHashMapIndex) -> Bool {
  guard lhs.buffer.storage === rhs.buffer.storage else { return false }
  return lhs.bucket == rhs.bucket
}

internal func <(lhs: OrderedSetHashMapIndex, rhs: OrderedSetHashMapIndex) -> Bool {
  guard lhs.buffer.storage === rhs.buffer.storage else { return false }
  return lhs.bucket < rhs.bucket
}

internal struct OrderedSetHashMap {

  typealias Index = OrderedSetHashMapIndex
  typealias Generator = OrderedSetHashMapGenerator
  typealias Element = Int
  typealias _Element = Element
  internal typealias Storage = OrderedSetHashMapStorage
  internal typealias Buffer = OrderedSetHashMapBuffer
  internal typealias Owner = OrderedSetHashMapStorageOwner

  internal var buffer: Buffer {
    get { return owner.buffer }
    set { owner.buffer = newValue }
  }

  internal var owner: Owner

  internal mutating func ensureUniqueWithCapacity(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool)
  {
    let currentCapacity = capacity

    func clonedBuffer(capacity: Int) -> Buffer {
      let clone = Buffer(storage: Storage.create(capacity))
      defer { print("\nclonedBuffer(capacity: \(capacity))\nbuffer:\n\(buffer.debugDescription)\nclone: \(clone.debugDescription)") }

      if currentCapacity == clone.capacity {
        buffer.storage.buffer.withUnsafeMutablePointers {
          header, elements in
            clone.storage.buffer.withUnsafeMutablePointerToElements{
              cloneElements in
                cloneElements.initializeFrom(elements, count: header.memory.bytesAllocated)
            }
        }
      } else {
        for value in self {
          let (newBucket, _) = clone.find(value)
          clone.initializeValue(value, bucket: newBucket)
        }
      }

      clone.count = buffer.count
      return clone
    }

    if capacity >= minimumCapacity {
      guard !isUniquelyReferenced(&owner) else { return (false, false) }
      owner = Owner(buffer: clonedBuffer(capacity))
      return (true, false)
    } else {
      owner = Owner(buffer: clonedBuffer(minimumCapacity))
      return (true, true)
    }
  }

  init(minimumCapacity: Int) { owner = Owner(minimumCapacity: minimumCapacity) }

  internal init(owner: Owner) { self.owner = owner }
  internal init(buffer: Buffer) { owner = Owner(buffer: buffer) }

  var startIndex: Index { return Index(buffer: buffer, bucket: -1).successor()  }

  var endIndex: Index { return Index(buffer: buffer, bucket: capacity) }

  private var _hashValue: UnsafeMutablePointer<Int> = nil

  var hashValue: Int {
    guard _hashValue == nil else { return _hashValue.memory }
    _hashValue.initialize(reduce(_mixInt(0)) { $0 ^ _mixInt($1) })
    return _hashValue.memory
  }

  func map<T>(@noescape transform: (Int) throws -> T) rethrows -> [T] {
    return []
  }

  @warn_unused_result
  func _customContainsEquatableElement(value: Int) -> Bool? { return contains(value) }

  @warn_unused_result
  func indexOf(value: Int) -> Index? {
    let (bucket, found) = buffer.find(value)
    guard found else { return nil }
    return Index(buffer: buffer, bucket: bucket)
  }

  @warn_unused_result
  func _customIndexOfEquatableElement(value: Element) -> Index?? {
    return Optional(indexOf(value))
  }

  subscript(index: Index) -> Int {
    precondition((0 ..< capacity).contains(index.bucket), "Index invalid: \(index)")
    return buffer.valueInBucket(index.bucket)
  }

  @warn_unused_result
  func contains(value: Int) -> Bool { let (_, found) = buffer.find(value); return found }

  /// Wrapper for modifying count that also sets `_hashValue` to `nil`
  /// - requires: `(0 ... capacity).contains(count + offset)`
  internal mutating func updateCount(offset offset: Int) {
    buffer.count += offset
    _hashValue = nil
  }

  internal mutating func _unsafeRemoveValue(value: Int, fromBucket bucket: Int) {
    buffer.destroyValueInBucket(bucket)
    updateCount(offset: -1)
    _patchHole(bucket, idealBucket: buffer.bucketForValue(value))
  }

  /// - requires: `bucket` is initialized
  internal mutating func _removeValueInBucket(bucket: Int, oldValue: UnsafeMutablePointer<Int?>) {
    let value = buffer.valueInBucket(bucket)
    if oldValue != nil { oldValue.initialize(value) }
    ensureUniqueWithCapacity(capacity)
    _unsafeRemoveValue(value, fromBucket: bucket)
  }

  internal func _patchHole(hole: Int, idealBucket: Int) {
    var hole = hole
    var start = idealBucket
    while buffer.isInitializedBucket(buffer.previousBucket(start)) { start = buffer.previousBucket(start) }

    var lastInChain = hole
    var last = buffer.nextBucket(lastInChain)
    while buffer.isInitializedBucket(last) { lastInChain = last; last = buffer.nextBucket(last) }

    FillHole: while hole != lastInChain {
      last = lastInChain
      while last != hole {
        let value = buffer.valueInBucket(last)
        let bucket = buffer.bucketForValue(value)

        switch (bucket >= start, bucket <= hole) {
          case (true, true) where start <= hole,
               (true, _)    where start > hole,
               (_, true)    where start > hole:
            break FillHole
          default:
            last = buffer.previousBucket(last)
        }
      }
      guard last != hole else { break }
      (buffer.values + hole).initialize((buffer.values + last).move())
      buffer.bitMap[last] = false
      buffer.bitMap[hole] = true
//      buffer.moveInitializeFrom(buffer, at: last, toEntryAt: hole)
      hole = last
    }
  }

  internal mutating func _removeValue(value: Int, oldValue: UnsafeMutablePointer<Int?>) {
    let (bucket, found) = buffer.find(value)
    guard found else {
      if oldValue != nil { oldValue.initialize(nil) }
      return
    }
    _removeValueInBucket(bucket, oldValue: oldValue)
  }

  mutating func remove(value: Int) -> Int? {
    let oldValue = UnsafeMutablePointer<Int?>.alloc(1)
    _removeValue(value, oldValue: oldValue)
    return oldValue.memory
  }

  mutating func removeFirst() -> Int {
    guard let bucket = (0 ..< capacity).first({ buffer.isInitializedBucket($0) }) else {
      fatalError("removeFirst() requires the collection not be empty")
    }
    let oldValue = UnsafeMutablePointer<Int?>.alloc(1)
    _removeValueInBucket(bucket, oldValue: oldValue)
    return oldValue.memory!
  }

  /// - requires: Guaranteed uniqueness and capacity
  internal mutating func _unsafeInsertValue(value: Int, inBucket bucket: Int) {
    buffer.initializeValue(value, bucket: bucket)
    updateCount(offset: 1)
  }

  /// - requires: `value` is not already a member
  internal mutating func _insertValue(value: Int, inBucket bucket: Int) {
    let minimumCapacity = Buffer.minimumCapacityForCount(count + 1, buffer.maxLoadFactorInverse)
    let (_, capacityChanged) = ensureUniqueWithCapacity(minimumCapacity)
    guard capacityChanged else {
      _unsafeInsertValue(value, inBucket: bucket)
      return
    }
    let (bucket, _) = buffer.find(value)
    _unsafeInsertValue(value, inBucket: bucket)
  }

  mutating func insert(value: Int) {
    let (bucket, found) = buffer.find(value)
    guard !found else { return }
    _insertValue(value, inBucket: bucket)
  }

  var count: Int { return buffer.count }
  var capacity: Int { return buffer.capacity }

  func generate() -> Generator { return Generator(buffer: buffer) }

  var isEmpty: Bool { return count == 0 }

  var first: Element? {
    guard let bucket = (0 ..< capacity).first({ buffer.isInitializedBucket($0) }) else {
      return nil
    }
    return buffer.valueInBucket(bucket)
  }

  mutating func popFirst() -> Element? {
    guard count > 0 else { return nil }; return removeFirst()
  }

}

extension OrderedSetHashMap: SetType {

  mutating func reserveCapacity(capacity: Int) { ensureUniqueWithCapacity(capacity) }

  init<S : SequenceType where S.Generator.Element == Int>(_ elements: S) {
    if let hashMap = elements as? OrderedSetHashMap {
      self.init(owner: hashMap.owner)
    } else {
      self.init(minimumCapacity: elements.underestimateCount())
      for element in elements {
        let (bucket, found) = buffer.find(element)
        guard !found else { continue }
        _unsafeInsertValue(element, inBucket: bucket)
      }
    }
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set`.
  @warn_unused_result
  func isSubsetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    for value in self where !hashMap.contains(value) { return false }
    return true
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    return isSubsetOf(hashMap) && hashMap.count > count
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set`.
  @warn_unused_result
  func isSupersetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    for value in sequence where !contains(value) { return false }
    return true
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    return isSupersetOf(hashMap) && count > hashMap.count
  }

  /// Returns true if no members in the set are in a finite sequence as a `Set`.
  @warn_unused_result
  func isDisjointWith<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    for value in sequence where contains(value){ return false }
    return true
  }

  /// Return a new `Set` with items in both this set and a finite sequence.
  @warn_unused_result
  func union<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> OrderedSetHashMap {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  /// Insert elements of a finite sequence into this `Set`.
  mutating func unionInPlace<S:SequenceType where S.Generator.Element == Int>(sequence: S) {
    var checkedUnique = false
    for value in sequence {
      var (bucket, found) = buffer.find(value)
      guard !found else { continue }
      if !checkedUnique {
        let (_, capacityChanged) = ensureUniqueWithCapacity(count + sequence.underestimateCount())
        if capacityChanged { (bucket, _) = buffer.find(value) }
        checkedUnique = true
      }
      _unsafeInsertValue(value, inBucket: bucket)
    }
    if checkedUnique { _hashValue = nil }
  }

  /// Return a new set with elements in this set that do not occur in a finite sequence.
  @warn_unused_result
  func subtract<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> OrderedSetHashMap {
    var result = self
    result.subtractInPlace(sequence)
    return result
  }

  /// Remove all members in the set that occur in a finite sequence.
  mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Int>(sequence: S) {
    var checkedUnique = false
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    for value in self where hashMap.contains(value) {

//    print("\n\(#function) - subtracting these values from other:\n\(hashMap)\n\n\(#function) - from these values from self:\n\(self)")
      if !checkedUnique {
        let (_, capacityChanged) = ensureUniqueWithCapacity(capacity)
        assert(!capacityChanged, "The only reason to reallocate should be if we weren't unique")
        checkedUnique = true
      }
      let (bucket, _) = buffer.find(value)
      _unsafeRemoveValue(value, fromBucket: bucket)
    }
    if checkedUnique { _hashValue = nil }
//    print("\n\(#function) - resulting hash map:\n\(self)")
  }

  /// Return a new set with elements common to this set and a finite sequence.
  @warn_unused_result
  func intersect<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> OrderedSetHashMap {
    var result = self
    result.intersectInPlace(sequence)
    return result
  }

  /// Remove any members of this set that aren't also in a finite sequence.
  mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Int>(sequence: S) {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    var checkedUnique = false
    for value in self where !hashMap.contains(value) {

      if !checkedUnique { ensureUniqueWithCapacity(capacity); checkedUnique = true }
      let (bucket, _) = buffer.find(value)
      _unsafeRemoveValue(value, fromBucket: bucket)
    }
    if checkedUnique { _hashValue = nil }
  }

  /// Return a new set with elements that are either in the set or a finite sequence but do not occur in both.
  @warn_unused_result
  func exclusiveOr<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> OrderedSetHashMap {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  /// For each element of a finite sequence, remove it from the set if it is a common element, otherwise add it
  /// to the set. Repeated elements of the sequence will be ignored.
  mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Int>(sequence: S) {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
//    var checkedUnique = false

    print("\n\(#function) - xoring these values from other:\n\(hashMap)\n\n\(#function) - with these values from self:\n\(self)")

    let common = intersect(hashMap)
    print("\n\(#function) - values in common: \(common)")

    let uniqueSelf = subtract(common)
//    subtractInPlace(common)
    print("\n\(#function) - values unique in self: \(uniqueSelf)")

    let uniqueOther = hashMap.subtract(common)
//    hashMap.subtractInPlace(common)

    print("\n\(#function) - values unique to other: \(uniqueOther)")

    self = uniqueSelf.union(uniqueOther)
//    unionInPlace(hashMap)

//    for value in self where hashMap.contains(value) {
//      remove(value)
//      hashMap.remove(value)
//      if !checkedUnique {
//        var (_, capacityChanged) = ensureUniqueWithCapacity(capacity)
//        assert(!capacityChanged, "capacity shouldn't change when we are removing a value")
//        (_, capacityChanged) = hashMap.ensureUniqueWithCapacity(hashMap.capacity)
//        assert(!capacityChanged, "capacity shouldn't change when we are removing a value")
//        checkedUnique = true
//      }
//      var (bucket, found) = buffer.find(value)
//      assert(found, "wtf")
//      _unsafeRemoveValue(value, fromBucket: bucket)
//
//      (bucket, _) = hashMap.buffer.find(value)
//      hashMap._unsafeRemoveValue(value, fromBucket: bucket)
//    }
//
//    for value in hashMap where !contains(value) {
//      insert(value)
//      if !checkedUnique {
//        ensureUniqueWithCapacity(count + 1)
//        checkedUnique = true
//      }
//      let (bucket, _) = buffer.find(value)
//      buffer.initializeValue(value, bucket: bucket)
//      buffer.count += 1
//    }

//    if checkedUnique { _hashValue = nil }

    print("\n\(#function) - resulting hash map:\n\(self)")
    assert(count == Set(self).count, "wtf")
  }
}

extension OrderedSetHashMap: ArrayLiteralConvertible {
  init(arrayLiteral elements: Int...) {
    self.init(minimumCapacity: elements.count)
    for element in elements {
      let (bucket, found) = buffer.find(element)
      guard !found else { continue }
      _unsafeInsertValue(element, inBucket: bucket)
    }
  }
}

extension OrderedSetHashMap: CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    guard count > 0 else { return "[]" }

    var result = "["
    var first = true
    for member in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(member, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  var description: String { return elementsDescription }

  var debugDescription: String { return elementsDescription }
}

func ==(lhs: OrderedSetHashMap, rhs: OrderedSetHashMap) -> Bool {

  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }

  return lhs.hashValue == rhs.hashValue
}

public struct OrderedSet<Element:Hashable>: CollectionType {

  internal typealias Base = ContiguousArray<Element>

  internal var _base: Base
  internal var _hashValues: Set<Int>

  public var count: Int { return _base.count }

  public init(minimumCapacity: Int) {
    _base = Base(minimumCapacity: minimumCapacity)
    _hashValues = Set<Int>(minimumCapacity: minimumCapacity)
  }

  /**
   init:

   - parameter collection: C
   */
  public init<C:CollectionType where C.Generator.Element == Element>(_ collection: C) {
    self.init(minimumCapacity: numericCast(collection.count))
    for element in collection {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.append(element)
      _hashValues.insert(hashValue)
    }
  }

  /**
   init:

   - parameter sequence: S
   */
  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    self.init(minimumCapacity: numericCast(sequence.underestimateCount()))
    for element in sequence {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.append(element)
      _hashValues.insert(hashValue)
    }
  }
  
}

extension OrderedSet: MutableIndexable {
  public typealias Index = Base.Index
  public var startIndex: Index { return _base.startIndex }
  public var endIndex: Index { return _base.endIndex }

  public subscript(index: Index) -> Element {
    get { return _base[index] }
    set {
      let hashValue = newValue.hashValue
      guard _hashValues ∌ hashValue else { return }
      _hashValues.remove(_base[index].hashValue)
      _hashValues.insert(hashValue)
      _base[index] = newValue
    }
  }

}

extension OrderedSet: MutableCollectionType {

  public subscript(bounds: Range<Int>) -> SubSequence {
    get { return SubSequence(_base[bounds]) }
    set { _base[bounds] = newValue._base }
  }

}

extension OrderedSet: RangeReplaceableCollectionType {

  public init() { _base = []; _hashValues = [] }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    var elements = Array<Element>(minimumCapacity: numericCast(newElements.count))
    for element in newElements where elements ∌ element { elements.append(element) }
    _hashValues.subtractInPlace(_base[subRange].hashValues)
    _base.replaceRange(subRange, with: elements)
    _hashValues.unionInPlace(elements.hashValues)
  }

  public mutating func append(element: Element) {
    let hashValue = element.hashValue
    guard _hashValues ∌ hashValue else { return }
    _hashValues.insert(hashValue)

    _base.append(element)
  }

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  public mutating func appendContentsOf<S : SequenceType
    where S.Generator.Element == Element>(newElements: S)
  {
    var elements: [Element] = []
    elements.reserveCapacity(newElements.underestimateCount())
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      elements.append(element)
    }
    _base.appendContentsOf(elements)
  }

  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAtIndex(i: Int) -> Element {
    let result = _base.removeAtIndex(i)
    _hashValues.remove(result.hashValue)
    return result
  }

  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  public mutating func removeFirst() -> Element {
    let result = _base.removeFirst()
    assert(_hashValues ∌ result.hashValue)
    return result
  }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `self.count >= n`.
  public mutating func removeFirst(n: Int) {
    precondition(_base.count >= n, "Cannot remove more items than are actually contained")
    _hashValues.subtractInPlace(_base[..<n].hashValues)
    _base.removeFirst(n)
  }


  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeRange(subRange: Range<Int>) {
    _hashValues.subtractInPlace(_base[subRange].hashValues)
    _base.removeRange(subRange)
  }

  /// Remove all elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - parameter keepCapacity: If `true`, is a non-binding request to
  ///    avoid releasing storage, which can be a useful optimization
  ///    when `self` is going to be grown again.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAll(keepCapacity: Bool = false) {
    _base.removeAll(keepCapacity: keepCapacity)
    _hashValues.removeAll(keepCapacity: keepCapacity)
  }

  /// Reserve enough space to store minimumCapacity elements.
  ///
  /// - Postcondition: `capacity >= minimumCapacity` and the array has
  ///   mutable contiguous storage.
  ///
  /// - Complexity: O(`count`).
  public mutating func reserveCapacity(minimumCapacity: Int) {
    _base.reserveCapacity(minimumCapacity)
    var hashValuesCopy = Set<Int>(minimumCapacity: minimumCapacity)
    hashValuesCopy.unionInPlace(_hashValues)
    _hashValues = hashValuesCopy
  }

  /// Insert `newElement` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  ///
  /// - Requires: `atIndex <= count`.
  public mutating func insert(newElement: Element, atIndex i: Int) {
    let hashValue = newElement.hashValue
    guard _hashValues ∌ hashValue else { return }
    _hashValues.insert(hashValue)
    _base.insert(newElement, atIndex: i)
  }

  /// Insert `newElements` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count + newElements.count`).
  public mutating func insertContentsOf<S:CollectionType
    where S.Generator.Element == Element>(newElements: S, at i: Int)
  {
    var elements: [Element] = []
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      elements.append(element)
    }
    _base.insertContentsOf(elements, at: i)
  }

}


extension OrderedSet: SequenceType {
  public typealias Generator = AnyGenerator<Element>
  public typealias SubSequence = OrderedSetSlice<Element>

  public func generate() -> Generator { return AnyGenerator(_base.generate()) }
  public func dropFirst(n: Int) -> SubSequence { return OrderedSetSlice(_base.dropFirst(n)) }
  public func dropLast(n: Int) -> SubSequence { return OrderedSetSlice(_base.dropLast(n)) }
  public func prefix(maxLength: Int) -> SubSequence { return OrderedSetSlice(_base.prefix(maxLength)) }
  public func suffix(maxLength: Int) -> SubSequence { return OrderedSetSlice(_base.suffix(maxLength)) }
  public func split(maxSplit: Int,
              allowEmptySlices: Bool,
              @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    return try _base.split(maxSplit, allowEmptySlices: allowEmptySlices, isSeparator: isSeparator).map {
      OrderedSetSlice($0)
    }
  }
}

extension OrderedSet: _ArrayType {

  public typealias _Buffer = _ContiguousArrayBuffer<Element>

  /// The number of elements the Array can store without reallocation.
  public var capacity: Int { return _base.capacity }

  /// An object that guarantees the lifetime of this array's elements.
  public var _owner: AnyObject? { return _base._owner }

  /// If the elements are stored contiguously, a pointer to the first
  /// element. Otherwise, `nil`.
  public var _baseAddressIfContiguous: UnsafeMutablePointer<Element> {
    return _base._baseAddressIfContiguous
  }

  public internal(set) var _buffer: _Buffer {
    get { return _base._buffer }
    set { _base._buffer = newValue }
  }

  public init(count: Int, repeatedValue: Element) {
    _base = [repeatedValue]
    _hashValues = [repeatedValue.hashValue]
  }

  public init(_ buffer: _Buffer) {
    self.init()
    let base = Base(buffer)
    for element in base {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      _base.append(element)
    }
  }

}


/// Operator form of `appendContentsOf`.
public func +=<Element, S: SequenceType
  where S.Generator.Element == Element>(inout lhs: OrderedSet<Element>, rhs: S)
{
  lhs ∪= rhs
}

extension OrderedSet: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension OrderedSet: CustomStringConvertible {
  public var description: String {
    var result = "["
    var first = true
    for item in self {
      if first { first = false } else { result += ", " }
      debugPrint(item, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }
}

extension OrderedSet: SetType {

  public mutating func insert(member: Element) { append(member) }

  public mutating func remove(member: Element) -> Element? {
    guard _hashValues.remove(member.hashValue) != nil, let idx = _base.indexOf(member) else { return nil }
    return _base.removeAtIndex(idx)
  }

  public func contains(element: Element) -> Bool { return _hashValues ∋ element.hashValue }

  public func isSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isSubsetOf(sequence.hashValues)
  }

  public func isStrictSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isStrictSubsetOf(sequence.hashValues)
  }

  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return _hashValues.isSupersetOf(sequence.hashValues)
  }

  public func isStrictSupersetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isStrictSupersetOf(sequence.hashValues)
  }

  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return _hashValues.isDisjointWith(sequence.hashValues)
  }

  public func union<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence where _hashValues ∌ element.hashValue {
      append(element)
    }
  }

  public func subtract<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.subtractInPlace(sequence)
    return result
  }

  public mutating func subtractInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    for element in sequence where _hashValues ∋ element.hashValue {
      remove(element)
    }
  }

  public func intersect<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.intersectInPlace(sequence)
    return result
  }

  public mutating func intersectInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let elements = sequence as? Set<Element> ?? Set(sequence)
    for element in _base where elements ∌ element { remove(element) }
  }

  public func exclusiveOr<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  public mutating func exclusiveOrInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let set = sequence as? Set<Element> ?? Set(sequence)
    var result = OrderedSet<Element>(minimumCapacity: capacity + set.count)
    for element in self where !set.contains(element) { result.insert(element) }
    for element in set where !contains(element) { result.insert(element) }
    self = result
  }

}

public struct OrderedSetSlice<Element:Hashable>: CollectionType {
  public typealias Base = ArraySlice<Element>
  internal var _base: Base
  internal var _hashValues: Set<Int>
  internal init(_ base: Base) { _base = base; _hashValues = Set(_base.hashValues) }
}

extension OrderedSetSlice: CustomStringConvertible {
  public var description: String {
    var result = "["
    var first = true
    for item in self {
      if first { first = false } else { result += ", " }
      debugPrint(item, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  public init<C:CollectionType where C.Generator.Element == Element>(_ collection: C) {
    self.init(minimumCapacity: numericCast(collection.count))
    for element in collection {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.append(element)
      _hashValues.insert(hashValue)
    }
  }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    self.init(minimumCapacity: numericCast(sequence.underestimateCount()))
    for element in sequence {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.append(element)
      _hashValues.insert(hashValue)
    }
  }

}

extension OrderedSetSlice: MutableIndexable {
  public typealias Index = Base.Index
  public var startIndex: Index { return _base.startIndex }
  public var endIndex: Index { return _base.endIndex }

  public subscript(index: Index) -> Element {
    get { return _base[index] }
    set {
      let hashValue = newValue.hashValue
      guard _hashValues ∌ hashValue else { return }
      _hashValues.remove(_base[index].hashValue)
      _hashValues.insert(hashValue)
      _base[index] = newValue
    }
  }

}

extension OrderedSetSlice: MutableCollectionType {

  public subscript(bounds: Range<Int>) -> SubSequence {
    get { return SubSequence(_base[bounds]) }
    set { _base[bounds] = newValue._base }
  }

}

extension OrderedSetSlice: RangeReplaceableCollectionType {

  public init() { _base = []; _hashValues = [] }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    var elements = Array<Element>(minimumCapacity: numericCast(newElements.count))
    for element in newElements where elements ∌ element { elements.append(element) }
    _hashValues.subtractInPlace(_base[subRange].hashValues)
    _base.replaceRange(subRange, with: elements)
    _hashValues.unionInPlace(elements.hashValues)
  }

  public mutating func append(element: Element) {
    let hashValue = element.hashValue
    guard _hashValues ∌ hashValue else { return }
    _hashValues.insert(hashValue)

    _base.append(element)
  }

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  public mutating func appendContentsOf<S : SequenceType
    where S.Generator.Element == Element>(newElements: S)
  {
    var elements: [Element] = []
    elements.reserveCapacity(newElements.underestimateCount())
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      elements.append(element)
    }
    _base.appendContentsOf(elements)
  }

  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAtIndex(i: Int) -> Element {
    let result = _base.removeAtIndex(i)
    _hashValues.remove(result.hashValue)
    return result
  }

  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  public mutating func removeFirst() -> Element {
    let result = _base.removeFirst()
    assert(_hashValues ∌ result.hashValue)
    return result
  }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `self.count >= n`.
  public mutating func removeFirst(n: Int) {
    _hashValues.subtractInPlace(_base[..<n].hashValues)
    _base.removeFirst(n)
  }


  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeRange(subRange: Range<Int>) {
    _hashValues.subtractInPlace(_base[subRange].hashValues)
    _base.removeRange(subRange)
  }

  /// Remove all elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - parameter keepCapacity: If `true`, is a non-binding request to
  ///    avoid releasing storage, which can be a useful optimization
  ///    when `self` is going to be grown again.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAll(keepCapacity: Bool = false) {
    _base.removeAll(keepCapacity: keepCapacity)
    _hashValues.removeAll(keepCapacity: keepCapacity)
  }

  /// Reserve enough space to store minimumCapacity elements.
  ///
  /// - Postcondition: `capacity >= minimumCapacity` and the array has
  ///   mutable contiguous storage.
  ///
  /// - Complexity: O(`count`).
  public mutating func reserveCapacity(minimumCapacity: Int) {
    _base.reserveCapacity(minimumCapacity)
    var hashValuesCopy = Set<Int>(minimumCapacity: minimumCapacity)
    hashValuesCopy.unionInPlace(_hashValues)
    _hashValues = hashValuesCopy
  }

  /// Insert `newElement` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  ///
  /// - Requires: `atIndex <= count`.
  public mutating func insert(newElement: Element, atIndex i: Int) {
    let hashValue = newElement.hashValue
    guard _hashValues ∌ hashValue else { return }
    _hashValues.insert(hashValue)
    _base.insert(newElement, atIndex: i)
  }

  /// Insert `newElements` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count + newElements.count`).
  public mutating func insertContentsOf<S:CollectionType
    where S.Generator.Element == Element>(newElements: S, at i: Int)
  {
    var elements: [Element] = []
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      elements.append(element)
    }
    _base.insertContentsOf(elements, at: i)
  }

}


extension OrderedSetSlice: SequenceType {
  public typealias Generator = AnyGenerator<Element>
  public typealias SubSequence = OrderedSetSlice<Element>

  public func generate() -> Generator { return AnyGenerator(_base.generate()) }
  public func dropFirst(n: Int) -> SubSequence { return OrderedSetSlice(_base.dropFirst(n)) }
  public func dropLast(n: Int) -> SubSequence { return OrderedSetSlice(_base.dropLast(n)) }
  public func prefix(maxLength: Int) -> SubSequence { return OrderedSetSlice(_base.prefix(maxLength)) }
  public func suffix(maxLength: Int) -> SubSequence { return OrderedSetSlice(_base.suffix(maxLength)) }
  public func split(maxSplit: Int,
                    allowEmptySlices: Bool,
                    @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    return try _base.split(maxSplit, allowEmptySlices: allowEmptySlices, isSeparator: isSeparator).map {
      SubSequence($0)
    }
  }
}

extension OrderedSetSlice: _ArrayType {

  public typealias _Buffer = ArraySlice<Element>._Buffer

  /// The number of elements the Array can store without reallocation.
  public var capacity: Int { return _base.capacity }

  /// An object that guarantees the lifetime of this array's elements.
  public var _owner: AnyObject? { return _base._owner }

  /// If the elements are stored contiguously, a pointer to the first
  /// element. Otherwise, `nil`.
  public var _baseAddressIfContiguous: UnsafeMutablePointer<Element> {
    return _base._baseAddressIfContiguous
  }

  public internal(set) var _buffer: _Buffer {
    get { return _base._buffer }
    set { _base._buffer = newValue }
  }

  public init(count: Int, repeatedValue: Element) {
    _base = [repeatedValue]
    _hashValues = [repeatedValue.hashValue]
  }

  public init(_ buffer: _Buffer) {
    self.init()
    let base = Base(buffer)
    for element in base {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      _base.append(element)
    }
  }

}


/// Operator form of `appendContentsOf`.
public func +=<Element, S: SequenceType
  where S.Generator.Element == Element>(inout lhs: OrderedSetSlice<Element>, rhs: S)
{
  lhs ∪= rhs
}

extension OrderedSetSlice: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension OrderedSetSlice: SetType {

  public mutating func insert(member: Element) { append(member) }

  public mutating func remove(member: Element) -> Element? {
    guard _hashValues.remove(member.hashValue) != nil, let idx = _base.indexOf(member) else { return nil }
    return _base.removeAtIndex(idx)
  }

  public func contains(element: Element) -> Bool { return _hashValues ∋ element.hashValue }

  public func isSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isSubsetOf(sequence.hashValues)
  }

  public func isStrictSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isStrictSubsetOf(sequence.hashValues)
  }

  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return _hashValues.isSupersetOf(sequence.hashValues)
  }

  public func isStrictSupersetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isStrictSupersetOf(sequence.hashValues)
  }

  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return _hashValues.isDisjointWith(sequence.hashValues)
  }

  public func union<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSetSlice<Element>
  {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence where _hashValues ∌ element.hashValue {
      append(element)
    }
  }

  public func subtract<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSetSlice<Element>
  {
    var result = self
    result.subtractInPlace(sequence)
    return result
  }

  public mutating func subtractInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    for element in sequence where _hashValues ∋ element.hashValue {
      remove(element)
    }
  }

  public func intersect<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSetSlice<Element>
  {
    var result = self
    result.intersectInPlace(sequence)
    return result
  }

  public mutating func intersectInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let elements = sequence as? Set<Element> ?? Set(sequence)
    for element in _base where elements ∌ element { remove(element) }
  }

  public func exclusiveOr<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSetSlice<Element>
  {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  public mutating func exclusiveOrInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let set = sequence as? Set<Element> ?? Set(sequence)
    var result = OrderedSetSlice<Element>(minimumCapacity: capacity + set.count)
    for element in self where !set.contains(element) { result.insert(element) }
    for element in set where !contains(element) { result.insert(element) }
    self = result
  }
  
}
