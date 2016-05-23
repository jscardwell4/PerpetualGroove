//
//  OrderedSetBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

//private let maxLoadFactorInverse = 1/0.75

struct OrderedSetBuffer<Element:Hashable>: CollectionType, MutableCollectionType, RangeReplaceableCollectionType {

  typealias Index = Int
  typealias _Element = Element
  typealias HashKey = Element

  typealias Buffer = OrderedSetBuffer<Element>
  typealias Storage = OrderedSetStorage<Element>
  typealias SubSequence = Buffer

  // MARK: Pointers to the underlying memory

  private(set) var storage: Storage
  let initializedBuckets: BitMap
  let bucketMap: HashBucketMap
  let elements: UnsafeMutablePointer<Element>

  var hashKeyBaseAddress: UnsafeMutablePointer<HashKey> { return elements }

  var startIndex: Index
  var endIndex: Index

  let indexOffset: Index

  @inline(__always) func offsetPosition(position: Int) -> Index { return position - indexOffset }
  @inline(__always) func offsetPosition(position: Range<Int>) -> Range<Index> { return position - indexOffset }
  @inline(__always) func offsetIndex(index: Index) -> Int { return index + indexOffset }
  @inline(__always) func offsetIndex(index: Range<Index>) -> Range<Int> { return index + indexOffset }

  var count: Int { return endIndex - startIndex }
  var capacity: Int { return indexOffset == 0 ? storage.capacity - startIndex : storage.capacity }
  
