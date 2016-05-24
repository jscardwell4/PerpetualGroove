//
//  HashedStorageBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct HashedStorageBuffer<Storage: HashedStorage where Storage:ConcreteHashedStorage>: MutableCollectionType {

  typealias HashedKey = Storage.HashedKey
  typealias HashedValue = Storage.HashedValue
  typealias Element = Storage.Element
  typealias _Element = Element
  typealias Index = Int
  typealias Buffer = HashedStorageBuffer<Storage>
  typealias SubSequence = Buffer

  private(set) var storage: Storage

//  let initializedBuckets: BitMap
  let bucketMap: HashBucketMap
  let hashedKeys: UnsafeMutablePointer<HashedKey>
  let hashedValues: UnsafeMutablePointer<HashedValue>
  let keyIsValue: Bool

  private let initializeAtOffset: (Int, Element) -> Void
  private let destroyAtOffset: (Int) -> Void
  private let moveAtOffset: (Int) -> Element
  private let elementAtOffset: (Int) -> Element
  private let updateAtOffset: (Int, Element) -> Element

  @inline(__always)
  mutating func isUniquelyReferenced() -> Bool {
    return Swift.isUniquelyReferenced(&storage)
  }

  let indexOffset: Int

  var startIndex: Int
  var endIndex: Int

  @inline(__always) private func offsetPosition(position: Int) -> Int { return position &- indexOffset }
  @inline(__always) private func offsetPosition(position: Range<Int>) -> Range<Int> { return position &- indexOffset }
  @inline(__always) private func offsetIndex(index: Int) -> Int { return index &+ indexOffset }
  @inline(__always) private func offsetIndex(index: Range<Int>) -> Range<Int> { return index &+ indexOffset }

  var count: Int { return endIndex - startIndex }
  var capacity: Int { return indexOffset == 0 ? storage.capacity - startIndex : storage.capacity }

  /// Returns the minimum capacity for storing `count` elements.
  @inline(__always)
  static func minimumCapacityForCount(count: Int) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count &+ 1)
  }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(storage.withUnsafeMutablePointerToElements { $0 }) }

  init(storage: Storage, indices: Range<Int>, indexOffset: Int) {
    self.storage = storage
//    initializedBuckets = storage.initializedBuckets
    bucketMap = storage.bucketMap
    hashedKeys = storage.hashedKeyBaseAddress
    hashedValues = storage.hashedValueBaseAddress
    keyIsValue = UnsafePointer<Void>(hashedKeys) == UnsafePointer<Void>(hashedValues)
    initializeAtOffset = storage.initializeAtOffset()
    destroyAtOffset = storage.destroyAtOffset()
    moveAtOffset = storage.moveAtOffset()
    elementAtOffset = storage.elementAtOffset()
    updateAtOffset = storage.updateAtOffset()

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
    return bucketMap[bucket] != nil //initializedBuckets[bucket.offset]
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
//  private func initializeBucket(bucket: HashBucket, with element: Element) {
//    // defer { _fixLifetime(self) }
//    initializeAtOffset(bucket.offset, element)
//    initializedBuckets[bucket.offset] = true
//  }

  /// Initializes `bucket` with `element` at `position`.
  private func initializeBucket(bucket: HashBucket, with element: Element, at position: Int) {
    // defer { _fixLifetime(self) }
//    initializeBucket(bucket, with: element)
    initializeAtOffset(bucket.offset, element)
    bucketMap[offsetPosition(position)] = bucket
  }

  /// Initializes a fresh bucket with `element` at `position` unless `element` is a duplicate. 
  /// Returns `true` if a bucket was initialized and `false` otherwise.
  func initializeElement(element: Element, at position: Int) -> Bool {
    guard let bucket = emptyBucketForElement(element) else { return false }
    initializeBucket(bucket, with: element, at: position)
    return true
  }

  func updateElement(element: Element) -> Element {
    guard let currentBucket = currentBucketForElement(element) else {
      fatalError("element has no bucket: '\(element)'")
    }
    return updateAtOffset(currentBucket.offset, element)
  }

  /// Initializes a fresh bucket with `element` unless `element` is a duplicate.
  /// Returns `true` if a bucket was initialized and `false` otherwise.
//  func initializeElement(element: Element) -> Bool {
//    guard let bucket = emptyBucketForElement(element) else { return false }
//    initializeBucket(bucket, with: element)
//    return true
//  }

  /// Removes the element from `bucket1` and uses this element to initialize `bucket2`
  private func moveBucket(bucket1: HashBucket, to bucket2: HashBucket) {
    // defer { _fixLifetime(self) }
    let element = moveAtOffset(bucket1.offset)
    initializeAtOffset(bucket2.offset, element)//initializeBucket(bucket2, with: element)
//    initializedBuckets[bucket1.offset] = false
    bucketMap.replaceBucket(bucket1, with: bucket2)
  }

  /// Replaces the element at `position` with `element`.
  func replaceElementAt(position: Int, with element: Element) {
    destroyAtOffset(bucketForPosition(position).offset)
    initializeElement(element, at: position)
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
//  private func destroyBucket(bucket: HashBucket) {
//    // defer { _fixLifetime(self) }
////    initializedBuckets[bucket.offset] = false
//    destroyAtOffset(bucket.offset)
//  }

  /// Uninitializes the bucket for `position`, adjusts positions and `endIndex` and patches the hole.
  mutating func destroyAt(position: Index) {

    let hole = bucketForPosition(position)
    let idealBucket = idealBucketForKey(keyForBucket(hole))

    destroyAtOffset(hole.offset)//destroyBucket(hole)
    bucketMap.removeBucketAt(offsetPosition(position))
    endIndex = endIndex &- 1
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

// MARK: RangeReplaceableCollectionType
extension HashedStorageBuffer: RangeReplaceableCollectionType {

  /// Create an empty instance.
  init() { self.init(minimumCapacity: 0, offsetBy: 0) }

  /// Replace the given `subRange` of elements with `newElements`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`subRange.count`) if
  ///   `subRange.endIndex == self.endIndex` and `newElements.isEmpty`,
  ///   O(`self.count` + `newElements.count`) otherwise.
  mutating func replaceRange<
    C:CollectionType where C.Generator.Element == Element
    >(subRange: Range<Int>, with newElements: C)
  {

    removeRange(subRange)
    insertContentsOf(newElements, at: subRange.startIndex)
//    let removeCount = subRange.count
//    let insertCount = numericCast(newElements.count) as Int
//
//    for (index, element) in zip(subRange, newElements) {
//      let position = offsetPosition(index)
//      let oldBucket = bucketMap[position]
//      destroyAtOffset(oldBucket.offset)
//      bucketMap.buckets[oldBucket.offset] = -1
//      bucketMap.positions[position] = -1
//      guard let bucket = emptyBucketForElement(element) else { continue }
//      initializeAtOffset(bucket.offset, element)
//      bucketMap.buckets[bucket.offset] = position
//      bucketMap.positions[position] = bucket.offset
//    }
//
//    switch insertCount - removeCount {
//
//      case 0:
//        // Nothing more to do
//        break
//
//      case let delta where delta < 0:
//        // Empty remaining positions in `subRange`
//
//        let subSubRange = subRange.endIndex.advancedBy(delta) ..< subRange.endIndex
//        for index in subSubRange { destroyAtOffset(bucketForPosition(index).offset) }
//        bucketMap.replaceRange(offsetPosition(subSubRange), with: EmptyCollection())
//        storage.count = storage.count &+ delta
//        endIndex = endIndex &+ delta
//
//      default: /* case let delta where delta > 0 */
//
//        let subSubRange = newElements.startIndex.advancedBy(numericCast(removeCount)) ..< newElements.endIndex
//
//        // Insert new elements, accumulating a list of their buckets
//        var newElementsBuckets = [HashBucket](minimumCapacity: numericCast(subSubRange.count))
//        for index in subSubRange {
//          let element = newElements[index]
//          guard let bucket = emptyBucketForElement(element) else { continue }
//          initializeAtOffset(bucket.offset, element)
//          newElementsBuckets.append(bucket)
//        }
//
//        // Adjust positions
//        bucketMap.replaceRange(offsetPosition(subRange), with: newElementsBuckets)
//
//        let 𝝙elements = newElementsBuckets.count - subRange.count
//
//        // Adjust count and endIndex
//        storage.count = storage.count &+ 𝝙elements
//        endIndex = endIndex &+ 𝝙elements
//
//    }

  }

  /// A non-binding request to ensure `n` elements of available storage.
  ///
  /// This works as an optimization to avoid multiple reallocations of
  /// linear data structures like `Array`.  Conforming types may
  /// reserve more than `n`, exactly `n`, less than `n` elements of
  /// storage, or even ignore the request completely.
  mutating func reserveCapacity(n: Int) {
    guard capacity < n else { return }
    var buffer = Buffer(minimumCapacity: n, offsetBy: startIndex) //FIXME: Should this be `startIndex - indexOffset`?
    for element in self { buffer.append(element) }
    buffer.startIndex = startIndex
    buffer.endIndex = endIndex
    buffer.storage.count = storage.count
    self = buffer
  }

  /// Creates a collection instance that contains `elements`.
  init<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.underestimateCount())

    var buffer = Buffer(minimumCapacity: minimumCapacity, offsetBy: 0)
    buffer.appendContentsOf(elements)

    self = buffer
  }

  /// Append `x` to `self`.
  ///
  /// Applying `successor()` to the index of the new element yields
  /// `self.endIndex`.
  ///
  /// - Complexity: Amortized O(1).
  mutating func append(x: Element) {
    guard initializeElement(x, at: endIndex) else { return }
    endIndex = endIndex &+ 1
    storage.count = storage.count &+ 1
  }


  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  mutating func appendContentsOf<
    S:SequenceType where S.Generator.Element == Element
    >(newElements: S)
  {
    for element in newElements { append(element) }
  }


  /// Insert `newElement` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  mutating func insert(newElement: Element, atIndex i: Index) {
    guard let bucket = emptyBucketForElement(newElement) else { return }
    initializeAtOffset(bucket.offset, newElement)//initializeBucket(bucket, with: newElement)
    let index = offsetPosition(i)
    bucketMap.replaceRange(index ..< index, with: CollectionOfOne(bucket))
    endIndex = endIndex &+ 1
    storage.count = storage.count &+ 1
  }


  /// Insert `newElements` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count + newElements.count`).
  mutating func insertContentsOf<
    S:CollectionType where S.Generator.Element == Element
    >(newElements: S, at i: Index)
  {

    let index = offsetPosition(i)

    // Insert new elements, accumulating a list of their buckets
    var newElementsBuckets = [HashBucket](minimumCapacity: numericCast(newElements.count))

    for (i, element) in newElements.enumerate() {
      guard let bucket = emptyBucketForElement(element) else { continue }
      initializeAtOffset(bucket.offset, element)//initializeBucket(bucket, with: element)
      bucketMap.assign(index &+ i, to: bucket)
      newElementsBuckets.append(bucket)
    }

    // Adjust positions
    bucketMap.replaceRange(index ..< index, with: newElementsBuckets)

    let 𝝙elements = newElementsBuckets.count

    // Adjust count and endIndex
    storage.count += 𝝙elements
    endIndex += 𝝙elements

  }


  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  mutating func removeAtIndex(i: Index) -> Element {
    let result = elementForPosition(i)
    destroyAt(i)
    return result
  }


  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  mutating func removeFirst() -> Element { return removeAtIndex(startIndex) }


  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `n >= 0 && self.count >= n`.
  mutating func removeFirst(n: Int) {
    removeRange(startIndex ..< startIndex.advancedBy(n))
  }


  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  mutating func removeRange(subRange: Range<Index>) {

    let delta = subRange.count
    guard delta > 0 else { return }

    let buckets = subRange.map { bucketForPosition($0) }
    let idealBuckets = buckets.map { idealBucketForKey(keyForBucket($0)) }
    buckets.forEach { destroyAtOffset($0.offset) }
    zip(buckets, idealBuckets).forEach { patchHole($0, idealBucket: $1) }

//    for index in subRange { destroyAtOffset(bucketForPosition(index).offset) }
    bucketMap.replaceRange(offsetPosition(subRange), with: EmptyCollection())
    storage.count = storage.count &- delta
    endIndex = endIndex &- delta

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
  mutating func removeAll(keepCapacity keepCapacity: Bool) {
    guard keepCapacity else { self = Buffer.init(); return }
    for bucket in bucketMap { destroyAtOffset(bucket.offset) }
    bucketMap.removeAll()
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
    for bucketOffset in 0 ..< bucketMap.capacity {
      let bucket = HashBucket(offset: bucketOffset, capacity: bucketMap.capacity)
      if isInitializedBucket(bucket) {
        let key = keyForBucket(bucket)
        result += "bucket \(bucket), key = \(key), ideal bucket = \(idealBucketForKey(key))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }


}
