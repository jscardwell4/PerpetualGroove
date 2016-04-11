//
//  OrderedSet3.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/14/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

// MARK: - Storage
// MARK: -

private let maxLoadFactorInverse = 1/0.75

struct OrderedSet3StorageHeader: CustomStringConvertible {
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

  let emptyPositionStorage: UnsafeMutablePointer<UInt>
  let emptyPositions: BitMap
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
    emptyPositionStorage = UnsafeMutablePointer<UInt>.alloc(BitMap.wordsFor(capacity))
    emptyPositions = BitMap(initializedStorage: emptyPositionStorage, bitCount: capacity)
    _endIndex.initialize(0)
    initializeToNegativeOne()
  }

  /// Initializes `positions` and `buckets` with `-1` and all bits in `emptyPositions` with `1`
  func initializeToNegativeOne() {
    positions.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
    buckets.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
    emptyPositions.initializeToOne()
  }

  /// Accessor for the index of a specified index.
  subscript(bucket: Bucket) -> Index? {
    guard buckets[bucket.offset] > -1 else { return nil }
    return indexForOffset(buckets[bucket.offset])
  }

  /// Accessors for getting and setting the bucket at a specified index.
  subscript(index: Index) -> Bucket {
    get {
      let positionOffset = offsetForIndex(index)
      guard !emptyPositions[positionOffset] else { fatalError("Invalid index: \(index)") }
      let bucketOffset = positions[positionOffset]
      return Bucket(offset: bucketOffset, capacity: capacity)
    }
    nonmutating set {
      if index == endIndex { appendBucket(newValue) }
      else { updateBucket(newValue, at: index) }
    }
  }

  /// Removes 'empty' positions in `positions`, optionally inserting new elements.
  /// - postcondition: `∀ i ∈ [startIndex, endIndex), i == offsetForIndex(i)`
  func patchHoles<
    C:CollectionType where C.Generator.Element == Bucket
    >(inserting: C? = nil, at: Index = 0)
  {
    var bucketOffsets = positions.filter { $0 > -1 }
    if let newElementsOffsets = inserting?.map({$0.offset}) {
      bucketOffsets.insertContentsOf(newElementsOffsets, at: at)
    }
    for (index, offset) in bucketOffsets.enumerate() {
      positions[index] = offset
      emptyPositions[index] = false
      buckets[offset] = index // index is used here because the whole idea is to have position offset = index
    }
    for index in bucketOffsets.endIndex ..< capacity {
      positions[index] = -1
      emptyPositions[index] = true
    }
    endIndex = bucketOffsets.endIndex
  }

  /// Converts `index` to an actual buffer offset
  func offsetForIndex(index: Index, forInserting: Bool = false) -> PositionOffset {
    switch emptyPositions.firstSetBit {
    case let e? where e > index || (e == index && e == endIndex): fallthrough
    case nil:
      assert(!emptyPositions[index] || index == endIndex, "Expected non-empty position at index: \(index)")
      return index
    case let e?:
      var skipCount = 1
      var nextEmpty = emptyPositions.nextSetBit(e)
      func shouldContinue() -> Bool {
        guard let nextEmpty = nextEmpty else { return false }
        if forInserting { return nextEmpty < index + skipCount }
        else { return nextEmpty <= index + skipCount }
      }
      while shouldContinue() {
        skipCount += 1
        nextEmpty = emptyPositions.nextSetBit(nextEmpty!)
      }
      return index + skipCount
    }
  }

  /// Returns the index value given an offset into `positions`
  func indexForOffset(offset: PositionOffset) -> Index {
    switch emptyPositions.previousSetBit(offset) {
    case nil: return offset
    case let e?:
      var skipCount = 1
      var previousEmpty = emptyPositions.previousSetBit(e)
      while previousEmpty != nil{
        skipCount += 1
        previousEmpty = emptyPositions.previousSetBit(previousEmpty!)
      }
      return offset - skipCount
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
    let positionOffset = offsetForIndex(index)
    assert(emptyPositions[positionOffset] == false, "\(#function) should not be called for an empty position")

    let bucketOffset = bucket.offset
    let oldBucketOffset = positions[positionOffset]
    guard oldBucketOffset != bucketOffset else { return }

    buckets[oldBucketOffset] = -1
    positions[positionOffset] = bucketOffset
    buckets[bucketOffset] = positionOffset

  }

  /// Assigns `bucket` to `endIndex`.
  /// - requires: `endIndex < capacity`
  /// - postcondition: `count = count + 1`
  func appendBucket(bucket: Bucket) {
    let positionOffset = offsetForIndex(endIndex, forInserting: true)
    guard positionOffset < capacity else {
      patchHoles([bucket], at: endIndex)
      return
    }

    positions[positionOffset] = bucket.offset
    emptyPositions[positionOffset] = false
    buckets[bucket.offset] = positionOffset
    endIndex += 1
  }

  /// Removes the bucket assigned to `index`.
  /// - requires: `index ∋ startIndex..<endIndex`
  /// - postcondition: count = count - 1
  func removeBucketAt(index: Index) {
    let offset = offsetForIndex(index)
    assert(emptyPositions[offset] == false, "\(#function) should not be called for an empty position")
    buckets[positions[offset]] = -1
    positions[offset] = -1
    emptyPositions[offset] = true
    endIndex -= 1
  }

  subscript(bounds: Range<Index>) -> [Bucket] {
    get {
      let bounds: Range<PositionOffset> =
        offsetForIndex(bounds.startIndex) ..< offsetForIndex(bounds.endIndex)
      return positions[bounds]
        .flatMap {emptyPositions[$0] ? nil : $0}
        .map {Bucket(offset: $0, capacity: capacity) }
    }
    set { replaceRange(bounds, with: newValue) }
  }

  /// Replaces buckets assigned to positions in `subRange` with `newElements`
  func replaceRange<
    C:CollectionType where C.Generator.Element == Bucket
    >(subRange: Range<Index>, with newElements: C)
  {
    let removeCount = subRange.count
    let insertCount = numericCast(newElements.count) as Int
    let subRange: Range<PositionOffset> =
      offsetForIndex(subRange.startIndex) ..< offsetForIndex(subRange.endIndex)
    let positionCount = subRange.count

    // Replace n values where n = max(subRange.count, newElements.count)
    for (positionOffset, bucket) in zip(subRange, newElements) {
      let bucketOffset = bucket.offset
      if emptyPositions[positionOffset] {
        emptyPositions[positionOffset] = false
      } else {
        let oldBucketOffset = positions[positionOffset]
        buckets[oldBucketOffset] = -1
      }
      positions[positionOffset] = bucketOffset
      buckets[bucketOffset] = positionOffset
    }

    switch positionCount - insertCount {
    case 0:
      // Nothing more to do
      break
    case let delta where delta > 0:
      // Empty remaining positions in `subRange`
      for position in subRange.dropFirst(insertCount) {
        if emptyPositions[position] { continue }
        buckets[positions[position]] = -1
        positions[position] = -1
        emptyPositions[position] = true
      }
      endIndex = endIndex - removeCount + insertCount

    case let delta /* where delta < 0*/:
      // Shift to make room for additional insertions
      let shiftAmount = abs(delta)
      var sourceIndex = endIndex.predecessor()
      var destinationIndex = sourceIndex.advancedBy(shiftAmount)
      let stopIndex = subRange.endIndex.predecessor()

      while sourceIndex > stopIndex {
        // Copy existing entry into later memory
        guard !emptyPositions[sourceIndex] else {
          positions[destinationIndex] = 1
          emptyPositions[destinationIndex] = true
          destinationIndex._predecessorInPlace()
          sourceIndex._predecessorInPlace()
          continue
        }
        let bucket = positions[sourceIndex]
        let position = buckets[bucket]
        buckets[bucket] = position + shiftAmount
        positions[destinationIndex] = bucket
        emptyPositions[destinationIndex] = false

        destinationIndex._predecessorInPlace()
        sourceIndex._predecessorInPlace()
      }

      // Copy additional insertions between `subRange` and the shifted entries
      var newElementsIndex = newElements.startIndex.advancedBy(numericCast(removeCount))
      destinationIndex = subRange.endIndex
      while newElementsIndex.distanceTo(newElements.endIndex) > 0 {
        let bucket = newElements[newElementsIndex].offset
        buckets[bucket] = destinationIndex
        positions[destinationIndex] = bucket
        destinationIndex._successorInPlace()
        newElementsIndex._successorInPlace()
      }
      endIndex += shiftAmount
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
    var result = "positions: ["

    var first = true
    for i in 0 ..< capacity {
      if first { first = false } else { result += ", " }
      result += String(positions[i])
    }
    result += "]\nbuckets: ["
    first = true
    for i in 0 ..< capacity {
      if first { first = false } else { result += ", " }
      result += String(buckets[i])
    }
    result += "]\nemptyPositions: \(emptyPositions)"
    return result
  }
  
}

final class OrderedSet3Storage<Member:Hashable>: ManagedBuffer<OrderedSet3StorageHeader, UInt8> {

  typealias Storage = OrderedSet3Storage<Member>
  typealias Header = OrderedSet3StorageHeader

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

  static func bytesForMembers(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(UInt), alignof(Int))
    let padding = max(0, alignof(Member) - maxPrevAlignment)
    return strideof(Member) * capacity + padding
  }

  /// The number of bytes used to store the hash values for this instance
  var membersBytes: Int { return Storage.bytesForMembers(capacity) }

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
  var members: UnsafeMutablePointer<Member> {
    return UnsafeMutablePointer<Member>(bucketPositionMapAddress + bucketPositionMapBytes)
  }

  static func create(minimumCapacity: Int) -> OrderedSet3Storage {
    let capacity = round2(minimumCapacity)

    let initializedBucketsBytes = bytesForInitializedBuckets(capacity)
    let bucketPositionMapBytes = bytesForBucketPositionMap(capacity)
    let membersBytes = bytesForMembers(capacity)
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
    guard !_isPOD(Member) else { return }
    defer { _fixLifetime(self) }
    let members = self.members
    for offset in initializedBuckets.nonZeroBits { (members + offset).destroy() }
  }
}

