
//
//  OrderedSetHashMap.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/23/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

//NOTE: Attempted to create a specialized Set type to store hash values but its performance doesn't come close to stdlib Set
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

  /// A bit map corresponding to which buckets have been initialized
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

//struct Bucket: BidirectionalIndexType, Comparable {
//  let offset: Int
//  let capacity: Int
//
//  func predecessor() -> Bucket {
//    return Bucket(offset: (offset &- 1) & (capacity &- 1), capacity: capacity)
//  }
//
//  func successor() -> Bucket {
//    return Bucket(offset: (offset &+ 1) & (capacity &- 1), capacity: capacity)
//  }
//}
//
//extension Bucket: CustomStringConvertible {
//  var description: String { return "\(offset)" }
//}
//
//func ==(lhs: Bucket, rhs: Bucket) -> Bool { return lhs.offset == rhs.offset }
//func <(lhs: Bucket, rhs: Bucket) -> Bool { return lhs.offset < rhs.offset }
//
//
///// Returns the hash value of `value` squeezed into `capacity`
//func suggestBucketForValue(value: Int, capacity: Int) -> Bucket {
//  return Bucket(offset: _squeezeHashValue(value.hashValue, 0 ..< capacity), capacity: capacity)
//}
//
///// - requires: `initializedBuckets` has an empty bucket (to avoid an infinite loop)
//func findBucketForValue(value: Int, capacity: Int, initializedBuckets: BitMap) -> Bucket {
//  var bucket = suggestBucketForValue(value, capacity: capacity)
//  repeat {
//    guard initializedBuckets[bucket.offset] else { return bucket }
//    bucket._successorInPlace()
//  } while true
//}
//
//extension BitMap {
//  subscript(bucket: Bucket) -> Bool {
//    get { return self[bucket.offset] }
//    nonmutating set { self[bucket.offset] = newValue }
//  }
//}

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
  typealias Generator = AnyGenerator<Int> //OrderedSetHashMapGenerator
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

  /// Copys buffer if `owner` is not uniquely referenced.
  /// - returns: `true` if the buffer was copied and `false` otherwise
  mutating func ensureUnique() -> Bool {
    guard !isUniquelyReferenced(&owner) else { return false }
    owner = Owner(buffer: cloneBuffer(capacity))
    return true
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
    let values = buffer.initializedBuckets.map { buffer.valueInBucket($0) }
    return AnyGenerator(values.generate())

//    return Generator(storage: storage)
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

    var guaranteedUnique = false

    for value in sequence {
      guard contains(value) else { continue }
      if !guaranteedUnique { ensureUnique(); _hashValue = nil; guaranteedUnique = true  }

      assert(isUniquelyReferenced(&owner), "We should have a unique owner at this point")
      let (bucket, found) = buffer.find(value)
      assert(found, "We seem to have misplaced value '\(value)'")
      _unsafeRemoveValue(value, fromBucket: bucket)
    }
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
