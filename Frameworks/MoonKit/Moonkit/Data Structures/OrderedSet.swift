//
//  OrderedSet.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/30/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

// MARK: - Storage
// MARK: -

private let maxLoadFactorInverse = 1/0.75

struct OrderedSetStorageHeader: CustomStringConvertible {
  var count: Int = 0
  let capacity: Int
  let bytesAllocated: Int
  let initializedBuckets: BitMap
  let bucketPositionMap: BucketPositionMap

  init(capacity: Int,
       bytesAllocated: Int,
       initializedBuckets: BitMap,
       bucketPositionMap: BucketPositionMap)
  {
    self.capacity = capacity
    self.bytesAllocated = bytesAllocated
    self.initializedBuckets = initializedBuckets
    self.bucketPositionMap = bucketPositionMap
  }

  var description: String {
    return "\n".join("count: \(count)",
                     "capacity: \(capacity)",
                     "bytesAllocated: \(bytesAllocated)",
                     "initializedBuckets: \(initializedBuckets)",
                     "bucketPositionMap: \(bucketPositionMap)")
  }
}

struct Bucket: BidirectionalIndexType, Comparable, Hashable {
  let offset: Int
  let capacity: Int

  func predecessor() -> Bucket {
    return Bucket(offset: (offset &- 1) & (capacity &- 1), capacity: capacity)
  }

  func successor() -> Bucket {
    return Bucket(offset: (offset &+ 1) & (capacity &- 1), capacity: capacity)
  }

  var hashValue: Int { return offset ^ capacity }
}

extension Bucket: CustomStringConvertible {
  var description: String { return "\(offset)" }
}

func ==(lhs: Bucket, rhs: Bucket) -> Bool { return lhs.offset == rhs.offset }
func <(lhs: Bucket, rhs: Bucket) -> Bool { return lhs.offset < rhs.offset }


/// Returns the hash value of `value` squeezed into `capacity`
func suggestBucketForValue<H:Hashable>(value: H, capacity: Int) -> Bucket {
  return Bucket(offset: _squeezeHashValue(value.hashValue, 0 ..< capacity), capacity: capacity)
}

