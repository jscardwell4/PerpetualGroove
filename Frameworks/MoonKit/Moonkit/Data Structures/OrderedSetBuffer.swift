//
//  OrderedSetBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct OrderedSetBuffer<Element:Hashable> {

  typealias Index = Int
  typealias Generator = OrderedSetGenerator<Element>

  typealias Buffer = OrderedSetBuffer<Element>
  typealias Storage = OrderedSetStorage<Element>

  // MARK: Pointers to the underlying memory

  let storage: Storage
  let initializedBuckets: BitMap
  let bucketMap: HashBucketMap
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
    bucketMap = storage.bucketMap
    members = storage.members
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
  func idealBucketForElement(member: Element) -> HashBucket {
    return suggestBucketForValue(member, capacity: capacity)
  }

  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
  func positionForBucket(bucket: HashBucket) -> Index? {
    return bucketMap[bucket]
  }

  /// Returns the bucket for the member assigned to `position`.
  /// - requires: A bucket has been assigned to `position`
  func bucketForPosition(position: Index) -> HashBucket {
    return bucketMap[position]
  }

  /// Returns the bucket containing `member` or `nil` if no bucket contains `member`.
  func currentBucketForElement(member: Element) -> HashBucket? {
    let (bucket, found) = find(member)
    return found ? bucket : nil
  }

  /// Returns an empty bucket suitable for holding `member` or `nil` if a bucket already contains `member`.
  func emptyBucketForElement(member: Element) -> HashBucket? {
    let (bucket, found) = find(member)
    return found ? nil : bucket
  }

  /// Returns the current bucket for `member` and `true` when `member` is located; 
  /// returns an open bucket for `member` and `false` otherwise
  /// - requires: At least one empty bucket
  func find(member: Element) -> (bucket: HashBucket, found: Bool) {

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
  func memberInBucket(bucket: HashBucket) -> Element { return members[bucket.offset] }

  /// Returns the value assigned to `position`
  func memberAtPosition(position: Index) -> Element {
    return memberInBucket(bucketForPosition(position))
  }

  /// Returns `false` when `bucket` is empty and `true` otherwise.
  func isInitializedBucket(bucket: HashBucket) -> Bool { return initializedBuckets[bucket] }

  /// Returns the position for `member` or `nil` if `member` is not found.
  func positionForElement(member: Element) -> Index? {
    guard count > 0, let bucket = currentBucketForElement(member) else { return nil }
    return positionForBucket(bucket)
  }

  // MARK: Removing data

  /// Attempts to move the values of the buckets near `hole` into buckets nearer to their 'ideal' bucket
  func _patchHole(hole: HashBucket, idealBucket: HashBucket) {

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

  func destroyBucket(bucket: HashBucket) {
    initializedBuckets[bucket] = false
    (members + bucket.offset).destroy()
  }

  func destroyElementAt(position: Index) {
    defer { _fixLifetime(self) }
    let hole = bucketForPosition(position)
    let idealBucket = idealBucketForElement(memberInBucket(hole))

    destroyBucket(hole)
    bucketMap.removeBucketAt(position)

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
    var newElementsBuckets = [HashBucket](minimumCapacity: numericCast(newElements.count))

    for value in newElements {
      let (bucket, found) = find(value)
      guard !found else { continue }
      initializeBucket(bucket, with: value)
      newElementsBuckets.append(bucket)
    }

    // Adjust positions
    bucketMap.replaceRange(subRange, with: newElementsBuckets)

    // Update count
    storage.count = bucketMap.count

  }


  // MARK: Initializing with data

  func initializeBucket(bucket: HashBucket, with member: Element) {
    (members + bucket.offset).initialize(member)
    initializedBuckets[bucket] = true
  }

  func initializeElement(member: Element, position: Int, bucket: HashBucket) {
    defer { _fixLifetime(self) }
    initializeBucket(bucket, with: member)
    bucketMap[position] = bucket
  }

  func initializeElement(member: Element, position: Int) {
    let (bucket, _) = find(member)
    initializeElement(member, position: position, bucket: bucket)
  }

  func initializeElement(member: Element, bucket: HashBucket) {
    initializeElement(member, position: count, bucket: bucket)
  }

  /// Removes the value from `bucket1` and uses this value to initialize `bucket2`
  func moveElementInBucket(bucket1: HashBucket, toBucket bucket2: HashBucket) {
    initializeBucket(bucket2, with: (members + bucket1.offset).move())
    initializedBuckets[bucket1] = false
    bucketMap.replaceBucket(bucket1, with: bucket2)
  }


}

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension OrderedSetBuffer : CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    if count == 0 { return "[:]" }

    var result = "["
    var first = true
    for bucket in bucketMap {
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
      result += "position \(position) ➞ bucket \(bucketMap[position])\n"
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