  mutating func isUniquelyReferenced() -> Bool { return Swift.isUniquelyReferenced(&storage) }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(initializedBuckets.buffer.baseAddress) }

  // MARK: Initializing by capacity

  init() { self.init(minimumCapacity: 2) }

  init(minimumCapacity: Int, offsetBy offset: Index = 0) {
    let requiredCapacity = Buffer.minimumCapacityForCount(minimumCapacity)
    let storage = Storage.create(requiredCapacity)
    let indices = offset ..< offset
    self.init(storage: storage, bucketMap: HashBucketMap(capacity: storage.capacity), indices: indices, indexOffset: offset)
  }

  static func minimumCapacityForCount(count: Int) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  // MARK: Initializing with data

  init(storage: Storage, bucketMap: HashBucketMap, indices: Range<Index>, indexOffset: Index = 0) {
    self.storage = storage
    initializedBuckets = storage.initializedBuckets
    self.bucketMap = bucketMap
    elements = storage.values

    self.indexOffset = indexOffset
    startIndex = indices.startIndex
    endIndex = indices.endIndex
  }

  init<S:SequenceType where S.Generator.Element == Element>(elements: S, capacity: Int? = nil) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.underestimateCount())
    var buffer = Buffer(minimumCapacity: minimumCapacity)

    var duplicates = 0

    for (position, element) in elements.enumerate() {
      let (bucket, found) = buffer.find(element)
      if found {
        duplicates += 1
        continue
      } else {
        buffer.initializeBucket(bucket, with: element, at: position - duplicates)
        buffer.endIndex += 1
      }
    }
    buffer.storage.count = buffer.count

    self = buffer
  }


  // MARK: Queries

  /// Returns the bucket for `element` diregarding collisions
  func idealBucketForElement(element: Element) -> HashBucket {
    return suggestBucketForValue(element, capacity: storage.capacity)
  }

  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
  func positionForBucket(bucket: HashBucket) -> Index? {
    return bucketMap[bucket]
  }

  /// Returns the bucket for the element assigned to `position`.
  /// - requires: A bucket has been assigned to `position`
  func bucketForPosition(position: Index) -> HashBucket {
    return bucketMap[offsetPosition(position)]
  }

  /// Returns the bucket containing `element` or `nil` if no bucket contains `element`.
  func currentBucketForElement(element: Element) -> HashBucket? {
    let (bucket, found) = find(element)
    return found ? bucket : nil
  }

  /// Returns an empty bucket suitable for holding `element` or `nil` if a bucket already contains `element`.
  func emptyBucketForElement(element: Element) -> HashBucket? {
    let (bucket, found) = find(element)
    return found ? nil : bucket
  }

  /// Returns the current bucket for `element` and `true` when `element` is located;
  /// returns an open bucket for `element` and `false` otherwise
  /// - requires: At least one empty bucket
  func find(element: Element) -> (bucket: HashBucket, found: Bool) {

    let startBucket = idealBucketForElement(element)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard elementForBucket(bucket) != element  else { return (bucket, true) }
      bucket._successorInPlace()
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  /// Returns the value inserted into `bucket`
  func elementForBucket(bucket: HashBucket) -> Element { return elements[bucket.offset] }

  /// Returns the value assigned to `position`
  func elementForPosition(position: Index) -> Element {
    return elementForBucket(bucketForPosition(position))
  }

  /// Returns `false` when `bucket` is empty and `true` otherwise.
  func isInitializedBucket(bucket: HashBucket) -> Bool { return initializedBuckets[bucket.offset] }

  /// Returns the position for `element` or `nil` if `element` is not found.
  func positionForElement(element: Element) -> Index? {
    guard count > 0, let bucket = currentBucketForElement(element) else { return nil }
    return positionForBucket(bucket)
  }

  // MARK: Removing data

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
        let value = elementForBucket(last)
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
      moveBucket(last, to: hole)
      hole = last
    }

  }

  func destroyBucket(bucket: HashBucket) {
    initializedBuckets[bucket.offset] = false
    (elements + bucket.offset).destroy()
  }

  mutating func destroyAt(position: Index) {
    defer { _fixLifetime(self) }
    let hole = bucketForPosition(position)
    let idealBucket = idealBucketForElement(elementForBucket(hole))

    destroyBucket(hole)
    bucketMap.removeBucketAt(offsetPosition(position))

    endIndex -= 1

    patchHole(hole, idealBucket: idealBucket)

  }

  /// - requires: A element has been assigned to `position`
  func replaceElementAt(position: Index, with element: Element) {
    let bucket = bucketForPosition(position)
    guard elementForBucket(bucket) != element else { return }
    guard let emptyBucket = emptyBucketForElement(element) else {
      fatalError("failed to locate an empty bucket for '\(element)'")
    }
    destroyBucket(bucket)
    initializeBucket(emptyBucket, with: element, at: position)
  }

  mutating func replaceRange<C:CollectionType
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
    bucketMap.replaceRange(offsetPosition(subRange), with: newElementsBuckets)

    let 𝝙elements = newElementsBuckets.count - subRange.count

    // Adjust count and endIndex
    storage.count += 𝝙elements
    endIndex += 𝝙elements
    
  }


  // MARK: Initializing with data

  func initializeBucket(bucket: HashBucket, with element: Element) {
    (elements + bucket.offset).initialize(element)
    initializedBuckets[bucket.offset] = true
  }

  func initializeBucket(bucket: HashBucket, with element: Element, at position: Int ) {
    defer { _fixLifetime(self) }
    initializeBucket(bucket, with: element)
    bucketMap[offsetPosition(position)] = bucket
  }

  func initializeElement(element: Element, at position: Int) {
    let (bucket, _) = find(element)
    initializeBucket(bucket, with: element, at: position)
  }

  /// Removes the value from `bucket1` and uses this value to initialize `bucket2`
  func moveBucket(bucket1: HashBucket, to bucket2: HashBucket) {
    initializeBucket(bucket2, with: (elements + bucket1.offset).move())
    initializedBuckets[bucket1.offset] = false
    bucketMap.replaceBucket(bucket1, with: bucket2)
  }

  // MARK: Subscripting

  subscript(index: Index) -> Element {
    get { return elementForPosition(index) }
    set { replaceElementAt(index, with: newValue) }
  }

  subscript(subRange: Range<Index>) -> SubSequence {
    get { return SubSequence(storage: storage, bucketMap: bucketMap[subRange], indices: subRange) }
    set { replaceRange(subRange, with: newValue) }
  }

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension OrderedSetBuffer : CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    if count == 0 { return "[]" }

    var result = "["
    var first = true
    for position in startIndex ..< endIndex {
      if first { first = false } else { result += ", " }
      let bucket = bucketMap[offsetPosition(position)]
      debugPrint(elements[bucket.offset], terminator: "",   toStream: &result)
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
        let element = elements[bucket]
        result += "bucket \(bucket), ideal bucket = \(idealBucketForElement(element))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }
}