/// - requires: `initializedBuckets` has an empty bucket (to avoid an infinite loop)
func findBucketForValue<H:Hashable>(value: H, capacity: Int, initializedBuckets: BitMap) -> Bucket {
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

struct BucketPositionMap: CollectionType {

  typealias BucketOffset = Int
  typealias PositionOffset = Int
  typealias Index = Int
  typealias _Element = Bucket

  let capacity: Int
  let buckets: UnsafeMutableBufferPointer<PositionOffset>
  let positions: UnsafeMutableBufferPointer<BucketOffset>

  let _endIndex = UnsafeMutablePointer<Index>.alloc(1)

  let startIndex: Index = 0

  var endIndex: Index {
    get { return _endIndex.memory }
    nonmutating set { _endIndex.memory = newValue }
  }

  var count: Int { return endIndex - startIndex }

  /// Initialize with a pointer to the storage to use and its represented capacity as an element count.
  init(storage: UnsafeMutablePointer<Int>, capacity: Int) {
    self.capacity = capacity
    positions = UnsafeMutableBufferPointer<BucketOffset>(start: storage, count: capacity)
    buckets = UnsafeMutableBufferPointer<PositionOffset>(start: storage + capacity, count: capacity)
    _endIndex.initialize(0)
    initializeToNegativeOne()
  }

  /// Initializes `positions` and `buckets` with `-1` and all bits in `emptyPositions` with `1`
  func initializeToNegativeOne() {
    positions.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
    buckets.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
  }

  /// Accessor for the index of a specified index.
  subscript(bucket: Bucket) -> Index? {
    let index = buckets[bucket.offset]
    return index > -1 ? index : nil
  }

  /// Accessors for getting and setting the bucket at a specified index.
  subscript(index: Index) -> Bucket {
    get {
      return Bucket(offset: positions[index], capacity: capacity)
    }
    nonmutating set {
      if index == endIndex { appendBucket(newValue) }
      else { updateBucket(newValue, at: index) }
    }
  }

  /// Removes `bucket1` by inserting `bucket2` and giving it `bucket1`'s position
  /// - requires: `bucket1` has been assigned a position
  func replaceBucket(bucket1: Bucket, with bucket2: Bucket) {
    let oldBucketOffset = bucket1.offset
    let bucketOffset = bucket2.offset
    let positionOffset = buckets[oldBucketOffset]
    positions[positionOffset] = bucketOffset
    buckets[oldBucketOffset] = -1
    buckets[bucketOffset] = positionOffset
  }


  /// Assigns `bucket` to `index`, removing the previously assigned bucket.
  /// - requires: `index ∋ startIndex..<endIndex`
  func updateBucket(bucket: Bucket, at index: Index) {

    let bucketOffset = bucket.offset
    let oldBucketOffset = positions[index]
    guard oldBucketOffset != bucketOffset else { return }

    buckets[oldBucketOffset] = -1
    positions[index] = bucketOffset
    buckets[bucketOffset] = index

  }

  /// Assigns `bucket` to `endIndex`.
  /// - requires: `endIndex < capacity`
  /// - postcondition: `count = count + 1`
  func appendBucket(bucket: Bucket) {
    positions[endIndex] = bucket.offset
    buckets[bucket.offset] = endIndex
    endIndex += 1
  }

  /// Removes the bucket assigned to `index`.
  /// - requires: `index ∋ startIndex..<endIndex`
  /// - postcondition: count = count - 1
  func removeBucketAt(index: Index) {
    let bucketOffset = positions[index]
    buckets[bucketOffset] = -1
    for moveIndex in index.successor() ..< endIndex {
      let previousIndex = moveIndex.predecessor()
      buckets[positions[moveIndex]] = previousIndex
      swap(&positions[moveIndex], &positions[previousIndex])
    }
    endIndex -= 1
  }

  subscript(bounds: Range<Index>) -> [Bucket] {
    get { return positions[bounds].map {Bucket(offset: $0, capacity: capacity) } }
    set { replaceRange(bounds, with: newValue) }
  }

  func insertContentsOf<
    C:CollectionType where C.Generator.Element == Bucket
    >(newElements: C, at index: Int)
  {
    let shiftAmount = numericCast(newElements.count) as Int
    shiftPositionsFrom(index, by: shiftAmount)

    (positions.baseAddress + index).initializeFrom(newElements.map { $0.offset })
    for position in index ..< endIndex { buckets[positions[position]] = position }
  }

  func shiftPositionsFrom(from: Int, by amount: Int) {
    let count = endIndex - from
    let source = positions.baseAddress + from
    let destination = source + amount
    if amount < 0 {
      destination.moveInitializeFrom(source, count: count)
      (destination + count).initializeFrom(Repeat(count: abs(amount), repeatedValue: -1))
    } else {
      destination.moveInitializeBackwardFrom(source, count: count)
      source.initializeFrom(Repeat(count: amount, repeatedValue: -1))
    }
    endIndex += amount
    for position in (from + amount) ..< endIndex {
      buckets[positions[position]] = position
    }
  }

  /// Replaces buckets assigned to positions in `subRange` with `newElements`
  /// - requires: `newElements` contains unique values.
  func replaceRange<
    C:CollectionType
    where
    C.Generator.Element == Bucket,
    C.SubSequence.Generator.Element == Bucket,
    C.SubSequence:CollectionType
    >(subRange: Range<Index>, with newElements: C)
  {
    let removeCount = subRange.count
    let insertCount = numericCast(newElements.count) as Int

    // Replace n values where n = max(subRange.count, newElements.count)
    for (index, bucket) in zip(subRange, newElements) {
      let oldBucketOffset = positions[index]
      if oldBucketOffset > -1 && buckets[oldBucketOffset] == index {
        buckets[oldBucketOffset] = -1
      }
      let newBucketOffset = bucket.offset
      positions[index] = newBucketOffset
      buckets[newBucketOffset] = index
    }

    switch insertCount - removeCount {
    case 0:
      // Nothing more to do
      break

    case let delta where delta < 0:
      // Empty remaining positions in `subRange`

      for index in subRange.endIndex.advancedBy(delta) ..< subRange.endIndex {
        let oldBucketOffset = positions[index]
        positions[index] = -1
        let oldPosition = buckets[oldBucketOffset]
        guard oldPosition == index else { continue }
        buckets[oldBucketOffset] = -1
      }

      shiftPositionsFrom(subRange.endIndex, by: delta)

    default: /*case let delta where delta < 0*/
      // Insert remaining values

      insertContentsOf(newElements.dropFirst(removeCount), at: subRange.endIndex)

    }
  }
  
}

extension BucketPositionMap: CustomStringConvertible, CustomDebugStringConvertible {
  var description: String {
    var result = "["

    var first = true
    for i in startIndex ..< endIndex {
      if first { first = false } else { result += ", " }
      result += String(positions[i])
    }
    result += "]"

    return result
  }

  var debugDescription: String {
    var result = "startIndex: \(startIndex); endIndex: \(endIndex)\n"
    result += "positions: [\n"

    var first = true
    for position in 0 ..< capacity {
      let bucketOffset = positions[position]
      guard bucketOffset > -1 else { continue }
      if first { first = false } else { result += ",\n" }
      result += "\t\(position): \(bucketOffset)"
    }
    result += "]\nbuckets: [\n"
    first = true
    for bucket in 0 ..< capacity {
      let position = buckets[bucket]
      guard position > -1 else { continue }
      if first { first = false } else { result += ",\n" }
      result += "\t\(bucket): \(position)"
    }
    result += "]"
    return result
  }
  
}

final class OrderedSetStorage<Element:Hashable>: ManagedBuffer<OrderedSetStorageHeader, UInt8> {

  typealias Storage = OrderedSetStorage<Element>
  typealias Header = OrderedSetStorageHeader

  /// Returns the number of bytes required for the bit map of initialized buckets given `capacity`
  static func bytesForInitializedBuckets(capacity: Int) -> Int {
    return BitMap.wordsFor(capacity) * sizeof(UInt) + alignof(UInt)
  }

  /// The number of bytes used to store the bit map of initialized buckets for this instance
  var initializedBucketsBytes: Int { return Storage.bytesForInitializedBuckets(capacity) }

  /// Returns the number of bytes required for the map of buckets to positions given `capacity`
  static func bytesForBucketPositionMap(capacity: Int) -> Int {
    return strideof(Int) * (capacity * 2) + max(0, alignof(Int) - alignof(UInt))
  }

  var bucketPositionMapBytes: Int { return Storage.bytesForBucketPositionMap(capacity) }

  static func bytesForElements(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Element) - maxPrevAlignment)
    return strideof(Element) * capacity + padding
  }

  /// The number of bytes used to store the hash values for this instance
  var membersBytes: Int { return Storage.bytesForElements(capacity) }

  /// The total number of buckets
  var capacity: Int { return value.capacity }

  /// The total number of initialized buckets
  var count: Int { get { return value.count } set { value.count = newValue } }

  /// The total number of bytes managed by this instance; equal to 
  /// `initializedBucketsBytes + bucketMapBytes + membersBytes`
  var bytesAllocated: Int { return value.bytesAllocated }

  /// Pointer to the first byte in memory allocated for the bit map of initialized buckets
  var initializedBucketsAddress: UnsafeMutablePointer<UInt8> {
    return withUnsafeMutablePointerToElements {$0}
  }

  /// A bit map corresponding to which buckets have been initialized
  var initializedBuckets: BitMap { return value.initializedBuckets }

  /// Pointer to the first byte in memory allocated for the position map
  var bucketPositionMapAddress: UnsafeMutablePointer<UInt8> {
    return initializedBucketsAddress + initializedBucketsBytes
  }

  /// An index mapping buckets to positions and positions to buckets
  var bucketPositionMap: BucketPositionMap { return value.bucketPositionMap }

  /// Pointer to the first byte in memory allocated for the hash values
  var members: UnsafeMutablePointer<Element> {
    return UnsafeMutablePointer<Element>(bucketPositionMapAddress + bucketPositionMapBytes)
  }

  static func create(minimumCapacity: Int) -> OrderedSetStorage {
    let capacity = round2(minimumCapacity)

    let initializedBucketsBytes = bytesForInitializedBuckets(capacity)
    let bucketPositionMapBytes = bytesForBucketPositionMap(capacity)
    let membersBytes = bytesForElements(capacity)
    let requiredCapacity = initializedBucketsBytes
                         + bucketPositionMapBytes
                         + membersBytes

    let storage = super.create(requiredCapacity) {
      let initializedBucketsStorage = $0.withUnsafeMutablePointerToElements {$0}
      let initializedBuckets = BitMap(uninitializedStorage: pointerCast(initializedBucketsStorage), bitCount: capacity)
      let bucketPositionMapStorage = initializedBucketsStorage + initializedBucketsBytes
      let bucketPositionMap = BucketPositionMap(storage: pointerCast(bucketPositionMapStorage), capacity: capacity)
      let bytesAllocated = $0.allocatedElementCount
      let header =  Header(capacity: capacity,
                    bytesAllocated: bytesAllocated,
                    initializedBuckets: initializedBuckets,
                    bucketPositionMap: bucketPositionMap)
      return header
    }

    return storage as! Storage
  }

  deinit {
    guard !_isPOD(Element) else { return }
    defer { _fixLifetime(self) }
    let members = self.members
    for offset in initializedBuckets.nonZeroBits { (members + offset).destroy() }
  }
}

