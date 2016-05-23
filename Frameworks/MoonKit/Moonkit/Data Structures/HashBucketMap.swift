//
//  HashBucketMap.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct HashBucketMap: CollectionType {

  typealias BucketOffset = Int
  typealias PositionOffset = Int
  typealias Index = Int
  typealias _Element = HashBucket

  /// Returns the number of bytes required for a map of `capacity` elements.
  /// This includes storage for `capacity` `Int` values for the buckets,
  /// `capacity` `Int` values for the positions, and an `Int` value for `_endIndex`
  static func wordsFor(capacity: Int) -> Int { return strideof(Int) * (capacity * 2 + 1) }

  let capacity: Int
  let storage: UnsafeMutablePointer<Int>
  let buckets: UnsafeMutableBufferPointer<PositionOffset>
  let positions: UnsafeMutableBufferPointer<BucketOffset>

  let _endIndex: UnsafeMutablePointer<Index>

  let startIndex: Index = 0

  var endIndex: Index {
    get { return _endIndex.memory }
    nonmutating set { _endIndex.memory = newValue }
  }

  var count: Int { return endIndex - startIndex }

  private var ownsStorage: Bool = false

  init(capacity: Int) {
    let storage = UnsafeMutablePointer<Int>.alloc(HashBucketMap.wordsFor(capacity))
    self.init(storage: storage, capacity: capacity)
    ownsStorage = true
  }

  /// Initialize with a pointer to the storage to use and its represented capacity as an element count.
  init(storage: UnsafeMutablePointer<Int>, capacity: Int) {
    self.capacity = capacity
    self.storage = storage
    _endIndex = storage
    positions = UnsafeMutableBufferPointer<BucketOffset>(start: storage + 1, count: capacity)
    buckets = UnsafeMutableBufferPointer<PositionOffset>(start: storage + capacity + 1, count: capacity)
    initializeToNegativeOne()
  }

  /// Initializes `positions` and `buckets` with `-1` and all bits in `emptyPositions` with `1`
  func initializeToNegativeOne() {
    positions.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
    buckets.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
    _endIndex.initialize(0)
  }

  /// Accessor for the index of a specified index.
  subscript(bucket: HashBucket) -> Index? {
    let index = buckets[bucket.offset]
    return index > -1 ? index : nil
  }

  /// Accessors for getting and setting the bucket at a specified index.
  subscript(index: Index) -> HashBucket {
    get {
      return HashBucket(offset: positions[index], capacity: capacity)
    }
    nonmutating set {
      if index == endIndex { appendBucket(newValue) }
      else { updateBucket(newValue, at: index) }
    }
  }

  /// Removes `bucket1` by inserting `bucket2` and giving it `bucket1`'s position
  /// - requires: `bucket1` has been assigned a position
  func replaceBucket(bucket1: HashBucket, with bucket2: HashBucket) {
    let oldBucketOffset = bucket1.offset
    let bucketOffset = bucket2.offset
    let positionOffset = buckets[oldBucketOffset]
    positions[positionOffset] = bucketOffset
    buckets[oldBucketOffset] = -1
    buckets[bucketOffset] = positionOffset
  }


  /// Assigns `bucket` to `index`, removing the previously assigned bucket.
  /// - requires: `index ∋ startIndex..<endIndex`
  func updateBucket(bucket: HashBucket, at index: Index) {

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
  func appendBucket(bucket: HashBucket) {
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

  subscript(subRange: Range<Index>) -> HashBucketMap {
    get {
      let mapSlice = HashBucketMap(capacity: capacity)
      (mapSlice.positions.baseAddress).initializeFrom(positions[subRange])
      for bucketIndex in positions[subRange].flatMap({$0}) where bucketIndex > -1 {
        (mapSlice.buckets.baseAddress + bucketIndex - subRange.startIndex).initialize(buckets[bucketIndex])
      }
      mapSlice.endIndex = endIndex - subRange.startIndex
      return mapSlice
    }
    set { replaceRange(subRange, with: newValue) }
  }

  func insertContentsOf<
    C:CollectionType where C.Generator.Element == HashBucket
    >(newElements: C, at index: Int)
  {
    let shiftAmount = numericCast(newElements.count) as Int
    shiftPositionsFrom(index, by: shiftAmount)

    (positions.baseAddress + index).initializeFrom(newElements.map { $0.offset })
    for position in index ..< endIndex { buckets[positions[position]] = position }
  }

  func shiftPositionsFrom(from: Int, by amount: Int) {
    let count = endIndex - from
    guard count > 0 else { return }
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
    C.Generator.Element == HashBucket,
    C.SubSequence.Generator.Element == HashBucket,
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

    default: /*case let delta where delta > 0*/
      // Insert remaining values

      insertContentsOf(newElements.dropFirst(removeCount), at: subRange.endIndex)

    }
  }

}

