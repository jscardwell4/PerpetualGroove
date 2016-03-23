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

// MARK: -
/// Structure for storing various pieces of information about an `OrderedSetHashMapStorage` instance.
struct OrderedSetHashMapStorageHeader {
  var count: Int = 0
  let capacity: Int
  let bytesAllocated: Int
  let maxLoadFactorInverse = 1/0.75
  let initializedBuckets: BitMap

  init(capacity: Int, bytesAllocated: Int, initializedBuckets: BitMap) {
    self.capacity = capacity
    self.bytesAllocated = bytesAllocated
    self.initializedBuckets = initializedBuckets
  }

}

// MARK: -

/// Hash-based storage for holding a collection of hash values \(`Int`\)
final class OrderedSetHashMapStorage: ManagedBuffer<OrderedSetHashMapStorageHeader, UInt8> {
  typealias Storage = OrderedSetHashMapStorage
  typealias Header = OrderedSetHashMapStorageHeader

  // MARK: Calculating size requirements

  /// Returns the number of bytes required for the bit map of initialized buckets given `capacity`
  static func bytesForInitializedBuckets(capacity: Int) -> Int {
    return BitMap.wordsFor(capacity) * sizeof(UInt) + alignof(UInt)
  }

  /// Returns the number of bytes required for the hash values given `capacity`
  static func bytesForValues(capacity: Int) -> Int {
    return strideof(Int) * capacity + max(0, alignof(Int) - alignof(UInt))
  }

  /// The number of bytes used to store the hash values for this instance
  var valuesBytes: Int { return Storage.bytesForValues(capacity) }

  /// The number of bytes used to store the bit map of initialized buckets for this instance
  var initializedBucketsBytes: Int { return Storage.bytesForInitializedBuckets(capacity) }

  // MARK: Accessors for storage header properties

  /// The total number of initialized buckets
  var count: Int { get { return value.count } set { value.count = newValue } }

  /// The total number of buckets
  var capacity: Int { return value.capacity }

  /// The total number of bytes managed by this instance; equal to `initializedBucketsBytes + valuesBytes`
  var bytesAllocated: Int { return value.bytesAllocated }

  /// Inverse of the ratio specified as the 'max load' for this instance
  var maxLoadFactorInverse: Double { return value.maxLoadFactorInverse }

  // MARK: Accessors for raw data

  /// Pointer to the first byte in memory allocated for the bit map of initialized buckets
  var initializedBucketsAddress: UnsafeMutablePointer<UInt8> { return withUnsafeMutablePointerToElements {$0} }

  /// Convenience for creating a `BitMap` over `initializedBuckets` that zeros out its memory only if `count == 0`
  var initializedBuckets: BitMap { return value.initializedBuckets }

  /// Pointer to the first byte in memory allocated for the hash values
  var values: UnsafeMutablePointer<Int> {
    return UnsafeMutablePointer<Int>(initializedBucketsAddress + initializedBucketsBytes)
  }

  /// Returns a new instance with enough space for at least `minimumCapacity` buckets
  static func create(minimumCapacity: Int) -> Storage {
    let capacity = round2(minimumCapacity)

    let bitmapBytes = bytesForInitializedBuckets(capacity)
    let requiredCapacity = bitmapBytes + bytesForValues(capacity)

    let storage = super.create(requiredCapacity) {
      let initializedBucketsStorage = $0.withUnsafeMutablePointerToElements { UnsafeMutablePointer<UInt>($0) }
      return Header(capacity: capacity,
             bytesAllocated: $0.allocatedElementCount,
             initializedBuckets: BitMap(uninitializedStorage: initializedBucketsStorage, bitCount: capacity))
    }

    return storage as! Storage
  }

  //NOTE: There does not seem to be a need for `deinit` since `super` destroys the header and `Int` is `POD`
}

// MARK: - Some bucket-related helpers

struct Bucket: BidirectionalIndexType, Comparable {
  let offset: Int
  let capacity: Int

  func predecessor() -> Bucket {
    return Bucket(offset: (offset &- 1) & (capacity &- 1), capacity: capacity)
  }

