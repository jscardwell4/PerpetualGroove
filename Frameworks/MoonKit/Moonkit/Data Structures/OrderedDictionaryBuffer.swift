//
//  OrderedDictionaryBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/7/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct OrderedDictionaryBuffer<Key:Hashable, Value>: CollectionType, MutableCollectionType, RangeReplaceableCollectionType {

  typealias Index = Int
  typealias Element = (Key, Value)
  typealias _Element = Element
  typealias Storage = OrderedDictionaryStorage<Key, Value>
  typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  typealias SubSequence = Buffer

  private(set) var storage: Storage
  let initializedBuckets: BitMap
  let bucketMap: HashBucketMap
  let keysBaseAddress: UnsafeMutablePointer<Key>
  let valuesBaseAddress: UnsafeMutablePointer<Value>

  var startIndex: Index
  var endIndex: Index

  let indexOffset: Index

  @inline(__always) func offsetPosition(position: Int) -> Index { return position - indexOffset }
  @inline(__always) func offsetPosition(position: Range<Int>) -> Range<Index> { return position - indexOffset }
  @inline(__always) func offsetIndex(index: Index) -> Int { return index + indexOffset }
  @inline(__always) func offsetIndex(index: Range<Index>) -> Range<Int> { return index + indexOffset }

  var count: Int { return endIndex - startIndex }
  var capacity: Int { return indexOffset == 0 ? storage.capacity - startIndex : storage.capacity }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(initializedBuckets.buffer.baseAddress) }

  static func minimumCapacityForCount(count: Int) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  mutating func isUniquelyReferenced() -> Bool { return Swift.isUniquelyReferenced(&storage) }


  /// Returns the bucket for `key` diregarding collisions
  func idealBucketForKey(key: Key) -> HashBucket { return suggestBucketForValue(key, capacity: storage.capacity) }

  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
  func positionForBucket(bucket: HashBucket) -> Int? {
    guard let index = bucketMap[bucket] else { return nil }
    return offsetIndex(index)
  }

  /// Returns the bucket for the member assigned to `position`.
  /// - requires: A bucket has been assigned to `position`
  func bucketForPosition(position: Int) -> HashBucket { return bucketMap[offsetPosition(position)] }

  /// Returns the bucket containing `key` or `nil` if no bucket contains `member`.
  func currentBucketForKey(key: Key) -> HashBucket? {
    let (bucket, found) = find(key)
    return found ? bucket : nil
  }

  /// Returns an empty bucket suitable for holding `key` or `nil` if a bucket already contains `key`.
  func emptyBucketForKey(key: Key) -> HashBucket? {
    let (bucket, found) = find(key)
    return found ? nil : bucket
  }

  /// Returns the current bucket for `key` and `true` when `key` is located;
  /// returns an open bucket for `key` and `false` otherwise
  /// - requires: At least one empty bucket
  func find(key: Key) -> (bucket: HashBucket, found: Bool) {

    let startBucket = idealBucketForKey(key)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard keyInBucket(bucket) != key  else { return (bucket, true) }
      bucket._successorInPlace()
    } while bucket != startBucket

    print(storage.description)
    fatalError("failed to locate hole:\n\(debugDescription)")
  }

  /// Returns the key inserted into `bucket`
  func keyInBucket(bucket: HashBucket) -> Key { return keysBaseAddress[bucket.offset] }

  /// Returns the key assigned to `position`
  func keyAtPosition(position: Int) -> Key { return keyInBucket(bucketForPosition(position)) }

  /// Returns `false` when `bucket` is empty and `true` otherwise.
  func isInitializedBucket(bucket: HashBucket) -> Bool { return initializedBuckets[bucket] }

  /// Returns the position for `key` or `nil` if `member` is not found.
  func positionForKey(key: Key) -> Index? {
    guard count > 0, let bucket = currentBucketForKey(key) else { return nil }
    return positionForBucket(bucket)
  }

  /// Returns the value inserted into `bucket`
  func valueInBucket(bucket: HashBucket) -> Value { return valuesBaseAddress[bucket.offset] }

  /// Returns the value assigned to `position`
  func valueAtPosition(position: Int) -> Value { return valueInBucket(bucketForPosition(position)) }

  /// Returns the value associated with `key` or `nil` if `key` is not present.
  func valueForKey(key: Key) -> Value? {
    guard count > 0 else { return nil }
    let (bucket, found) = find(key)
    return found ? valueInBucket(bucket) : nil
  }

  /// Convenience for retrieving both the key and value for a bucket.
  func elementInBucket(bucket: HashBucket) -> (Key, Value) { return (keyInBucket(bucket), valueInBucket(bucket)) }

  /// Convenience for retrieving both the key and value for a position.
  func elementAtPosition(position: Int) -> (Key, Value) { return elementInBucket(bucketForPosition(position)) }

  init(storage: Storage, indices: Range<Index>, offset: Index = 0) {
    self.storage = storage
    initializedBuckets = storage.initializedBuckets
    bucketMap = storage.bucketMap
    keysBaseAddress = storage.keys
    valuesBaseAddress = storage.values

    indexOffset = offset
    startIndex = indices.startIndex
    endIndex = indices.endIndex
  }

  init<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.underestimateCount())
    var buffer = Buffer(minimumCapacity: minimumCapacity)

    var duplicates = 0

    for (position, (key, value)) in elements.enumerate() {
      let (bucket, found) = buffer.find(key)
      if found {
        duplicates += 1
        continue
      } else {
        buffer.initializeKey(key, forValue: value, position: position - duplicates, bucket: bucket)
        buffer.endIndex += 1
      }
    }

    buffer.storage.count = buffer.count
    self = buffer
  }

  init() { self.init(minimumCapacity: 2) }

  init(minimumCapacity: Int, offsetBy offset: Index = 0) {
    let requiredCapacity = Buffer.minimumCapacityForCount(minimumCapacity)
    let storage = Storage.create(requiredCapacity)
    let indices = offset ..< offset
    self.init(storage: storage, indices: indices, offset: offset)
  }

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
        let key = keyInBucket(last)
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
      moveElementInBucket(last, toBucket: hole)
      hole = last
    }

  }

  func destroyBucket(bucket: HashBucket) {
    initializedBuckets[bucket] = false
    (keysBaseAddress + bucket.offset).destroy()
    (valuesBaseAddress + bucket.offset).destroy()
  }

  mutating func destroyElementAt(position: Index) {
    defer { _fixLifetime(self) }
    let hole = bucketForPosition(position)
    let idealBucket = idealBucketForKey(keyInBucket(hole))

    destroyBucket(hole)
    bucketMap.removeBucketAt(offsetPosition(position))

    endIndex -= 1

    _patchHole(hole, idealBucket: idealBucket)

  }

  /// - requires: A key-value pair has been assigned to `position`
  func replaceElementAtPosition(position: Index, with element: Element) {
    let bucket = bucketForPosition(position)
    guard keyInBucket(bucket) != element.0 else { setValue(element.1, inBucket: bucket); return }
    guard let emptyBucket = emptyBucketForKey(element.0) else {
      fatalError("failed to locate an empty bucket for key '\(element.0)'")
    }
    destroyBucket(bucket)
    initializeKey(element.0, forValue: element.1, position: position, bucket: emptyBucket)
  }
  
  mutating func replaceRange<
    C:CollectionType where C.Generator.Element == Element
    >(subRange: Range<Index>, with newElements: C)
  {
    defer { _fixLifetime(self) }

    assert(indices.contains(subRange), "Invalid subrange '\(subRange)' for slice with indices '\(indices)'")

    // Remove values from buckets in `subRange`

    subRange.forEach { destroyBucket(bucketForPosition($0)) }

    // Insert new elements, accumulating a list of their buckets
    var newElementsBuckets = [HashBucket](minimumCapacity: numericCast(newElements.count))

    for (key, value) in newElements {
      let (bucket, found) = find(key)
      guard !found else { continue }
      initializeBucket(bucket, with: key, forValue: value)
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

  func initializeBucket(bucket: HashBucket, with key: Key, forValue value: Value) {
    defer { _fixLifetime(self) }
    (keysBaseAddress + bucket.offset).initialize(key)
    (valuesBaseAddress + bucket.offset).initialize(value)
    initializedBuckets[bucket] = true
  }

  func initializeKey(key: Key, forValue value: Value, position: Int, bucket: HashBucket) {
    defer { _fixLifetime(self) }
    initializeBucket(bucket, with: key, forValue: value)
    bucketMap[offsetPosition(position)] = bucket
  }

  func initializeKey(key: Key, forValue value: Value, position: Int) {
    let (bucket, _) = find(key)
    initializeKey(key, forValue: value, position: position, bucket: bucket)
  }

  func initializeKey(key: Key, forValue value: Value, bucket: HashBucket) {
    initializeKey(key, forValue: value, position: endIndex, bucket: bucket)
  }

  /// Removes the value from `bucket1` and uses this value to initialize `bucket2`
  func moveElementInBucket(bucket1: HashBucket, toBucket bucket2: HashBucket) {
    initializeBucket(bucket2, with: (keysBaseAddress + bucket1.offset).move(), forValue: (valuesBaseAddress + bucket1.offset).move())
    initializedBuckets[bucket1] = false
    bucketMap.replaceBucket(bucket1, with: bucket2)
  }

  // MARK: Assigning into already initialized data

  func setValue(value: Value, at position: Index) {
    setValue(value, inBucket: bucketForPosition(position))
  }

  func setValue(value: Value, inBucket bucket: HashBucket) {
    (valuesBaseAddress + bucket.offset).initialize(value)
  }
  
  // MARK: Subscripting

  subscript(index: Index) -> Element {
    get { return elementAtPosition(index) }
    set { replaceElementAtPosition(index, with: newValue) }
  }

  subscript(subRange: Range<Index>) -> SubSequence {
    get { return SubSequence(storage: storage, indices: subRange) }
    set { replaceRange(subRange, with: newValue) }
  }
  
}

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension OrderedDictionaryBuffer : CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    if count == 0 { return "[:]" }

    var result = "["
    var first = true
    for position in startIndex ..< endIndex {
      if first { first = false } else { result += ", " }
      let bucket = bucketMap[offsetPosition(position)]
      debugPrint(keysBaseAddress[bucket.offset], terminator: ": ", toStream: &result)
      debugPrint(valuesBaseAddress[bucket.offset], terminator: "",   toStream: &result)
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
      let key = keyInBucket(bucket)
      let value = valueInBucket(bucket)
      result += "position \(position) ➞ bucket \(bucket) [\(key): \(value)]\n"
    }
    for position in endIndex ..< capacity {
      result += "position \(position), empty\n"
    }
    for bucket in 0 ..< bucketMap.capacity {
      if initializedBuckets[bucket] {
        let key = keysBaseAddress[bucket]
        result += "bucket \(bucket), key = \(key), ideal bucket = \(idealBucketForKey(key))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }
}