extension HashBucketMap: CustomStringConvertible, CustomDebugStringConvertible {
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
    var result = "startIndex: \(startIndex); endIndex: \(endIndex); capacity: \(capacity)\n"
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


//struct HashBucketMap: CollectionType {
//
//  typealias BucketOffset = Int
//  typealias PositionOffset = Int
//  typealias Index = Int
//  typealias _Element = HashBucket
//
//  /// Returns the number of bytes required for a map of `capacity` elements.
//  /// This includes storage for `capacity` `Int` values for the buckets, 
//  /// `capacity` `Int` values for the positions, and an `Int` value for `_endIndex`
//  static func bytesFor(capacity: Int) -> Int { return strideof(Int) * (capacity * 2 + 1) }
//
//  let capacity: Int
//  let buckets: UnsafeMutableBufferPointer<PositionOffset>
//  let positions: UnsafeMutableBufferPointer<BucketOffset>
//
//  let _endIndex: UnsafeMutablePointer<Index>
//
//  let startIndex: Index = 0
//
//  var endIndex: Index {
//    get { return _endIndex.memory }
//    nonmutating set { _endIndex.memory = newValue }
//  }
//
//  var count: Int { return endIndex - startIndex }
//
//  /// Initialize with a pointer to the storage to use and its represented capacity as an element count.
//  init(storage: UnsafeMutablePointer<Int>, capacity: Int) {
//    self.capacity = capacity
//    _endIndex = storage
//    _endIndex.initialize(0)
//    positions = UnsafeMutableBufferPointer<BucketOffset>(start: storage + 1, count: capacity)
//    buckets = UnsafeMutableBufferPointer<PositionOffset>(start: storage + capacity + 1, count: capacity)
//    initializeToNegativeOne()
//  }
//
//  /// Initializes `positions` and `buckets` with `-1` and all bits in `emptyPositions` with `1`
//  func initializeToNegativeOne() {
//    positions.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
//    buckets.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
//  }
//
//  /// Accessor for the index of a specified index.
//  subscript(bucket: HashBucket) -> Index? {
//    let index = buckets[bucket.offset]
//    return index > -1 ? index : nil
//  }
//
//  /// Accessors for getting and setting the bucket at a specified index.
//  subscript(index: Index) -> HashBucket {
//    get {
//      return HashBucket(offset: positions[index], capacity: capacity)
//    }
//    nonmutating set {
//      if index == endIndex { appendBucket(newValue) }
//      else { updateBucket(newValue, at: index) }
//    }
//  }
//
//  /// Removes `bucket1` by inserting `bucket2` and giving it `bucket1`'s position
//  /// - requires: `bucket1` has been assigned a position
//  func replaceBucket(bucket1: HashBucket, with bucket2: HashBucket) {
//    let oldBucketOffset = bucket1.offset
//    let bucketOffset = bucket2.offset
//    let positionOffset = buckets[oldBucketOffset]
//    positions[positionOffset] = bucketOffset
//    buckets[oldBucketOffset] = -1
//    buckets[bucketOffset] = positionOffset
//  }
//
//
//  /// Assigns `bucket` to `index`, removing the previously assigned bucket.
//  /// - requires: `index ∋ startIndex..<endIndex`
//  func updateBucket(bucket: HashBucket, at index: Index) {
//
//    let bucketOffset = bucket.offset
//    let oldBucketOffset = positions[index]
//    guard oldBucketOffset != bucketOffset else { return }
//
//    buckets[oldBucketOffset] = -1
//    positions[index] = bucketOffset
//    buckets[bucketOffset] = index
//
//  }
//
//  /// Assigns `bucket` to `endIndex`.
//  /// - requires: `endIndex < capacity`
//  /// - postcondition: `count = count + 1`
//  func appendBucket(bucket: HashBucket) {
//    positions[endIndex] = bucket.offset
//    buckets[bucket.offset] = endIndex
//    endIndex += 1
//  }
//
//  /// Removes the bucket assigned to `index`.
//  /// - requires: `index ∋ startIndex..<endIndex`
//  /// - postcondition: count = count - 1
//  func removeBucketAt(index: Index) {
//    let bucketOffset = positions[index]
//    buckets[bucketOffset] = -1
//    for moveIndex in index.successor() ..< endIndex {
//      let previousIndex = moveIndex.predecessor()
//      buckets[positions[moveIndex]] = previousIndex
//      swap(&positions[moveIndex], &positions[previousIndex])
//    }
//    endIndex -= 1
//  }
//
//  subscript(bounds: Range<Index>) -> [HashBucket] {
//    get { return positions[bounds].map {HashBucket(offset: $0, capacity: capacity) } }
//    set { replaceRange(bounds, with: newValue) }
//  }
//
//  func insertContentsOf<
//    C:CollectionType where C.Generator.Element == HashBucket
//    >(newElements: C, at index: Int)
//  {
//    let shiftAmount = numericCast(newElements.count) as Int
//    shiftPositionsFrom(index, by: shiftAmount)
//
//    (positions.baseAddress + index).initializeFrom(newElements.map { $0.offset })
//    for position in index ..< endIndex { buckets[positions[position]] = position }
//  }
//
//  func shiftPositionsFrom(from: Int, by amount: Int) {
//    let count = endIndex - from
//    let source = positions.baseAddress + from
//    let destination = source + amount
//    if amount < 0 {
//      destination.moveInitializeFrom(source, count: count)
//      (destination + count).initializeFrom(Repeat(count: abs(amount), repeatedValue: -1))
//    } else {
//      destination.moveInitializeBackwardFrom(source, count: count)
//      source.initializeFrom(Repeat(count: amount, repeatedValue: -1))
//    }
//    endIndex += amount
//    for position in (from + amount) ..< endIndex {
//      buckets[positions[position]] = position
//    }
//  }
//
//  /// Replaces buckets assigned to positions in `subRange` with `newElements`
//  /// - requires: `newElements` contains unique values.
//  func replaceRange<
//    C:CollectionType
//    where
//    C.Generator.Element == HashBucket,
//    C.SubSequence.Generator.Element == HashBucket,
//    C.SubSequence:CollectionType
//    >(subRange: Range<Index>, with newElements: C)
//  {
//    let removeCount = subRange.count
//    let insertCount = numericCast(newElements.count) as Int
//
//    // Replace n values where n = max(subRange.count, newElements.count)
//    for (index, bucket) in zip(subRange, newElements) {
//      let oldBucketOffset = positions[index]
//      if oldBucketOffset > -1 && buckets[oldBucketOffset] == index {
//        buckets[oldBucketOffset] = -1
//      }
//      let newBucketOffset = bucket.offset
//      positions[index] = newBucketOffset
//      buckets[newBucketOffset] = index
//    }
//
//    switch insertCount - removeCount {
//    case 0:
//      // Nothing more to do
//      break
//
//    case let delta where delta < 0:
//      // Empty remaining positions in `subRange`
//
//      for index in subRange.endIndex.advancedBy(delta) ..< subRange.endIndex {
//        let oldBucketOffset = positions[index]
//        positions[index] = -1
//        let oldPosition = buckets[oldBucketOffset]
//        guard oldPosition == index else { continue }
//        buckets[oldBucketOffset] = -1
//      }
//
//      shiftPositionsFrom(subRange.endIndex, by: delta)
//
//    default: /*case let delta where delta < 0*/
//      // Insert remaining values
//
//      insertContentsOf(newElements.dropFirst(removeCount), at: subRange.endIndex)
//
//    }
//  }
//  
//}
//
//extension HashBucketMap: CustomStringConvertible, CustomDebugStringConvertible {
//  var description: String {
//    var result = "["
//
//    var first = true
//    for i in startIndex ..< endIndex {
//      if first { first = false } else { result += ", " }
//      result += String(positions[i])
//    }
//    result += "]"
//
//    return result
//  }
//
//  var debugDescription: String {
//    var result = "startIndex: \(startIndex); endIndex: \(endIndex); capacity: \(capacity)\n"
//    result += "positions: [\n"
//
//    var first = true
//    for position in 0 ..< capacity {
//      let bucketOffset = positions[position]
//      guard bucketOffset > -1 else { continue }
//      if first { first = false } else { result += ",\n" }
//      result += "\t\(position): \(bucketOffset)"
//    }
//    result += "]\nbuckets: [\n"
//    first = true
//    for bucket in 0 ..< capacity {
//      let position = buckets[bucket]
//      guard position > -1 else { continue }
//      if first { first = false } else { result += ",\n" }
//      result += "\t\(bucket): \(position)"
//    }
//    result += "]"
//    return result
//  }
//  
//}
//