  func successor() -> Bucket {
    return Bucket(offset: (offset &+ 1) & (capacity &- 1), capacity: capacity)
  }
}

extension Bucket: CustomStringConvertible {
  var description: String { return "\(offset)" }
}

func ==(lhs: Bucket, rhs: Bucket) -> Bool { return lhs.offset == rhs.offset }
func <(lhs: Bucket, rhs: Bucket) -> Bool { return lhs.offset < rhs.offset }


/// Returns the hash value of `value` squeezed into `capacity`
func suggestBucketForValue(value: Int, capacity: Int) -> Bucket {
  return Bucket(offset: _squeezeHashValue(value.hashValue, 0 ..< capacity), capacity: capacity)
}

/// - requires: `initializedBuckets` has an empty bucket (to avoid an infinite loop)
func findBucketForValue(value: Int, capacity: Int, initializedBuckets: BitMap) -> Bucket {
  var bucket = suggestBucketForValue(value, capacity: capacity)
  repeat {
    guard initializedBuckets[bucket.offset] else { return bucket }
    bucket._successorInPlace()
  } while true
}

extension BitMap {
  subscript(bucket: Bucket) -> Bool {
    get { return self[bucket.offset] }
    nonmutating set { self[bucket.offset] = newValue }
  }
}

// MARK: -

struct OrderedSetHashMapBuffer {

  typealias Buffer = OrderedSetHashMapBuffer
  typealias Storage = OrderedSetHashMapStorage

  /// Owns the backing data.
  var storage: Storage

  /// A bit map for which buckets have been initialized.
  var _initializedBuckets: BitMap

  var initializedBuckets: [Bucket] {
    return _initializedBuckets.nonZeroBits.map { [capacity = capacity] in Bucket(offset: $0, capacity: capacity) }
  }

  /// A pointer to the first bucket.
  var values: UnsafeMutablePointer<Int>

  /// Returns a pointer to the specified `bucket`
  func bucketPointer(bucket: Bucket) -> UnsafeMutablePointer<Int> { return values + bucket.offset }

//  var buckets: Range<Bucket> {
//    return Bucket(offset: 0, capacity: capacity) ..< Bucket(offset: capacity, capacity: capacity)
//  }

  var capacity: Int { return storage.capacity }
  var count: Int { get { return storage.count } nonmutating set { storage.count = newValue } }
  var maxLoadFactorInverse: Double { return storage.maxLoadFactorInverse}

  /// Initialize the buffer by creating storage with at least `minimumCapacity` capacity.
  init(minimumCapacity: Int = 2) {
    assert(minimumCapacity >= 0, "minimumCapacity may not be negative")
    self.init(storage: Storage.create(round2(minimumCapacity)))
  }

  /// Initialize the buffer with the specied `storage`.
  init(storage: Storage) {
    self.storage = storage
    _initializedBuckets = storage.initializedBuckets
    values = storage.values
  }

  /// Returns the ideal bucket for `value`.
  func idealBucketForValue(value: Int) -> Bucket { return suggestBucketForValue(value, capacity: capacity) }

  /// Returns the bucket for `value` and whether the value is actually in the bucket.
  func find(value: Int, _ startBucket: Bucket? = nil) -> (bucket: Bucket, found: Bool) {
    var bucket = startBucket ?? idealBucketForValue(value)
    var result: (Bucket, Bool) = (bucket, false)

    repeat {
      guard isInitializedBucket(bucket) else { result = (bucket, false); break }
      guard valueInBucket(bucket) != value  else { result = (bucket, true); break }
      bucket._successorInPlace()
    } while true

//    print("\(#function) value: \(value); startBucket: \(startBucket?.description ?? "nil"); bucket: \(result.0); found: \(result.1)\n\(debugDescription)")
    return result
  }

  /// Returns the value in `bucket`.
  /// - requires: `bucket` is initialized
  func valueInBucket(bucket: Bucket) -> Int { return bucketPointer(bucket).memory }

  /// Returns the value in `bucket` or `nil` if the bucket is uninitialized.
  func maybeValueInBucket(bucket: Bucket) -> Int? {
    guard count > 0 && isInitializedBucket(bucket) else { return nil }
    return valueInBucket(bucket)
  }

