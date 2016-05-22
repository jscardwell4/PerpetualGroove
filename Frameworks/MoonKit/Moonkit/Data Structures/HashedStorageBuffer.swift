//
//  _HashedStorageBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct HashedStorageBuffer<Storage: HashedStorage where Storage:ConcreteHashedStorage>: CollectionType, MutableCollectionType, RangeReplaceableCollectionType {

  typealias HashedKey = Storage.HashedKey
  typealias HashedValue = Storage.HashedValue
  typealias Element = Storage.Element
  typealias _Element = Element
  typealias Index = Int
  typealias Buffer = HashedStorageBuffer<Storage>
  typealias SubSequence = Buffer

  private(set) var storage: Storage

  let initializedBuckets: BitMap
  let bucketMap: HashBucketMap
  let hashedKeys: UnsafeMutablePointer<HashedKey>
  let hashedValues: UnsafeMutablePointer<HashedValue>
  let keyIsValue: Bool

  private let initializeAtOffset: (Int, Element) -> Void
  private let destroyAtOffset: (Int) -> Void
  private let moveAtOffset: (Int) -> Element
  private let elementAtOffset: (Int) -> Element

  @inline(__always)
  mutating func isUniquelyReferenced() -> Bool {
    return Swift.isUniquelyReferenced(&storage)
  }

  let indexOffset: Int

  var startIndex: Int
  var endIndex: Int

  @inline(__always) private func offsetPosition(position: Int) -> Int { return position - indexOffset }
  @inline(__always) private func offsetPosition(position: Range<Int>) -> Range<Int> { return position - indexOffset }
  @inline(__always) private func offsetIndex(index: Int) -> Int { return index + indexOffset }
  @inline(__always) private func offsetIndex(index: Range<Int>) -> Range<Int> { return index + indexOffset }

  var count: Int { return endIndex - startIndex }
  var capacity: Int { return indexOffset == 0 ? storage.capacity - startIndex : storage.capacity }

  /// Returns the minimum capacity for storing `count` elements.
  @inline(__always)
  static func minimumCapacityForCount(count: Int) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count &+ 1)
  }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(initializedBuckets.buffer.baseAddress) }

  init(storage: Storage, indices: Range<Int>, indexOffset: Int) {
    self.storage = storage
    initializedBuckets = storage.initializedBuckets
    bucketMap = storage.bucketMap
    hashedKeys = storage.hashedKeyBaseAddress
    hashedValues = storage.hashedValueBaseAddress
    keyIsValue = UnsafePointer<Void>(hashedKeys) == UnsafePointer<Void>(hashedValues)
    initializeAtOffset = storage.initializeAtOffset()
    destroyAtOffset = storage.destroyAtOffset()
    moveAtOffset = storage.moveAtOffset()
    elementAtOffset = storage.elementAtOffset()

    self.indexOffset = indexOffset
    startIndex = indices.startIndex
    endIndex = indices.endIndex
  }

  init(minimumCapacity: Int, offsetBy offset: Int = 0) {
    let requiredCapacity = Buffer.minimumCapacityForCount(minimumCapacity)
    let storage = Storage.create(requiredCapacity)
    let indices = offset ..< offset
    self.init(storage: storage, indices: indices, indexOffset: offset)
  }

  init() { self.init(minimumCapacity: 0, offsetBy: 0) }

  init<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.underestimateCount())
    var buffer = Buffer(minimumCapacity: minimumCapacity, offsetBy: 0)

    var duplicates = 0

    for (position, element) in elements.enumerate() {
      if buffer.initializeElement(element, at: position - duplicates) {
        buffer.endIndex = buffer.endIndex &+ 1
      } else {
        duplicates = duplicates &+ 1
      }
    }
    buffer.storage.count = buffer.count

    self = buffer
  }

  /// Returns the bucket for `hashedKey` diregarding collisions
  private func idealBucketForKey(hashedKey: HashedKey) -> HashBucket {
    return suggestBucketForValue(hashedKey, capacity: storage.capacity)
  }

  /// Returns the bucket for `element` diregarding collisions
  private func idealBucketForElement(element: Element) -> HashBucket {
    return idealBucketForKey(Storage.keyForElement(element))
  }

  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
  private func positionForBucket(bucket: HashBucket) -> Int? {
    // defer { _fixLifetime(self) }
    return bucketMap[bucket]
  }

  /// Returns the bucket for the element assigned to `position`.
  /// - requires: A bucket has been assigned to `position`
  private func bucketForPosition(position: Int) -> HashBucket {
    // defer { _fixLifetime(self) }
    return bucketMap[offsetPosition(position)]
  }

  /// Returns `false` when `bucket` is empty and `true` otherwise.
  private func isInitializedBucket(bucket: HashBucket) -> Bool {
    // defer { _fixLifetime(self) }
    return initializedBuckets[bucket.offset]
  }

  /// Returns the hashed key for the specified bucket.
  private func keyForBucket(bucket: HashBucket) -> HashedKey {
    // defer { _fixLifetime(self) }
    return hashedKeys[bucket.offset]
  }

  /// Returns the hashed value for the specified bucket.
  private func valueForBucket(bucket: HashBucket) -> HashedValue {
    // defer { _fixLifetime(self) }
    return hashedValues[bucket.offset]
  }

  /// Returns the bucket containing `hashedKey` or `nil` if no bucket contains `member`.
  private func currentBucketForKey(key: HashedKey) -> HashBucket? {
    let (bucket, found) = find(key)
    return found ? bucket : nil
  }

  /// Returns whether `key` is present in the buffer.
  func containsKey(key: HashedKey) -> Bool {
    let (_, found) = find(key)
    return found
  }

  /// Returns the bucket containing `element` or `nil` if no bucket contains `element`.
  private func currentBucketForElement(element: Element) -> HashBucket? {
      return currentBucketForKey(Storage.keyForElement(element))
  }

  /// Returns an empty bucket suitable for holding `hashedKey` or `nil` if a bucket already contains `key`.
  private func emptyBucketForKey(key: HashedKey) -> HashBucket? {
    let (bucket, found) = find(key)
    return found ? nil : bucket
  }

  /// Returns an empty bucket suitable for holding `element` or `nil` if a bucket already contains `element`.
  private func emptyBucketForElement(element: Element) -> HashBucket? {
    return emptyBucketForKey(Storage.keyForElement(element))
  }

  /// Returns the hashed key for the specified position.
  /// - requires: A bucket has been assigned to `position`
  func keyForPosition(position: Int) -> HashedKey {
    return keyForBucket(bucketForPosition(position))
  }

  /// Returns the hashed value for the specified position.
  /// - requires: A bucket has been assigned to `position`
  func valueForPosition(position: Int) -> HashedValue {
    return valueForBucket(bucketForPosition(position))
  }

  /// Returns the position for `hashedKey` or `nil` if `hashedKey` is not found.
  func positionForKey(hashedKey: HashedKey) -> Int? {
    guard count > 0, let bucket = currentBucketForKey(hashedKey) else { return nil }
    return positionForBucket(bucket)
  }

  /// Returns the position for `element` or `nil` if `element` is not found.
  func positionForElement(element: Element) -> Int? {
    guard count > 0, let bucket = currentBucketForElement(element) else { return nil }
    return positionForBucket(bucket)
  }

  /// Returns the element in `bucket`.
  /// - requires: `bucket` contains an element.
  private func elementForBucket(bucket: HashBucket) -> Element {
    return elementAtOffset(bucket.offset)
  }

  /// Returns the element at `position`.
  /// - requires: a bucket has been assigned to `position`.
  func elementForPosition(position: Int) -> Element { return elementForBucket(bucketForPosition(position)) }

  /// Returns the current bucket for `key` and `true` when `key` is located;
  /// returns an open bucket for `key` and `false` otherwise
  /// - requires: At least one empty bucket
  private func find(key: HashedKey) -> (bucket: HashBucket, found: Bool) {
    let startBucket = idealBucketForKey(key)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard keyForBucket(bucket) != key  else { return (bucket, true) }
      bucket._successorInPlace()
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  /// Initializes `bucket` with `element` without assigning a position.
  private func initializeBucket(bucket: HashBucket, with element: Element) {
    // defer { _fixLifetime(self) }
    initializeAtOffset(bucket.offset, element)
    initializedBuckets[bucket.offset] = true
  }

  /// Initializes `bucket` with `element` at `position`.
  private func initializeBucket(bucket: HashBucket, with element: Element, at position: Int) {
    // defer { _fixLifetime(self) }
    initializeBucket(bucket, with: element)
    bucketMap[offsetPosition(position)] = bucket
  }

  /// Initializes a fresh bucket with `element` at `position` unless `element` is a duplicate. 
  /// Returns `true` if a bucket was initialized and `false` otherwise.
  func initializeElement(element: Element, at position: Int) -> Bool {
    guard let bucket = emptyBucketForElement(element) else { return false }
    initializeBucket(bucket, with: element, at: position)
    return true
  }

  /// Initializes a fresh bucket with `element` unless `element` is a duplicate.
  /// Returns `true` if a bucket was initialized and `false` otherwise.
  func initializeElement(element: Element) -> Bool {
    guard let bucket = emptyBucketForElement(element) else { return false }
    initializeBucket(bucket, with: element)
    return true
  }

  /// Removes the element from `bucket1` and uses this element to initialize `bucket2`
  private func moveBucket(bucket1: HashBucket, to bucket2: HashBucket) {
    // defer { _fixLifetime(self) }
    let element = moveAtOffset(bucket1.offset)
    initializeBucket(bucket2, with: element)
    initializedBuckets[bucket1.offset] = false
    bucketMap.replaceBucket(bucket1, with: bucket2)
  }

  /// Replaces the element at `position` with `element`.
  func replaceElementAt(position: Int, with element: Element) {
    destroyBucket(bucketForPosition(position))
    initializeElement(element, at: position)
  }

  mutating func replaceRange<
    C:CollectionType where C.Generator.Element == Element
    >(subRange: Range<Int>, with newElements: C)
  {
    // Remove values from buckets in `subRange`
    subRange.forEach { destroyBucket(bucketForPosition($0)) }

    // Insert new elements, accumulating a list of their buckets
    var newElementsBuckets = [HashBucket](minimumCapacity: numericCast(newElements.count))

    for element in newElements {
      guard let bucket = emptyBucketForElement(element) else { continue }
      initializeBucket(bucket, with: element)
      newElementsBuckets.append(bucket)
    }

    // Adjust positions
    bucketMap.replaceRange(offsetPosition(subRange), with: newElementsBuckets)

    let 𝝙elements = newElementsBuckets.count - subRange.count

    // Adjust count and endIndex
    storage.count += 𝝙elements
    endIndex += 𝝙elements
  }

  /// Attempts to move the values of the buckets near `hole` into buckets nearer to their 'ideal' bucket
  private func patchHole(hole: HashBucket, idealBucket: HashBucket) {

    var hole = hole
    var start = idealBucket
    while isInitializedBucket(start.predecessor()) { start._predecessorInPlace() }

    var lastInChain = hole
    var last = lastInChain.successor()
    while isInitializedBucket(last) { lastInChain = last; last._successorInPlace() }

    while hole != lastInChain {
      last = lastInChain
      FillHole: while last != hole {
        let key = keyForBucket(last)
        let bucket = idealBucketForKey(key)

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
      moveBucket(last, to: hole)
      hole = last
    }

  }

  /// Uninitializes `bucket`, destroys the element in `bucket`. Does not adjust positions.
  /// - requires: `bucket` contains an element.
  private func destroyBucket(bucket: HashBucket) {
    // defer { _fixLifetime(self) }
    initializedBuckets[bucket.offset] = false
    destroyAtOffset(bucket.offset)
  }

  /// Uninitializes the bucket for `position`, adjusts positions and `endIndex` and patches the hole.
  mutating func destroyAt(position: Index) {
    let hole = bucketForPosition(position)
    let idealBucket = idealBucketForKey(keyForBucket(hole))

    destroyBucket(hole)
    bucketMap.removeBucketAt(offsetPosition(position))
    endIndex -= 1
    patchHole(hole, idealBucket: idealBucket)
  }


  subscript(index: Int) -> Element {
    get { return elementForPosition(index) }
    set { replaceElementAt(index, with: newValue) }
  }

  subscript(subRange: Range<Int>) -> SubSequence {
    get { return SubSequence(storage: storage, indices: subRange, indexOffset: indexOffset) }
    set { replaceRange(subRange, with: newValue) }
  }

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible
extension HashedStorageBuffer: CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    if count == 0 { return keyIsValue ? "[]" : "[:]" }

    var result = "["
    var first = true
    for position in startIndex ..< endIndex {
      if first { first = false } else { result += ", " }
      let bucket = bucketMap[offsetPosition(position)]
      let element = elementForBucket(bucket)
      if keyIsValue {
        debugPrint(element, terminator: "",   toStream: &result)
      } else if let (key, value) = (element as? (HashedKey, HashedValue)) {
        debugPrint(key, terminator: ": ", toStream: &result)
        debugPrint(value, terminator: "",   toStream: &result)
      }
    }
    result += "]"
    return result
  }

  var description: String { return elementsDescription }

  var debugDescription: String {
    var result = elementsDescription + "\n"
    result += "startIndex = \(startIndex)\n"
    result += "endIndex = \(endIndex)\n"
    result += "indexOffset = \(indexOffset)\n"
    result += "count = \(count)\n"
    result += "capacity = \(capacity)\n"
    for position in startIndex ..< endIndex {
      let bucket = bucketMap[offsetPosition(position)]
      result += "position \(position) ➞ bucket \(bucket) [\(elementForBucket(bucket))]\n"
    }
    for position in endIndex ..< capacity {
      result += "position \(position), empty\n"
    }
    for bucket in 0 ..< bucketMap.capacity {
      if initializedBuckets[bucket] {
        let key = keyForBucket(HashBucket(offset: bucket, capacity: bucketMap.capacity))
        result += "bucket \(bucket), key = \(key), ideal bucket = \(idealBucketForKey(key))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }


}