extension OrderedSet3Storage {
  var description: String {
    defer { _fixLifetime(self) }
    var result = "OrderedSet3Storage {\n"
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

public struct OrderedSet3Generator<Member:Hashable>: GeneratorType {
  typealias Buffer = OrderedSet3Buffer<Member>
  let buffer: Buffer
  var index: Int = 0
  init(buffer: Buffer) { self.buffer = buffer }

  public mutating func next() -> (Member)? {
    guard index < buffer.count else { return nil }
    defer { index = index.successor() }
    return buffer.memberAtPosition(index)
  }
}

struct OrderedSet3Buffer<Member:Hashable> {

  typealias Index = Int
  typealias Element = Member
  typealias Generator = OrderedSet3Generator<Member>

  typealias Buffer = OrderedSet3Buffer<Member>
  typealias Storage = OrderedSet3Storage<Member>

  // MARK: Pointers to the underlying memory

  let storage: Storage
  let initializedBuckets: BitMap
  let bucketPositionMap: BucketPositionMap
  let members: UnsafeMutablePointer<Member>

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
        buffer.initializeMember(member, position: position - duplicates, bucket: bucket)
        count += 1
      }
    }
    buffer.count = count

    self = buffer
  }


  // MARK: Queries

  /// Returns the bucket for `member` diregarding collisions
  func idealBucketForMember(member: Member) -> Bucket {
    return suggestBucketForValue(member, capacity: capacity)
  }

  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
  func positionForBucket(bucket: Bucket) -> Index? {
//    return positionMap.indexOf(bucket)
    return bucketPositionMap[bucket]
  }

  /// Returns the bucket for the member assigned to `position`.
  /// - requires: A bucket has been assigned to `position`
  func bucketForPosition(position: Index) -> Bucket {
    return bucketPositionMap[position]
  }

  /// Returns the bucket containing `member` or `nil` if no bucket contains `member`.
  func currentBucketForMember(member: Member) -> Bucket? {
    let (bucket, found) = find(member)
    return found ? bucket : nil
  }

  /// Returns an empty bucket suitable for holding `member` or `nil` if a bucket already contains `member`.
  func emptyBucketForMember(member: Member) -> Bucket? {
    let (bucket, found) = find(member)
    return found ? nil : bucket
  }

  /// Returns the current bucket for `member` and `true` when `member` is located; 
  /// returns an open bucket for `member` and `false` otherwise
  /// - requires: At least one empty bucket
  func find(member: Member) -> (bucket: Bucket, found: Bool) {

    let startBucket = idealBucketForMember(member)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard memberInBucket(bucket) != member  else { return (bucket, true) }
      bucket._successorInPlace()
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  /// Returns the value inserted into `bucket`
  func memberInBucket(bucket: Bucket) -> Member { return members[bucket.offset] }

  /// Returns the value assigned to `position`
  func memberAtPosition(position: Index) -> Member {
    return memberInBucket(bucketForPosition(position))
  }

  /// Returns `false` when `bucket` is empty and `true` otherwise.
  func isInitializedBucket(bucket: Bucket) -> Bool { return initializedBuckets[bucket] }

  /// Returns the position for `member` or `nil` if `member` is not found.
  func positionForMember(member: Member) -> Index? {
    guard count > 0, let bucket = currentBucketForMember(member) else { return nil }
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
        let bucket = idealBucketForMember(value)

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
      moveMemberInBucket(last, toBucket: hole)
      hole = last
    }

  }

  func destroyBucket(bucket: Bucket) {
    initializedBuckets[bucket] = false
    (members + bucket.offset).destroy()
  }

  func destroyMemberAt(position: Index) {
    defer { _fixLifetime(self) }
    let hole = bucketForPosition(position)
    let idealBucket = idealBucketForMember(memberInBucket(hole))

    destroyBucket(hole)
    bucketPositionMap.removeBucketAt(position)

    count -= 1

    _patchHole(hole, idealBucket: idealBucket)

  }

  /// - requires: A member has been assigned to `position`
  func replaceMemberAtPosition(position: Index, with member: Member) {
    let bucket = bucketForPosition(position)
    guard memberInBucket(bucket) != member else { return }
    guard let emptyBucket = emptyBucketForMember(member) else {
      fatalError("failed to locate an empty bucket for '\(member)'")
    }
    destroyBucket(bucket)
    initializeMember(member, position: position, bucket: emptyBucket)
  }

  /// - requires: `newElements` contains unique values
  func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    defer { _fixLifetime(self) }

    // Remove values from buckets in `subRange`

    subRange.forEach { destroyBucket(bucketForPosition($0)) }


    // Insert new elements, accumulating a list of their buckets
    var newElementsBuckets = [Bucket](minimumCapacity: numericCast(newElements.count))

    for value in newElements {
      let (bucket, _) = find(value)
      initializeBucket(bucket, with: value)
      newElementsBuckets.append(bucket)
    }

    // Adjust positions
    bucketPositionMap.replaceRange(subRange, with: newElementsBuckets)

    // Update count
    storage.count = bucketPositionMap.count

  }


  // MARK: Initializing with data

  func initializeBucket(bucket: Bucket, with member: Member) {
    (members + bucket.offset).initialize(member)
    initializedBuckets[bucket] = true
  }

  func initializeMember(member: Member, position: Int, bucket: Bucket) {
    defer { _fixLifetime(self) }
    initializeBucket(bucket, with: member)
    bucketPositionMap[position] = bucket
  }

  func initializeMember(member: Member, position: Int) {
    let (bucket, _) = find(member)
    initializeMember(member, position: position, bucket: bucket)
  }

  func initializeMember(member: Member, bucket: Bucket) {
    initializeMember(member, position: count, bucket: bucket)
  }

  /// Removes the value from `bucket1` and uses this value to initialize `bucket2`
  func moveMemberInBucket(bucket1: Bucket, toBucket bucket2: Bucket) {
    initializeBucket(bucket2, with: (members + bucket1.offset).move())
    initializedBuckets[bucket1] = false
    bucketPositionMap.replaceBucket(bucket1, with: bucket2)
  }


}

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension OrderedSet3Buffer : CustomStringConvertible, CustomDebugStringConvertible {

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
        result += "bucket \(bucket), ideal bucket = \(idealBucketForMember(member))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }
}

