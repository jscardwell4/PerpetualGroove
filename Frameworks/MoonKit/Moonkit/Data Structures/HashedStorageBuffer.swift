//
//  HashedStorageBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

enum ___HashedStorageBuffer<HashKey:Hashable, Value> {
  typealias Member = HashKey
  typealias Key = HashKey
  typealias SetBuffer = OrderedSetBuffer<Member>
  typealias DictionaryBuffer = OrderedDictionaryBuffer<Key, Value>
  typealias SetStorage = OrderedSetStorage<Member>
  typealias DictionaryStorage = OrderedDictionaryStorage<Key, Value>


  case OrderedSet(SetBuffer)
  case OrderedDictionary(DictionaryBuffer)

  typealias Index = Int

  var storage: HashedStorage {
    switch self {
      case .OrderedSet(let buffer): return buffer.storage
      case .OrderedDictionary(let buffer): return buffer.storage
    }
  }

  func isUniquelyReferenced() -> Bool {
    var storage = self.storage
    return Swift.isUniquelyReferenced(&storage)
  }

  var indexOffset: Index {
    switch self {
    case .OrderedSet(let buffer): return buffer.indexOffset
    case .OrderedDictionary(let buffer): return buffer.indexOffset
    }
  }

  @inline(__always) func offsetPosition(position: Int) -> Index { return position - indexOffset }
  @inline(__always) func offsetPosition(position: Range<Int>) -> Range<Index> { return position - indexOffset }
  @inline(__always) func offsetIndex(index: Index) -> Int { return index + indexOffset }
  @inline(__always) func offsetIndex(index: Range<Index>) -> Range<Int> { return index + indexOffset }

  var startIndex: Index {
    get {
      switch self {
        case .OrderedSet(let buffer): return buffer.startIndex
        case .OrderedDictionary(let buffer): return buffer.startIndex
      }
    }
    set {
      switch self {
        case .OrderedSet(var buffer): buffer.startIndex = newValue; self = .OrderedSet(buffer)
        case .OrderedDictionary(var buffer): buffer.startIndex = newValue; self = .OrderedDictionary(buffer)
      }
    }
  }

  var endIndex: Index {
    get {
      switch self {
        case .OrderedSet(let buffer): return buffer.endIndex
        case .OrderedDictionary(let buffer): return buffer.endIndex
      }
    }
    set {
      switch self {
      case .OrderedSet(var buffer): buffer.endIndex = newValue; self = .OrderedSet(buffer)
      case .OrderedDictionary(var buffer): buffer.endIndex = newValue; self = .OrderedDictionary(buffer)
      }
    }
  }

  var count: Int { return endIndex - startIndex }

  static func minimumCapacityForCount(count: Int) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  var bucketMap: HashBucketMap { return storage.bucketMap }