extension OrderedSetStorage {
  var description: String {
    defer { _fixLifetime(self) }
    var result = "OrderedSetStorage {\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tinitializedBucketsBytes: \(initializedBucketsBytes)\n"
    result += "\tbucketMapBytes: \(bucketPositionMapBytes)\n"
    result += "\tmembersBytes: \(membersBytes)\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tinitializedBuckets: \(initializedBuckets)\n"
    result += "\tbucketPositionMap: \(bucketPositionMap)\n"
    result += "\tmembers: \(Array(UnsafeBufferPointer(start: members, count: count)))\n"
    result += "\n}"
    return result
  }
}

// MARK: - Generator
// MARK: -

public struct OrderedSetGenerator<Element:Hashable>: GeneratorType {
  typealias Buffer = OrderedSetBuffer<Element>
  let buffer: Buffer
  var index: Int = 0
  init(buffer: Buffer) { self.buffer = buffer }

  public mutating func next() -> (Element)? {
    guard index < buffer.count else { return nil }
    defer { index = index.successor() }
    return buffer.memberAtPosition(index)
  }
}

struct OrderedSetBuffer<Element:Hashable> {

  typealias Index = Int
  typealias Generator = OrderedSetGenerator<Element>

  typealias Buffer = OrderedSetBuffer<Element>
  typealias Storage = OrderedSetStorage<Element>