// MARK: - Owner
// MARK: -

final class OrderedSet3StorageOwner<Member:Hashable>: NonObjectiveCBase {

  typealias Buffer = OrderedSet3Buffer<Member>
  var buffer: Buffer
  init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }
  init(buffer: Buffer) { self.buffer = buffer }
}

// MARK: - SubSequence
// MARK: -

public struct OrderedSet3Slice<Member:Hashable>: CollectionType {
  public typealias Index = Int
  typealias Buffer = OrderedSet3Buffer<Member>
  public var startIndex: Int { return bounds.startIndex }
  public var endIndex: Int  { return bounds.endIndex }
  let buffer: Buffer
  let bounds: Range<Int>
  public subscript(position: Index) -> Member { return buffer.memberAtPosition(position) }
  init(buffer: Buffer, bounds: Range<Int>) {
    precondition(bounds.startIndex >= 0, "Invalid start for bounds: \(bounds.startIndex)")
    precondition(bounds.endIndex <= buffer.count, "Invalid end for bounds: \(bounds.endIndex)")
    self.buffer = buffer
    self.bounds = bounds
  }
}

extension OrderedSet3Slice: CustomStringConvertible {
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


// MARK: - OrderedSet3
// MARK: -

/// A hash-based mapping from `Key` to `Member` instances that preserves elment order.
public struct OrderedSet3<Member:Hashable>: CollectionType {