  var initializedBuckets: BitMap { return storage.initializedBuckets }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(initializedBuckets.buffer.baseAddress) }

  /// Returns the bucket for `hashKey` diregarding collisions
  func idealBucketFor(hashKey: HashKey) -> HashBucket {
    return suggestBucketForValue(hashKey, capacity: storage.capacity)
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

  /// Returns `false` when `bucket` is empty and `true` otherwise.
  func isInitializedBucket(bucket: HashBucket) -> Bool { return initializedBuckets[bucket] }

  func hashKeyInBucket(bucket: HashBucket) -> HashKey {
    switch storage {

      case let storage as SetStorage:
        return storage.values[bucket.offset]

      case let storage as OrderedDictionaryStorage<Key, Value>:
        return storage.keys[bucket.offset]

      default: fatalError("The impossible happened")
    }
  }

  /// Returns the bucket containing `hashKey` or `nil` if no bucket contains `member`.
  func currentBucketFor(hashKey: HashKey) -> HashBucket? {
    let (bucket, found) = find(hashKey)
    return found ? bucket : nil
  }

  /// Returns an empty bucket suitable for holding `hashKey` or `nil` if a bucket already contains `key`.
  func emptyBucketFor(hashKey: HashKey) -> HashBucket? {
    let (bucket, found) = find(hashKey)
    return found ? nil : bucket
  }

  /// Returns the value inserted into `bucket`.
  /// - requires: An `OrderedSet`-based instance.
  func memberInBucket(bucket: HashBucket) -> Member {
    switch storage {
      case let storage as SetStorage: return storage.values[bucket.offset]
      default: fatalError("\(#function) requires a buffer backed by OrderedSetStorage")
    }
  }

  /// Returns the value assigned to `position`.
  /// - requires: An `OrderedSet`-based instance.
  func memberAtPosition(position: Index) -> Member {
    return memberInBucket(bucketForPosition(position))
  }

  /// Returns the position for `hashKey` or `nil` if `hashKey` is not found.
  func positionFor(hashKey: HashKey) -> Index? {
    guard count > 0, let bucket = currentBucketFor(hashKey) else { return nil }
    return positionForBucket(bucket)
  }

  /// Returns the current bucket for `hashKey` and `true` when `hashKey` is located;
  /// returns an open bucket for `hashKey` and `false` otherwise
  /// - requires: At least one empty bucket
  func find(hashKey: HashKey) -> (bucket: HashBucket, found: Bool) {
    let startBucket = idealBucketFor(hashKey)
    var bucket = startBucket

    switch storage {

      case let storage as SetStorage:
        repeat {
          guard isInitializedBucket(bucket) else { return (bucket, false) }
          guard storage.values[bucket.offset] != hashKey  else { return (bucket, true) }
          bucket._successorInPlace()
      } while bucket != startBucket

      case let storage as OrderedDictionaryStorage<Key, Value>:
        repeat {
          guard isInitializedBucket(bucket) else { return (bucket, false) }
          guard storage.keys[bucket.offset] != hashKey  else { return (bucket, true) }
          bucket._successorInPlace()
        } while bucket != startBucket

      default: fatalError("The impossible happened")

    }

    fatalError("failed to locate hole")
  }

  func initializeBucket(bucket: HashBucket, with key: Key, forValue value: Value) {
    switch storage {
      case let storage as OrderedDictionaryStorage<Key, Value>:
        (storage.keys + bucket.offset).initialize(key)
        (storage.values + bucket.offset).initialize(value)
        initializedBuckets[bucket] = true

      default: fatalError("\(#function) requires a buffer backed by OrderedDictionaryStorage")
    }
  }

  func initializeKey(key: Key, forValue value: Value, position: Int, bucket: HashBucket) {
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


  func initializeBucket(bucket: HashBucket, with member: Member) {
    switch storage {
      case let storage as SetStorage:
        (storage.values + bucket.offset).initialize(member)
        initializedBuckets[bucket] = true

      default: fatalError("\(#function) requires a buffer backed by OrderedSetStorage")
    }
  }

  func initializeMember(member: Member, position: Int, bucket: HashBucket) {
    initializeBucket(bucket, with: member)
    bucketMap[offsetPosition(position)] = bucket
  }

  func initializeMember(member: Member, position: Int) {
    let (bucket, _) = find(member)
    initializeMember(member, position: position, bucket: bucket)
  }

  func initializeMember(member: Member, bucket: HashBucket) {
    initializeMember(member, position: endIndex, bucket: bucket)
  }

  /// Removes the element from `bucket1` and uses this element to initialize `bucket2`
  func moveBucket(bucket1: HashBucket, to bucket2: HashBucket) {
    switch storage {

      case let storage as DictionaryStorage:
        let key = (storage.keys + bucket1.offset).move()
        let value = (storage.values + bucket1.offset).move()
        initializeBucket(bucket2, with: key, forValue: value)

      case let storage as SetStorage:
        let member = (storage.values + bucket1.offset).move()
        initializeBucket(bucket2, with: member)

      default: fatalError("The impossible happened")
    }

    initializedBuckets[bucket1] = false
    bucketMap.replaceBucket(bucket1, with: bucket2)
  }

  func replaceMemberAt(position: Index, with member: Member) {
    let bucket = bucketForPosition(position)
    guard let emptyBucket = emptyBucketFor(member) else {
      fatalError("failed to locate an empty bucket for '\(member)'")
    }
    destroyBucket(bucket)
    initializeMember(member, position: position, bucket: emptyBucket)
  }

  mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Member>(subRange: Range<Int>, with newElements: C)
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

  mutating func replaceRange<
    C:CollectionType where C.Generator.Element == (Key, Value)
    >(subRange: Range<Index>, with newElements: C)
  {
    defer { _fixLifetime(self) }

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
        let key = hashKeyInBucket(last)
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

  func destroyBucket(bucket: HashBucket) {
    initializedBuckets[bucket] = false
    switch storage {
      case let storage as SetStorage:
        (storage.values + bucket.offset).destroy()
      case let storage as DictionaryStorage:
        (storage.keys + bucket.offset).destroy()
        (storage.values + bucket.offset).destroy()
      default: fatalError("The impossible happened")
    }
  }

  mutating func destroyAt(position: Index) {
    let hole = bucketForPosition(position)
    let idealBucket = idealBucketFor(hashKeyInBucket(hole))

    destroyBucket(hole)
    bucketMap.removeBucketAt(offsetPosition(position))
    endIndex -= 1
    patchHole(hole, idealBucket: idealBucket)
  }

}