  // MARK: Pointers to the underlying memory

  let storage: Storage
  let initializedBuckets: BitMap
  let bucketPositionMap: BucketPositionMap
  let members: UnsafeMutablePointer<Element>

  // MARK: Accessors for the storage header properties

  var capacity: Int { return storage.capacity }

  var count: Int {
    get { return storage.count }
    nonmutating set { storage.count = newValue }
  }

  // MARK: Initializing by capacity

  init(minimumCapacity: Int = 2) {
    self.init(storage: Storage.create(Buffer.minimumCapacityForCount(minimumCapacity)))
  }

  static func minimumCapacityForCount(count: Int) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  // MARK: Initializing with data

  init(storage: Storage) {
    self.storage = storage
    initializedBuckets = storage.initializedBuckets
    members = storage.members
    bucketPositionMap = storage.bucketPositionMap
  }

  init<S:SequenceType where S.Generator.Element == Element>(elements: S, capacity: Int? = nil) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.underestimateCount())
    let requiredCapacity = max(minimumCapacity, capacity ?? 0)
    let buffer = Buffer(minimumCapacity: requiredCapacity)

    var count = 0
    var duplicates = 0

    for (position, member) in elements.enumerate() {
      let (bucket, found) = buffer.find(member)
      if found {
        duplicates += 1
        continue
      } else {
        buffer.initializeElement(member, position: position - duplicates, bucket: bucket)
        count += 1
      }
    }
    buffer.count = count

    self = buffer
  }


  // MARK: Queries

  /// Returns the bucket for `member` diregarding collisions
  func idealBucketForElement(member: Element) -> Bucket {
    return suggestBucketForValue(member, capacity: capacity)
  }

  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
  func positionForBucket(bucket: Bucket) -> Index? {
    return bucketPositionMap[bucket]
  }

  /// Returns the bucket for the member assigned to `position`.
  /// - requires: A bucket has been assigned to `position`
  func bucketForPosition(position: Index) -> Bucket {
    return bucketPositionMap[position]
  }

  /// Returns the bucket containing `member` or `nil` if no bucket contains `member`.
  func currentBucketForElement(member: Element) -> Bucket? {
    let (bucket, found) = find(member)
    return found ? bucket : nil
  }

  /// Returns an empty bucket suitable for holding `member` or `nil` if a bucket already contains `member`.
  func emptyBucketForElement(member: Element) -> Bucket? {
    let (bucket, found) = find(member)
    return found ? nil : bucket
  }

  /// Returns the current bucket for `member` and `true` when `member` is located; 
  /// returns an open bucket for `member` and `false` otherwise
  /// - requires: At least one empty bucket
  func find(member: Element) -> (bucket: Bucket, found: Bool) {

    let startBucket = idealBucketForElement(member)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard memberInBucket(bucket) != member  else { return (bucket, true) }
      bucket._successorInPlace()
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  /// Returns the value inserted into `bucket`
  func memberInBucket(bucket: Bucket) -> Element { return members[bucket.offset] }

  /// Returns the value assigned to `position`
  func memberAtPosition(position: Index) -> Element {
    return memberInBucket(bucketForPosition(position))
  }

  /// Returns `false` when `bucket` is empty and `true` otherwise.
  func isInitializedBucket(bucket: Bucket) -> Bool { return initializedBuckets[bucket] }

  /// Returns the position for `member` or `nil` if `member` is not found.
  func positionForElement(member: Element) -> Index? {
    guard count > 0, let bucket = currentBucketForElement(member) else { return nil }
    return positionForBucket(bucket)
  }

  // MARK: Removing data

  /// Attempts to move the values of the buckets near `hole` into buckets nearer to their 'ideal' bucket
  func _patchHole(hole: Bucket, idealBucket: Bucket) {

    var hole = hole
    var start = idealBucket
    while isInitializedBucket(start.predecessor()) { start._predecessorInPlace() }

    var lastInChain = hole
    var last = lastInChain.successor()
    while isInitializedBucket(last) { lastInChain = last; last._successorInPlace() }

    while hole != lastInChain {
      last = lastInChain
      FillHole: while last != hole {
        let value = memberInBucket(last)
        let bucket = idealBucketForElement(value)

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
      moveElementInBucket(last, toBucket: hole)
      hole = last
    }

  }

  func destroyBucket(bucket: Bucket) {
    initializedBuckets[bucket] = false
    (members + bucket.offset).destroy()
  }

  func destroyElementAt(position: Index) {
    defer { _fixLifetime(self) }
    let hole = bucketForPosition(position)
    let idealBucket = idealBucketForElement(memberInBucket(hole))

    destroyBucket(hole)
    bucketPositionMap.removeBucketAt(position)

    count -= 1

    _patchHole(hole, idealBucket: idealBucket)

  }

  /// - requires: A member has been assigned to `position`
  func replaceElementAtPosition(position: Index, with member: Element) {
    let bucket = bucketForPosition(position)
    guard memberInBucket(bucket) != member else { return }
    guard let emptyBucket = emptyBucketForElement(member) else {
      fatalError("failed to locate an empty bucket for '\(member)'")
    }
    destroyBucket(bucket)
    initializeElement(member, position: position, bucket: emptyBucket)
  }

  func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    defer { _fixLifetime(self) }

    // Remove values from buckets in `subRange`

    subRange.forEach { destroyBucket(bucketForPosition($0)) }


    // Insert new elements, accumulating a list of their buckets
    var newElementsBuckets = [Bucket](minimumCapacity: numericCast(newElements.count))

    for value in newElements {
      let (bucket, found) = find(value)
      guard !found else { continue }
      initializeBucket(bucket, with: value)
      newElementsBuckets.append(bucket)
    }

    // Adjust positions
    bucketPositionMap.replaceRange(subRange, with: newElementsBuckets)

    // Update count
    storage.count = bucketPositionMap.count

  }


  // MARK: Initializing with data

  func initializeBucket(bucket: Bucket, with member: Element) {
    (members + bucket.offset).initialize(member)
    initializedBuckets[bucket] = true
  }

  func initializeElement(member: Element, position: Int, bucket: Bucket) {
    defer { _fixLifetime(self) }
    initializeBucket(bucket, with: member)
    bucketPositionMap[position] = bucket
  }

  func initializeElement(member: Element, position: Int) {
    let (bucket, _) = find(member)
    initializeElement(member, position: position, bucket: bucket)
  }

  func initializeElement(member: Element, bucket: Bucket) {
    initializeElement(member, position: count, bucket: bucket)
  }

  /// Removes the value from `bucket1` and uses this value to initialize `bucket2`
  func moveElementInBucket(bucket1: Bucket, toBucket bucket2: Bucket) {
    initializeBucket(bucket2, with: (members + bucket1.offset).move())
    initializedBuckets[bucket1] = false
    bucketPositionMap.replaceBucket(bucket1, with: bucket2)
  }


}

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension OrderedSetBuffer : CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    if count == 0 { return "[:]" }

    var result = "["
    var first = true
    for bucket in bucketPositionMap {
      if first { first = false } else { result += ", " }
      debugPrint(members[bucket.offset], terminator: "",   toStream: &result)
    }
    result += "]"
    return result
  }

  var description: String { return elementsDescription }

  var debugDescription: String {
    var result = elementsDescription + "\n"
    result += "count = \(count)\n"
    result += "capacity = \(capacity)\n"
    for position in 0 ..< count {
      result += "position \(position) ➞ bucket \(bucketPositionMap[position])\n"
    }
    for position in count ..< capacity {
      result += "position \(position), empty\n"
    }
    for bucket in 0 ..< capacity {
      if initializedBuckets[bucket] {
        let member = members[bucket]
        result += "bucket \(bucket), ideal bucket = \(idealBucketForElement(member))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }
}

// MARK: - Owner
// MARK: -

final class OrderedSetStorageOwner<Element:Hashable>: NonObjectiveCBase {

  typealias Buffer = OrderedSetBuffer<Element>
  var buffer: Buffer
  init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }
  init(buffer: Buffer) { self.buffer = buffer }
}

// MARK: - SubSequence
// MARK: -

public struct OrderedSetSlice<Element:Hashable>: CollectionType {
  public typealias Index = Int
  typealias Buffer = OrderedSetBuffer<Element>
  public var startIndex: Int { return bounds.startIndex }
  public var endIndex: Int  { return bounds.endIndex }
  let buffer: Buffer
  let bounds: Range<Int>
  public subscript(position: Index) -> Element { return buffer.memberAtPosition(position) }
  init(buffer: Buffer, bounds: Range<Int>) {
    precondition(bounds.startIndex >= 0, "Invalid start for bounds: \(bounds.startIndex)")
    precondition(bounds.endIndex <= buffer.count, "Invalid end for bounds: \(bounds.endIndex)")
    self.buffer = buffer
    self.bounds = bounds
  }
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
}


// MARK: - OrderedSet
// MARK: -

/// A hash-based mapping from `Key` to `Element` instances that preserves elment order.
public struct OrderedSet<Element:Hashable>: CollectionType {

  public typealias _Element = Element
  typealias Storage = OrderedSetStorage<Element>
  typealias Buffer = OrderedSetBuffer<Element>
  typealias Owner = OrderedSetStorageOwner<Element>

  var buffer: Buffer {
    get { return owner.buffer }
    set { owner.buffer = newValue }
  }

  var owner: Owner


  func cloneBuffer(newCapacity: Int) -> Buffer {

    let clone = Buffer(minimumCapacity: newCapacity)

    if clone.capacity == buffer.capacity {
      for (position, bucket) in buffer.bucketPositionMap.enumerate() {
        clone.initializeElement(buffer.memberInBucket(bucket), position: position, bucket: bucket)
      }
    } else {
      for (position, bucket) in buffer.bucketPositionMap.enumerate() {
        clone.initializeElement(buffer.memberInBucket(bucket), position: position)
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
        owner.buffer = cloneBuffer(Int(Double(minimumCapacity) * maxLoadFactorInverse))
        return (reallocated: true, capacityChanged: true)

      case (isUnique: false, hasCapacity: true):
        owner = Owner(buffer: cloneBuffer(capacity))
        return (reallocated: true, capacityChanged: false)

      case (isUnique: false, hasCapacity: false):
        owner = Owner(buffer: cloneBuffer(Int(Double(minimumCapacity) * maxLoadFactorInverse)))
        return (reallocated: true, capacityChanged: true)
    }

  }

  public init(minimumCapacity: Int) { owner = Owner(minimumCapacity: minimumCapacity) }

  init(buffer: Buffer) { owner = Owner(buffer: buffer) }

  public var hashValue: Int {
    // FIXME: <rdar://problem/18915294> Cache Set<T> hashValue
    var result: Int = _mixInt(0)
    for member in self {
      result ^= _mixInt(member.hashValue)
    }
    return result
  }

  @warn_unused_result
  public func _customContainsEquatableElement(member: Element) -> Bool? {
    return contains(member)
  }

  @warn_unused_result
  public func _customIndexOfEquatableElement(member: Element) -> Index?? {
    return Optional(indexOf(member))
  }
  

  public func indexOf(member: Element) -> Index? { return buffer.positionForElement(member) }

  @warn_unused_result
  public func contains(member: Element) -> Bool { let (_, found) = buffer.find(member); return found }

  mutating func _removeAtIndex(index: Index, oldElement: UnsafeMutablePointer<Element>) {
    if oldElement != nil { oldElement.initialize(buffer.memberInBucket(buffer.bucketForPosition(index))) }
    ensureUniqueWithCapacity(capacity)
    buffer.destroyElementAt(index)
  }

  public mutating func removeAtIndex(index: Index) -> Element {
    let oldElement = UnsafeMutablePointer<Element>.alloc(1)
    _removeAtIndex(index, oldElement: oldElement)
    return oldElement.memory
  }

  mutating func _removeElement(member: Element, oldElement: UnsafeMutablePointer<Element?>) {
    guard let index = buffer.positionForElement(member) else {
      if oldElement != nil { oldElement.initialize(nil) }
      return
    }
    if oldElement != nil {
      let oldElement = UnsafeMutablePointer<Element>.alloc(1)
      _removeAtIndex(index, oldElement: oldElement)
      oldElement.initialize(oldElement.memory)
    } else {
      _removeAtIndex(index, oldElement: nil)
    }
  }

  public mutating func removeFirst() -> Element { return removeAtIndex(0) }

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public var isEmpty: Bool { return count == 0 }

  public var first: Element? { guard count > 0 else { return nil }; return buffer.memberAtPosition(0) }

  public mutating func popFirst() -> Element? { guard count > 0 else { return nil }; return removeAtIndex(0) }

}

extension OrderedSet: MutableIndexable {

  public typealias Index = Int

  public var startIndex: Index { return 0 }

  public var endIndex: Index { return count }

  public subscript(index: Index) -> Element {
    get { return buffer.memberAtPosition(index) }
    set { buffer.replaceElementAtPosition(index, with: newValue) }
  }

}

extension OrderedSet: SequenceType {

  public typealias Generator = OrderedSetGenerator<Element>
  public typealias SubSequence = OrderedSetSlice<Element>

  public func generate() -> Generator { return Generator(buffer: buffer) }

  public func dropFirst(n: Int) -> SubSequence { return self[n..<] }

  public func dropLast(n: Int) -> SubSequence { return self[..<endIndex.advancedBy(-n)] }

  public func prefix(maxLength: Int) -> SubSequence { return self[..<min(count, maxLength)] }

  public func suffix(maxLength: Int) -> SubSequence { return self[max(startIndex, endIndex.advancedBy(-maxLength))..<] }

  public func split(maxSplit: Int,
                    allowEmptySlices: Bool,
                    @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    var result: [SubSequence] = []
    var subSequenceStart = startIndex

    var currentIndex = startIndex

    // Iterate through indices
    while currentIndex < endIndex {

      // Check whether element at `currentIndex` is a separator
      if try isSeparator(self[currentIndex]) {

        // Check for a non-empty range from previous split to current index
        if subSequenceStart < currentIndex { result.append(self[subSequenceStart ..< currentIndex]) }


        // Iterate through consecutive separator elements
        repeat { currentIndex._successorInPlace() } while try (currentIndex < endIndex && isSeparator(self[currentIndex]))

        // Append empty slice if two or more consecutive separators were consumed and `allowEmptySlices` is set to `true`
        if currentIndex > subSequenceStart.successor() && allowEmptySlices {
          result.append(OrderedSetSlice<Element>(buffer: buffer, bounds: subSequenceStart ..< subSequenceStart))
        }
        subSequenceStart = currentIndex

      } else {

        currentIndex._successorInPlace()

      }

    }

    // Check for a trailing subsequence
    if subSequenceStart < currentIndex { result.append(self[subSequenceStart ..< currentIndex]) }

    return result
  }
}

extension OrderedSet: SetType {

  public mutating func insert(member: Element) {
    ensureUniqueWithCapacity(count + 1)
    let (bucket, found) = buffer.find(member)
    guard !found else { return }
    buffer.initializeElement(member, bucket: bucket)
    buffer.count += 1
  }

  public mutating func remove(member: Element) -> Element? {
    let oldElement = UnsafeMutablePointer<Element?>.alloc(1)
    _removeElement(member, oldElement: oldElement)
    return oldElement.memory
  }
  
  public init<S : SequenceType where S.Generator.Element == Element>(_ elements: S) {
    self.init(buffer: Buffer(elements: elements)) // Uniqueness checked by `Buffer`
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set`.
  @warn_unused_result
  public func isSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var hitCount = 0
    for element in sequence where self.contains(element) {
      hitCount += 1
      guard hitCount < count else { return true }
    }
    return hitCount == count
  }
  /// Returns true if the set is a subset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  public func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var hitCount = 0, totalCount = 0
    for element in sequence {
      if contains(element) { hitCount += 1 }
      totalCount += 1
      guard hitCount < count || totalCount <= count else { return true }
    }
    return hitCount == count && totalCount > count
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set`.
  @warn_unused_result
  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    for element in sequence { guard contains(element) else { return false } }
    return true
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  public func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var totalCount = 0
    for element in sequence {
      totalCount += 1
      guard contains(element) else { return false }
    }
    return totalCount < count
  }

  /// Returns true if no members in the set are in a finite sequence as a `Set`.
  @warn_unused_result
  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    for element in sequence { guard !contains(element) else { return false } }
    return true
  }

  /// Return a new `Set` with items in both this set and a finite sequence.
  @warn_unused_result
  public func union<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  /// Insert elements of a finite sequence into this `Set`.
  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence where !contains(element) { insert(element) }
  }

  /// Return a new set with elements in this set that do not occur in a finite sequence.
  @warn_unused_result
  public func subtract<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    switch sequence {
    case let other as OrderedSet<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    }
  }

  /// Remove all members in the set that occur in a finite sequence.
  public mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    self = subtract(sequence)
  }

  /// Return a new set with elements common to this set and a finite sequence.
  @warn_unused_result
  public func intersect<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    switch sequence {
    case let other as OrderedSet<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    }
  }

  /// Remove any members of this set that aren't also in a finite sequence.
  public mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    self = intersect(sequence)
  }

  /// Return a new set with elements that are either in the set or a finite sequence but do not occur in both.
  @warn_unused_result
  public func exclusiveOr<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    switch sequence {
    case let other as OrderedSet<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity + other.count)
      for element in self where other ∌ element { result.append(element) }
      for element in other where self ∌ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity + other.count)
      for element in self where other ∌ element { result.append(element) }
      for element in other where self ∌ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet<Element>(minimumCapacity: capacity + other.count)
      for element in self where other ∌ element { result.append(element) }
      for element in other where self ∌ element { result.append(element) }
      return result
    }
  }

  /// For each element of a finite sequence, remove it from the set if it is a common element, otherwise add it
  /// to the set. Repeated elements of the sequence will be ignored.
  public mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    self = exclusiveOr(sequence)
  }
}