  /// Returns whether `bucket` is initialized
  func isInitializedBucket(bucket: Bucket) -> Bool { return _initializedBuckets[bucket] }

  /// Removes the value in `bucket`, returning the bucket to an uninitialized state.
  /// - requires: `bucket` is initialized
  func destroyValueInBucket(bucket: Bucket) {
    assert(isInitializedBucket(bucket), "Cannot destroy the value in an uninitialized bucket")
    bucketPointer(bucket).destroy()
    _initializedBuckets[bucket] = false
  }

  /// Initializes `bucket` with `value`
  func initializeValue(value: Int, bucket: Bucket) {
    bucketPointer(bucket).initialize(value)
    _initializedBuckets[bucket] = true
  }

  /// Removes the value from `bucket1` and uses this value to initialize `bucket2`
  func moveValueInBucket(bucket1: Bucket, toBucket bucket2: Bucket) {
    assert(isInitializedBucket(bucket1), "Cannot move the value in an uninitialized bucket")
    bucketPointer(bucket2).initialize(bucketPointer(bucket1).move())
    _initializedBuckets[bucket1] = false
    _initializedBuckets[bucket2] = true
  }

}

extension OrderedSetHashMapBuffer : CustomStringConvertible, CustomDebugStringConvertible {

  var elementsDescription: String {
    if count == 0 { return "[]" }

//    print("buckets = \(buckets)")
    var result = "["
    var first = true
    for bucket in initializedBuckets {
      if first { first = false } else { result += ", " }
      debugPrint(valueInBucket(bucket), terminator: "",   toStream: &result)
    }
    result += "]"
    return result
  }

  var description: String { return elementsDescription }

  var debugDescription: String {
    var result = elementsDescription + "\n"
    result += "count = \(count)\n"
    result += "capacity = \(capacity)\n"
    for (i, bucket) in initializedBuckets.enumerate() {
      let value = valueInBucket(bucket)
      let idealBucket = idealBucketForValue(value)
      result += "[\(i)] bucket \(bucket), ideal bucket = \(idealBucket), value: \(value)\n"
    }
    return result
  }
}

/// Class responsible for the buffer and storage of `OrderedSetHashMap`. 
/// COW checks uniqueness of instances of this class
final class OrderedSetHashMapStorageOwner: NonObjectiveCBase {

  typealias Buffer = OrderedSetHashMapBuffer
  var buffer: Buffer

  convenience init(minimumCapacity: Int) { self.init(buffer: Buffer(minimumCapacity: minimumCapacity)) }
  init(buffer: Buffer) { self.buffer = buffer }

}

/// Generator for producing the hash values contained in an instance of `OrderedSetHashMapStorage`
struct OrderedSetHashMapGenerator: GeneratorType {
  typealias Index = OrderedSetHashMapIndex
  typealias Storage = OrderedSetHashMapStorage

  var index: Index
  var storage: Storage { return index.storage }
  init(storage: Storage) {
    index = Index(storage: storage, offset: -1).successor()
  }

  mutating func next() -> Int? {
    guard index.bucket.offset < index.bucket.capacity else { return nil }
    defer { index._successorInPlace() }
    return storage.values[index.bucket.offset]
  }
}

/// An index for a bucket in an instance of `OrderedSetHashMapStorage`
struct OrderedSetHashMapIndex: ForwardIndexType, Comparable {

  typealias Index = OrderedSetHashMapIndex
  typealias Storage = OrderedSetHashMapStorage
  
  let storage: Storage
  let initializedBuckets: BitMap
  let bucket: Bucket

  init(storage: Storage, offset: Int) {
    self.init(storage: storage, bucket: Bucket(offset: offset, capacity: storage.capacity))
  }

  init(storage: Storage, bucket: Bucket) {
    self.storage = storage
    self.bucket = bucket
    initializedBuckets = storage.initializedBuckets
  }

