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

  mutating func isUniquelyReferenced() -> Bool {
    return Swift.isUniquelyReferenced(&storage)
  }

  let indexOffset: Int

  var startIndex: Int
  var endIndex: Int

  @inline(__always) func offsetPosition(position: Int) -> Int { return position - indexOffset }
  @inline(__always) func offsetPosition(position: Range<Int>) -> Range<Int> { return position - indexOffset }
  @inline(__always) func offsetIndex(index: Int) -> Int { return index + indexOffset }
  @inline(__always) func offsetIndex(index: Range<Int>) -> Range<Int> { return index + indexOffset }

  var count: Int { return endIndex - startIndex }
  var capacity: Int { return indexOffset == 0 ? storage.capacity - startIndex : storage.capacity }

  /// Returns the minimum capacity for storing `count` elements.
  static func minimumCapacityForCount(count: Int) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(initializedBuckets.buffer.baseAddress) }

  init(storage: Storage, indices: Range<Int>, indexOffset: Int) {
    self.storage = storage
    initializedBuckets = storage.initializedBuckets
    bucketMap = storage.bucketMap
    hashedKeys = storage.hashedKeyBaseAddress
    hashedValues = storage.hashedValueBaseAddress
    keyIsValue = UnsafePointer<Void>(hashedKeys) == UnsafePointer<Void>(hashedValues)

    self.indexOffset = indexOffset
    startIndex = indices.startIndex
    endIndex = indices.endIndex
  }

  init(minimumCapacity: Int, offsetBy offset: Int) {
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
      if buffer.initializeElement(element, at: position - duplicates) != nil {
        buffer.endIndex += 1
      } else {
        duplicates += 1
      }
    }
    buffer.storage.count = buffer.count

    self = buffer
  }

  /// Returns the bucket for `hashedKey` diregarding collisions
  func idealBucketFor(hashedKey: HashedKey) -> HashBucket {
    return suggestBucketForValue(hashedKey, capacity: storage.capacity)
  }

  /// Returns the bucket for `element` diregarding collisions
  func idealBucketFor(element: Element) -> HashBucket {
    if keyIsValue, let key = element as? HashedKey { return idealBucketFor(key) }
    else if let (key, _) = (element as? (HashedKey, HashedValue)) {
      return idealBucketFor(key)
    } else {
      fatalError("Unhandled element type '\(Element.self)'")
    }
  }

  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
  func positionForBucket(bucket: HashBucket) -> Int? { return bucketMap[bucket] }

  /// Returns the bucket for the element assigned to `position`.
  /// - requires: A bucket has been assigned to `position`
  func bucketForPosition(position: Int) -> HashBucket { return bucketMap[offsetPosition(position)] }

  /// Returns `false` when `bucket` is empty and `true` otherwise.
  func isInitializedBucket(bucket: HashBucket) -> Bool { return initializedBuckets[bucket] }

  /// Returns the hashed key for the specified bucket.
  func hashedKeyInBucket(bucket: HashBucket) -> HashedKey { return hashedKeys[bucket.offset] }

  /// Returns the hashed value for the specified bucket.
  func hashedValueInBucket(bucket: HashBucket) -> HashedValue { return hashedValues[bucket.offset] }

  /// Returns the bucket containing `hashedKey` or `nil` if no bucket contains `member`.
  func currentBucketFor(hashedKey: HashedKey) -> HashBucket? {
    let (bucket, found) = find(hashedKey)
    return found ? bucket : nil
  }

  /// Returns the bucket containing `element` or `nil` if no bucket contains `element`.
  func currentBucketFor(element: Element) -> HashBucket? {
    if let (key, _) = (element as? (HashedKey, HashedValue)) {
      return currentBucketFor(key)
    } else if let key = element as? HashedKey where keyIsValue {
      return currentBucketFor(key)
    } else {
      fatalError("Unhandled element type '\(Element.self)'")
    }
  }

  /// Returns an empty bucket suitable for holding `hashedKey` or `nil` if a bucket already contains `key`.
  func emptyBucketFor(hashedKey: HashedKey) -> HashBucket? {
    let (bucket, found) = find(hashedKey)
    return found ? nil : bucket
  }

  /// Returns an empty bucket suitable for holding `element` or `nil` if a bucket already contains `element`.
  func emptyBucketFor(element: Element) -> HashBucket? {
    if let (key, _) = (element as? (HashedKey, HashedValue)) {
      return emptyBucketFor(key)
    } else if let key = element as? HashedKey where keyIsValue {
      return emptyBucketFor(key)
    } else {
      fatalError("Unhandled element type '\(Element.self)'")
    }
  }

  /// Returns the hashed key for the specified position.
  /// - requires: A bucket has been assigned to `position`
  func hashedKeyAtPosition(position: Int) -> HashedKey {
    return hashedKeyInBucket(bucketForPosition(position))
  }

  /// Returns the hashed value for the specified position.
  /// - requires: A bucket has been assigned to `position`
  func hashedValueAtPosition(position: Int) -> HashedValue {
    return hashedValueInBucket(bucketForPosition(position))
  }

  /// Returns the position for `hashedKey` or `nil` if `hashedKey` is not found.
  func positionForKey(hashedKey: HashedKey) -> Int? {
    guard count > 0, let bucket = currentBucketFor(hashedKey) else { return nil }
    return positionForBucket(bucket)
  }

  /// Returns the position for `element` or `nil` if `element` is not found.
  func positionForElement(element: Element) -> Int? {
    guard count > 0, let bucket = currentBucketFor(element) else { return nil }
    return positionForBucket(bucket)
  }

  /// Returns the element in `bucket`.
  /// - requires: `bucket` contains an element.
  func elementForBucket(bucket: HashBucket) -> Element {
    if keyIsValue {
      let key = hashedKeyInBucket(bucket)
      guard let element = key as? Element else {
        fatalError("Unhandled element type '\(Element.self)'")
      }
      return element
    } else {
      let key = hashedKeyInBucket(bucket)
      let value = hashedValueInBucket(bucket)
      guard let element = (key, value) as? Element else {
        fatalError("Unhandled element type '\(Element.self)'")
      }
      return element
    }
  }

  /// Returns the element at `position`.
  /// - requires: a bucket has been assigned to `position`.
  func elementForPosition(position: Int) -> Element { return elementForBucket(bucketForPosition(position)) }

  /// Returns the current bucket for `hashedKey` and `true` when `hashedKey` is located;
  /// returns an open bucket for `hashedKey` and `false` otherwise
  /// - requires: At least one empty bucket
  func find(hashedKey: HashedKey) -> (bucket: HashBucket, found: Bool) {
    let startBucket = idealBucketFor(hashedKey)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard hashedKeyInBucket(bucket) != hashedKey  else { return (bucket, true) }
      bucket._successorInPlace()
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  /// Initializes `bucket` with `element` without assigning a position.
  func initializeBucket(bucket: HashBucket, with element: Element) {
    if let (key, value) = (element as? (HashedKey, HashedValue)) {
      (hashedKeys + bucket.offset).initialize(key)
      (hashedValues + bucket.offset).initialize(value)
    } else if let key = element as? HashedKey where keyIsValue {
      (hashedKeys + bucket.offset).initialize(key)
    } else {
      fatalError("Unhandled element type '\(Element.self)'")
    }
    initializedBuckets[bucket] = true
  }

  /// Initializes `bucket` with `element` at `position`.
  func initializeBucket(bucket: HashBucket, with element: Element, at position: Int) {
    initializeBucket(bucket, with: element)
    bucketMap[offsetPosition(position)] = bucket
  }

  /// Initializes a fresh bucket with `element` at `position` unless `element` is a duplicate. Returns the bucket or nil.
  func initializeElement(element: Element, at position: Int) -> HashBucket? {
    guard let bucket = emptyBucketFor(element) else { return nil }
    initializeBucket(bucket, with: element, at: position)
    return bucket
  }

  /// Initializes a fresh bucket with `element` unless `element` is a duplicate. Returns the bucket or nil.
  func initializeElement(element: Element) -> HashBucket? {
    guard let bucket = emptyBucketFor(element) else { return nil }
    initializeBucket(bucket, with: element)
    return bucket
  }

  /// Removes the element from `bucket1` and uses this element to initialize `bucket2`
  func moveBucket(bucket1: HashBucket, to bucket2: HashBucket) {
    if keyIsValue,
      let element = (hashedValues + bucket1.offset).move() as? Element
    {
      initializeBucket(bucket2, with: element)
    } else if let element = ((hashedKeys + bucket1.offset).move(),
                             (hashedValues + bucket1.offset).move()) as? Element
    {
      initializeBucket(bucket2, with: element)
    } else {
      fatalError("Unhandled element type '\(Element.self)'")
    }

    initializedBuckets[bucket1] = false
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
      guard let bucket = initializeElement(element) else { continue }
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
  func patchHole(hole: HashBucket, idealBucket: HashBucket) {

    var hole = hole
    var start = idealBucket
    while isInitializedBucket(start.predecessor()) { start._predecessorInPlace() }

    var lastInChain = hole
    var last = lastInChain.successor()
    while isInitializedBucket(last) { lastInChain = last; last._successorInPlace() }

    while hole != lastInChain {
      last = lastInChain
      FillHole: while last != hole {
        let key = hashedKeyInBucket(last)
        let bucket = idealBucketFor(key)

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
  func destroyBucket(bucket: HashBucket) {
    initializedBuckets[bucket] = false
    (hashedKeys + bucket.offset).destroy()
    if !keyIsValue { (hashedValues + bucket.offset).destroy() }
  }

  /// Uninitializes the bucket for `position`, adjusts positions and `endIndex` and patches the hole.
  mutating func destroyAt(position: Index) {
    let hole = bucketForPosition(position)
    let idealBucket = idealBucketFor(hashedKeyInBucket(hole))

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
    get { return SubSequence(storage: storage, indices: subRange, indexOffset: 0) }
    set { replaceRange(subRange, with: newValue) }
  }

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible
extension HashedStorageBuffer: CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    if count == 0 { return "[:]" }

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
        let key = hashedKeyInBucket(HashBucket(offset: bucket, capacity: bucketMap.capacity))
        result += "bucket \(bucket), key = \(key), ideal bucket = \(idealBucketFor(key))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }


}