extension OrderedSet: MutableCollectionType {
  public subscript(bounds: Range<Int>) -> SubSequence {
    get {
      return SubSequence(buffer: buffer, bounds: bounds)
    }
    set {
      replaceRange(bounds, with: newValue)
    }
  }
}

extension OrderedSet: RangeReplaceableCollectionType {

  public init() { owner = Owner(minimumCapacity: 0) }

  public mutating func reserveCapacity(minimumCapacity: Int) { ensureUniqueWithCapacity(minimumCapacity) }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {

    let requiredCapacity = count - subRange.count + numericCast(newElements.count)
    ensureUniqueWithCapacity(requiredCapacity)

    // Replace with uniqued collection
    buffer.replaceRange(subRange, with: newElements)
  }

  public mutating func append(element: Element) { insert(element) }

  public mutating func appendContentsOf<S:SequenceType where S.Generator.Element == Element>(newElements: S) {
    for element in newElements { insert(element) } // Elementship check by `insert()`
  }

  public mutating func insert(newElement: Element, atIndex i: Int) {
    replaceRange(i ..< i, with: CollectionOfOne(newElement))
  }

  public mutating func insertContentsOf<C:CollectionType
    where C.Generator.Element == Element>(newElements: C, at i: Int)
  {
    replaceRange(i ..< i, with: newElements)
  }

  public mutating func removeFirst(n: Int) {
    replaceRange(0 ..< n, with: EmptyCollection())
  }

  public mutating func removeRange(subRange: Range<Int>) {
    replaceRange(subRange, with: EmptyCollection())
  }

  public mutating func removeAll(keepCapacity: Bool = false) {
    owner = Owner(buffer: Buffer(storage: Storage.create(keepCapacity ? capacity : 0)))
  }
  
}

extension OrderedSet: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(buffer: Buffer(elements: elements))
  }
}

extension OrderedSet: CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    guard count > 0 else { return "[:]" }

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

  public var description: String { return elementsDescription }

  public var debugDescription: String { return elementsDescription }
}

extension OrderedSet: Equatable {}

public func == <Element:Hashable>
  (lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  
  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }
  
  for (v1, v2) in zip(lhs, rhs) { guard v1 == v2 else { return false } }
  
  return true
}