  @warn_unused_result
  func successor() -> Index {
    guard bucket.offset < bucket.capacity else { return self }
    var nextBucket = bucket
    repeat {
      nextBucket._successorInPlace()
      guard nextBucket.offset < nextBucket.capacity else { break }
    } while !initializedBuckets[nextBucket.offset]
    guard nextBucket > bucket else { return Index(storage: storage, offset: storage.capacity) }
    return Index(storage: storage, bucket: nextBucket)
  }
}

func ==(lhs: OrderedSetHashMapIndex, rhs: OrderedSetHashMapIndex) -> Bool {
  return lhs.bucket == rhs.bucket
}

func <(lhs: OrderedSetHashMapIndex, rhs: OrderedSetHashMapIndex) -> Bool {
  return lhs.bucket < rhs.bucket
}

/// An unordered collection of hash values \(`Int`\) used by `OrderedSet` to store an index of member hash values
struct OrderedSetHashMap {

  typealias Index = OrderedSetHashMapIndex
  typealias Generator = OrderedSetHashMapGenerator
  typealias Element = Int
  typealias _Element = Element
  typealias Storage = OrderedSetHashMapStorage
  typealias Buffer = OrderedSetHashMapBuffer
  typealias Owner = OrderedSetHashMapStorageOwner
  
  var buffer: Buffer { get { return owner.buffer } set { owner.buffer = newValue } }

  var storage: Storage { return buffer.storage }

  var owner: Owner

  func cloneBuffer(newCapacity: Int) -> Buffer {

    let clone = Buffer(minimumCapacity: newCapacity)

    if clone.capacity == buffer.capacity {
      for bucket in buffer.initializedBuckets {
        clone.initializeValue(buffer.valueInBucket(bucket), bucket: bucket)
      }
    } else {
      for bucket in buffer.initializedBuckets {
        let value = buffer.valueInBucket(bucket)
        let (bucket, found) = clone.find(value)
        assert(!found, "Duplicate value introduced: \(value)")
        clone.initializeValue(value, bucket: bucket)
      }
    }

    clone.count = buffer.count

    return clone
  }

  /// Checks that `owner` has only the one strong reference and that it's `buffer` has at least `minimumCapacity` capacity
  mutating func ensureUniqueWithCapacity(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool)
  {
    switch (isUnique: isUniquelyReferenced(&owner), hasCapacity: capacity >= minimumCapacity) {

      case (isUnique: true, hasCapacity: true):
        return (reallocated: false, capacityChanged: false)

      case (isUnique: true, hasCapacity: false):
        owner.buffer = cloneBuffer(Int(Double(minimumCapacity) * buffer.maxLoadFactorInverse))
        return (reallocated: true, capacityChanged: true)

      case (isUnique: false, hasCapacity: true):
        owner = Owner(buffer: cloneBuffer(capacity))
        return (reallocated: true, capacityChanged: false)

      case (isUnique: false, hasCapacity: false):
        owner = Owner(buffer: cloneBuffer(Int(Double(minimumCapacity) * buffer.maxLoadFactorInverse)))
        return (reallocated: true, capacityChanged: true)
    }

  }

  init(minimumCapacity: Int) { owner = Owner(minimumCapacity: minimumCapacity) }

  init(owner: Owner) { self.owner = owner }
  init(buffer: Buffer) { owner = Owner(buffer: buffer) }

  var startIndex: Index {
    let startIndex = Index(storage: storage, offset: -1).successor()
    return startIndex
  }

  var endIndex: Index {
    let endIndex = Index(storage: storage, offset: capacity)
    return endIndex
  }

  /// Caches the calculated `hashValue`
  private var _hashValue: UnsafeMutablePointer<Int> = nil

  var hashValue: Int {
    guard _hashValue == nil else { return _hashValue.memory }
    _hashValue.initialize(reduce(_mixInt(0)) { $0 ^ _mixInt($1) })
    return _hashValue.memory
  }

  @warn_unused_result
  func _customContainsEquatableElement(value: Int) -> Bool? { return contains(value) }

  @warn_unused_result
  func indexOf(value: Int) -> Index? {
    let (bucket, found) = buffer.find(value)
    guard found else { return nil }
    return Index(storage: storage, bucket: bucket)
  }

  @warn_unused_result
  func _customIndexOfEquatableElement(value: Element) -> Index?? {
    return Optional(indexOf(value))
  }

