//
//  HashBucketMap.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct HashBucketMap: CollectionType {

  typealias Index = Int
  typealias _Element = HashBucket

  /// Returns the number of bytes required for a map of `capacity` elements.
  /// This includes storage for `capacity` `Int` values for the buckets,
  /// `capacity` `Int` values for the positions, and an `Int` value for `_endIndex`
  static func wordsFor(capacity: Int) -> Int { return strideof(Int) * (capacity * 2 + 1) }

  /// The total number of 'bucket ⟷ position' mappings that can be managed.
  let capacity: Int

  /// Pointer to the memory allocated for tracking the position of each bucket.
  let buckets: UnsafeMutableBufferPointer<Int>

  /// Pointer to the memory allocated for tracking the bucket of each position
  let positions: UnsafeMutableBufferPointer<Int>

  /// Pointer to the memory allocated for tracking the `endIndex` value.
  let _endIndex: UnsafeMutablePointer<Index>

  /// Indexing always starts with `0`.
  let startIndex: Index = 0

  /// 'past the end' position for the 'position ➞ bucket' mappings.
  var endIndex: Index {
    get { return _endIndex.memory }
    nonmutating set { _endIndex.memory = newValue }
  }

  /// The number of 'position ➞ bucket' mappings.
  var count: Int { return endIndex - startIndex }

  /// Initialize with a pointer to the storage to use and its represented capacity as an element count.
  /// - warning: `storage` must have been properly allocated. Existing values in memory will be overwritten.
  init(storage: UnsafeMutablePointer<Int>, capacity: Int) {
    self.capacity = capacity
    _endIndex = storage
    positions = UnsafeMutableBufferPointer<Int>(start: storage + 1, count: capacity)
    buckets = UnsafeMutableBufferPointer<Int>(start: storage + capacity + 1, count: capacity)
    removeAll()
  }

  /// Initializes `positions` and `buckets` with `-1` and `endIndex` to `0`
  func removeAll() {
    _endIndex.initialize(0)
    positions.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
    buckets.baseAddress.initializeFrom(Repeat(count: capacity, repeatedValue: -1))
  }

  /// Accessors for the position mapped to `bucket`. The setter will remove any existing mapping with the current
  /// position for `bucket` when `newValue == nil` and replace any existing mapping with `newValue` otherwise.
  subscript(bucket: HashBucket) -> Index? {
    get {
      assert((0 ..< capacity).contains(bucket.offset), "invalid bucket '\(bucket)'")
      let index = buckets[bucket.offset]
      return index > -1 ? index : nil
    }
    nonmutating set {
      if let position = newValue {
        replaceBucketAt(position, with: bucket)
      } else if let oldPosition = self[bucket] {
        removeBucketAt(oldPosition)
      }
    }
  }

  /// Accessors for getting and setting the bucket at a specified index. The setter will append `newValue`
  /// when `index == endIndex` and replace the currently mapped bucket otherwise.
  subscript(index: Index) -> HashBucket {
    get {
      assert((0 ..< capacity).contains(index), "index invalid '\(index)'")
      return HashBucket(offset: positions[index], capacity: capacity)
    }
    nonmutating set {
      assert((0 ..< capacity).contains(index), "index invalid '\(index)'")
      if index == endIndex { appendBucket(newValue) }
      else { replaceBucketAt(index, with: newValue) }
    }
  }

  /// Removes `bucket1` by inserting `bucket2` and giving it `bucket1`'s position
  /// - requires: `bucket1` has been assigned a position
  func replaceBucket(bucket1: HashBucket, with bucket2: HashBucket) {
    assert((0 ..< capacity).contains(bucket1.offset), "bucket1 invalid '\(bucket1)'")
    assert((0 ..< capacity).contains(bucket2.offset), "bucket2 invalid '\(bucket2)'")

    let position = buckets[bucket1.offset]

    positions[position] = bucket2.offset
    buckets[bucket1.offset] = -1
    buckets[bucket2.offset] = position
  }

  /// Assigns `bucket` to `index`, removing the previously assigned bucket.
  /// - requires: `index ∋ startIndex..<endIndex`
  func replaceBucketAt(index: Index, with bucket: HashBucket) {
    assert((0 ..< capacity).contains(index), "index invalid '\(index)'")
    let currentBucketOffset = positions[index]
    positions[index] = bucket.offset
    buckets[bucket.offset] = index
    if currentBucketOffset > 0 { buckets[currentBucketOffset] = -1 }
  }

  /// Maps `bucket` to `index` without updating the 'position ➞ bucket' mapping for `index`
  func assign(index: Index, to bucket: HashBucket) {
    assert((0 ..< capacity).contains(index), "index invalid '\(index)'")
    assert((0 ..< capacity).contains(bucket.offset), "bucket invalid '\(bucket)'")
    buckets[bucket.offset] = index
  }

  /// Assigns `bucket` to `endIndex`.
  /// - requires: `endIndex < capacity`
  /// - postcondition: `count = count + 1`
  func appendBucket(bucket: HashBucket) {
    assert((0 ..< capacity).contains(bucket.offset), "bucket invalid '\(bucket)'")
    positions[endIndex] = bucket.offset
    buckets[bucket.offset] = endIndex
    endIndex = endIndex &+ 1
  }

  /// Removes the bucket assigned to `index`.
  /// - requires: `index ∋ startIndex..<endIndex`
  /// - postcondition: count = count - 1
  func removeBucketAt(index: Index) {
    assert((0 ..< capacity).contains(index), "index invalid '\(index)'")
    let bucketOffset = positions[index]
    buckets[bucketOffset] = -1
    endIndex = endIndex &- 1
    guard index != endIndex else { return }
    for moveIndex in index.successor() ..< endIndex.successor() {
      let previousIndex = moveIndex.predecessor()
      buckets[positions[moveIndex]] = previousIndex
      swap(&positions[moveIndex], &positions[previousIndex])
    }
  }

  subscript(bounds: Range<Index>) -> [HashBucket] {
    get {
      assert((0 ..< capacity).contains(bounds), "bounds invalid '\(bounds)'")
      return positions[bounds].map {HashBucket(offset: $0, capacity: capacity) }
    }
    set {
      assert((0 ..< capacity).contains(bounds), "bounds invalid '\(bounds)'")
      replaceRange(bounds, with: newValue)
    }
  }

  func insertContentsOf<
    C:CollectionType where C.Generator.Element == HashBucket
    >(newElements: C, at index: Int)
  {
    assert((0 ..< capacity).contains(index), "index invalid '\(index)'")

    let shiftAmount = numericCast(newElements.count) as Int
    shiftPositionsFrom(index, by: shiftAmount) // Adjusts `endIndex`

    (positions.baseAddress + index).initializeFrom(newElements.map { $0.offset })
    for position in index ..< endIndex { buckets[positions[position]] = position }

  }

  func shiftPositionsFrom(from: Int, by amount: Int) {
    assert((0 ..< capacity).contains(from), "from invalid '\(from)'")
    assert((0 ..< capacity).contains(from + amount), "amount invalid '\(amount)'")
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
    endIndex = endIndex &+ amount
    for position in (from &+ amount) ..< endIndex {
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
    assert((0 ..< capacity).contains(subRange), "subRange invalid '\(subRange)'")

    let removeCount = subRange.count
    let insertCount = numericCast(newElements.count) as Int

    // Replace n values where n = max(subRange.count, newElements.count)
    for (index, bucket) in zip(subRange, newElements) {
      replaceBucketAt(index, with: bucket)
//      let oldBucketOffset = positions[index]
//      if oldBucketOffset > -1 && buckets[oldBucketOffset] == index {
//        buckets[oldBucketOffset] = -1
//      }
//      let newBucketOffset = bucket.offset
//      positions[index] = newBucketOffset
//      buckets[newBucketOffset] = index
    }

    switch insertCount - removeCount {
      case 0:
        // Nothing more to do
        break

      case let delta where delta < 0:
        // Empty remaining positions in `subRange`

        for index in subRange.endIndex.advancedBy(delta) ..< subRange.endIndex {
          let oldBucketOffset = positions[index]
          guard oldBucketOffset > -1 else { continue }
          positions[index] = -1
          let oldPosition = buckets[oldBucketOffset]
          guard oldPosition == index else { continue }
          buckets[oldBucketOffset] = -1
        }

        shiftPositionsFrom(subRange.endIndex, by: delta)

      default: /* case let delta where delta > 0 */
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