  public typealias Index = Int
  public typealias Generator = OrderedSet3Generator<Member>
  public typealias SubSequence = OrderedSet3Slice<Member>
  public typealias Element = (Member)
  public typealias _Element = Element
  typealias Storage = OrderedSet3Storage<Member>
  typealias Buffer = OrderedSet3Buffer<Member>
  typealias Owner = OrderedSet3StorageOwner<Member>

  var buffer: Buffer {
    get { return owner.buffer }
    set { owner.buffer = newValue }
  }

  var owner: Owner


  func cloneBuffer(newCapacity: Int) -> Buffer {

    let clone = Buffer(minimumCapacity: newCapacity)

    if clone.capacity == buffer.capacity {
      for (position, bucket) in buffer.bucketPositionMap.enumerate() {
        clone.initializeMember(buffer.memberInBucket(bucket), position: position, bucket: bucket)
      }
    } else {
      for (position, bucket) in buffer.bucketPositionMap.enumerate() {
        clone.initializeMember(buffer.memberInBucket(bucket), position: position)
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

  public var startIndex: Index { return 0 }

  public var endIndex: Index { return count }

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
  

  public func indexOf(member: Member) -> Index? { return buffer.positionForMember(member) }

  public subscript(position: Int) -> Member {
    get { return buffer.memberAtPosition(position) }
    set { buffer.replaceMemberAtPosition(position, with: newValue) }
  }

  @warn_unused_result
  public func contains(member: Member) -> Bool { let (_, found) = buffer.find(member); return found }

  mutating func _removeAtIndex(index: Index, oldElement: UnsafeMutablePointer<Element>) {
    if oldElement != nil { oldElement.initialize(buffer.memberInBucket(buffer.bucketForPosition(index))) }
    ensureUniqueWithCapacity(capacity)
    buffer.destroyMemberAt(index)
  }

  public mutating func removeAtIndex(index: Index) -> Member {
    let oldElement = UnsafeMutablePointer<Element>.alloc(1)
    _removeAtIndex(index, oldElement: oldElement)
    return oldElement.memory
  }

  mutating func _removeMember(member: Member, oldMember: UnsafeMutablePointer<Member?>) {
    guard let index = buffer.positionForMember(member) else {
      if oldMember != nil { oldMember.initialize(nil) }
      return
    }
    if oldMember != nil {
      let oldElement = UnsafeMutablePointer<Element>.alloc(1)
      _removeAtIndex(index, oldElement: oldElement)
      oldMember.initialize(oldElement.memory)
    } else {
      _removeAtIndex(index, oldElement: nil)
    }
  }

  public mutating func remove(member: Member) -> Member? {
    let oldMember = UnsafeMutablePointer<Member?>.alloc(1)
    _removeMember(member, oldMember: oldMember)
    return oldMember.memory
  }

  public mutating func removeFirst() -> Member { return removeAtIndex(0) }

  public mutating func insert(member: Member) {
    ensureUniqueWithCapacity(count + 1)
    let (bucket, found) = buffer.find(member)
    guard !found else { return }
    buffer.initializeMember(member, bucket: bucket)
    buffer.count += 1
  }

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public func generate() -> Generator { return Generator(buffer: buffer) }

  public var isEmpty: Bool { return count == 0 }

  public var first: Element? { guard count > 0 else { return nil }; return buffer.memberAtPosition(0) }

  public mutating func popFirst() -> Element? { guard count > 0 else { return nil }; return removeAtIndex(0) }

}

extension OrderedSet3: SetType {

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
  public func union<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet3<Element> {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  /// Insert elements of a finite sequence into this `Set`.
  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence { insert(element) }
  }

  /// Return a new set with elements in this set that do not occur in a finite sequence.
  @warn_unused_result
  public func subtract<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet3<Element> {
    switch sequence {
    case let other as OrderedSet3<Member>:
      var result = OrderedSet3<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    case let other as Set<Member>:
      var result = OrderedSet3<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet3<Element>(minimumCapacity: capacity)
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
  public func intersect<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet3<Element> {
    switch sequence {
    case let other as OrderedSet3<Member>:
      var result = OrderedSet3<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    case let other as Set<Member>:
      var result = OrderedSet3<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet3<Element>(minimumCapacity: capacity)
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
  public func exclusiveOr<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet3<Element> {
    switch sequence {
    case let other as OrderedSet3<Member>:
      var result = OrderedSet3<Member>(minimumCapacity: capacity + other.count)
      for element in self where other ∌ element { result.append(element) }
      for element in other where self ∌ element { result.append(element) }
      return result
    case let other as Set<Member>:
      var result = OrderedSet3<Member>(minimumCapacity: capacity + other.count)
      for element in self where other ∌ element { result.append(element) }
      for element in other where self ∌ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet3<Member>(minimumCapacity: capacity + other.count)
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

extension OrderedSet3: MutableCollectionType {
  public subscript(bounds: Range<Int>) -> SubSequence {
    get { return SubSequence(buffer: buffer, bounds: bounds) }
    set { for position in newValue.bounds { self[position] = newValue[position] } }
  }
}

extension OrderedSet3: RangeReplaceableCollectionType {

  public init() { owner = Owner(minimumCapacity: 0) }

  public mutating func reserveCapacity(minimumCapacity: Int) { ensureUniqueWithCapacity(minimumCapacity) }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {

    let requiredCapacity = count - subRange.count + numericCast(newElements.count)
    ensureUniqueWithCapacity(requiredCapacity)

    // Ensure uniqueness
    let elementsToRemove = self[subRange]
    let filteredElements = newElements.filter { !contains($0) || elementsToRemove.contains($0) }

    // Replace with uniqued collection
    buffer.replaceRange(subRange, with: filteredElements)
  }

  public mutating func append(element: Element) { insert(element) }

  public mutating func appendContentsOf<S:SequenceType where S.Generator.Element == Element>(newElements: S) {
    for element in newElements { insert(element) } // Membership check by `insert()`
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

  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    owner = Owner(buffer: Buffer(storage: Storage.create(keepCapacity ? capacity : 0)))
  }
  
}

extension OrderedSet3: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(buffer: Buffer(elements: elements))
  }
}

extension OrderedSet3: CustomStringConvertible, CustomDebugStringConvertible {

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

public func == <Member:Hashable>
  (lhs: OrderedSet3<Member>, rhs: OrderedSet3<Member>) -> Bool
{
  
  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }
  
  for (v1, v2) in zip(lhs, rhs) { guard v1 == v2 else { return false } }
  
  return true
}