  subscript(index: Index) -> Int {
    precondition(buffer.isInitializedBucket(index.bucket), "Index invalid: \(index)")
    return buffer.valueInBucket(index.bucket)
  }

  @warn_unused_result
  func contains(value: Int) -> Bool { let (_, found) = buffer.find(value); return found }

  /// Remove `value` from `bucket` without checking for uniqueness, value or bucket
  /// - requires: `bucket` has been initialized with `value`
  mutating func _unsafeRemoveValue(value: Int, fromBucket bucket: Bucket) {
    buffer.destroyValueInBucket(bucket)
    buffer.count -= 1
    _hashValue = nil
//    print("\(#function) value '\(value)' removed from bucket '\(bucket)'")
    _patchHole(bucket, idealBucket: buffer.idealBucketForValue(value))
  }

  /// Remove the value in `bucket`
  /// - requires: `bucket` is initialized
  mutating func _removeValueInBucket(bucket: Bucket) {
    assert(buffer.isInitializedBucket(bucket), "invalid request to remove value in bucket '\(bucket)'")
    let value = buffer.valueInBucket(bucket)
    ensureUniqueWithCapacity(capacity)
    assert(isUniquelyReferenced(&owner), "We should have a unique owner at this point")
    _unsafeRemoveValue(value, fromBucket: bucket)
  }

  /// Attempts to move the values of the buckets near `hole` into buckets nearer to their 'ideal' bucket
  func _patchHole(hole: Bucket, idealBucket: Bucket) {
    assert(!buffer.isInitializedBucket(hole), "Hole to path is initialized: '\(hole)'")
//    print("\(#function) before patching hole '\(hole)' with ideal bucket '\(idealBucket)': \(buffer.debugDescription)")
    var hole = hole
    var start = idealBucket
    while buffer.isInitializedBucket(start.predecessor()) { start._predecessorInPlace() }

    var lastInChain = hole
    var last = lastInChain.successor()
    while buffer.isInitializedBucket(last) { lastInChain = last; last._successorInPlace() }

    while hole != lastInChain {
      last = lastInChain
      FillHole: while last != hole {
        let value = buffer.valueInBucket(last)
        let bucket = buffer.idealBucketForValue(value)

        switch (bucket >= start, bucket <= hole) {
          case (true, true) where start <= hole,
               (true, _)    where start > hole,
               (_, true)    where start > hole:
            break FillHole
          default:
            last._predecessorInPlace()
        }
      }
      guard last != hole else { break }
      buffer.moveValueInBucket(last, toBucket: hole)
      hole = last
    }

//    print("\(#function) after patching hole: \(buffer.debugDescription)")
  }

  /// Locates the bucket for `value` and removes that value, optionally initializing `oldValue` with th
  mutating func _removeValue(value: Int) {
    let (bucket, found) = buffer.find(value)
//    print("\(#function) value = \(value); bucket = \(bucket), found = \(found)")
    guard found else { return }
    _removeValueInBucket(bucket)
  }

  /// Attempts to locate and remove `value`, returning `value` if found and `nil` otherwise
  mutating func remove(value: Int) -> Int? {
    defer { _removeValue(value) }
    return contains(value) ? value : nil
  }

  /// Removes and returns the first value
  /// - requires: That at least one bucket has been initialized with a value
  mutating func removeFirst() -> Int {
    guard let firstValue = first else {
      fatalError("removeFirst() requires the collection not be empty")
    }
    _removeValue(firstValue)
    return firstValue
  }

  /// - requires: Guaranteed uniqueness and capacity
  mutating func _unsafeInsertValue(value: Int, inBucket bucket: Bucket) {
    buffer.initializeValue(value, bucket: bucket)
    buffer.count += 1
    _hashValue = nil
  }

  /// - requires: `value` is not already a member
  mutating func _insertValue(value: Int, inBucket bucket: Bucket) {
    assert(!contains(value), "Request to insert duplicate value '\(value)'")
    let minimumCapacity = max(Int(Double(count + 1) * buffer.maxLoadFactorInverse), count + 1)
    let (_, capacityChanged) = ensureUniqueWithCapacity(minimumCapacity)
    assert(isUniquelyReferenced(&owner), "We should have a unique owner at this point")


    _unsafeInsertValue(value,
                       inBucket: capacityChanged
                                   ? findBucketForValue(value,
                                                        capacity: buffer.capacity,
                                                        initializedBuckets: buffer._initializedBuckets)
                                   : bucket)
  }

  /// Inserts `value` if `value` is not already a member
  mutating func insert(value: Int) {
    let minimumCapacity = max(Int(Double(count + 1) * buffer.maxLoadFactorInverse), count + 1)
    ensureUniqueWithCapacity(minimumCapacity)
    let (bucket, found) = buffer.find(value)
    guard !found else { return }
    _insertValue(value, inBucket: bucket)
  }

  var count: Int { return buffer.count }
  var capacity: Int { return buffer.capacity }

  func generate() -> Generator {
//    var bucketGenerator = buffer.initializedBuckets.nonZeroBits.generate()
//    let storage = buffer.storage
//    return AnyGenerator {
//      guard let bucket = bucketGenerator.next() else { return nil }
//      return (storage.values + bucket).memory
//    }

    return Generator(storage: storage)
  }

  var isEmpty: Bool { return count == 0 }

  var first: Int? {
    guard let bucket = buffer.initializedBuckets.first else { return nil }
    return buffer.valueInBucket(bucket)
  }

  /// Remove and return the first value, or nil if there are no values
  mutating func popFirst() -> Element? { guard count > 0 else { return nil }; return removeFirst() }

}

extension OrderedSetHashMap: SetType {

  /// Checks whether enough memory has been allocated for `capacity` values and grows storage if not
  mutating func reserveCapacity(capacity: Int) { ensureUniqueWithCapacity(capacity) }

  init<S : SequenceType where S.Generator.Element == Int>(_ elements: S) {
    if let hashMap = elements as? OrderedSetHashMap {
      self.init(owner: hashMap.owner)
    } else {
      self.init(minimumCapacity: elements.underestimateCount())
      for element in elements {
        if (count + 1) == capacity { reserveCapacity(Int(Double(count + 1) * buffer.maxLoadFactorInverse)) }
        let (bucket, found) = buffer.find(element)
        guard !found else { continue }
        _unsafeInsertValue(element, inBucket: bucket)
      }
    }
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set`.
  @warn_unused_result
  func isSubsetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    let hashMap = sequence as? Set<Int> ?? Set(sequence)
    for value in self where !hashMap.contains(value) { return false }
    return true
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    let hashMap = sequence as? Set<Int> ?? Set(sequence)
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
    let hashMap = sequence as? Set<Int> ?? Set(sequence)
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
      assert(isUniquelyReferenced(&owner), "We should have a unique owner at this point")
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

    for value in sequence {
      remove(value)
    }
//    var checkedUnique = false
//    let hashMap = sequence as? Set<Int> ?? Set(sequence)
//    for value in self where hashMap.contains(value) {
//
////    print("\n\(#function) - subtracting these values from other:\n\(hashMap)\n\n\(#function) - from these values from self:\n\(self)")
//      if !checkedUnique {
//        let (_, capacityChanged) = ensureUniqueWithCapacity(capacity)
//        assert(!capacityChanged, "The only reason to reallocate should be if we weren't unique")
//        checkedUnique = true
//      }
//      assert(isUniquelyReferenced(&owner), "We should have a unique owner at this point")
//      let (bucket, found) = buffer.find(value)
//      assert(found, "We seem to have misplaced value '\(value)'")
//      _unsafeRemoveValue(value, fromBucket: bucket)
//    }
//    if checkedUnique { _hashValue = nil }
////    print("\n\(#function) - resulting hash map:\n\(self)")
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
    let hashMap = sequence as? Set<Int> ?? Set(sequence)
    var checkedUnique = false
    for value in self where !hashMap.contains(value) {

      if !checkedUnique { ensureUniqueWithCapacity(capacity); checkedUnique = true }
      assert(isUniquelyReferenced(&owner), "We should have a unique owner at this point")
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
      if first { first = false } else { result += ", " }
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
