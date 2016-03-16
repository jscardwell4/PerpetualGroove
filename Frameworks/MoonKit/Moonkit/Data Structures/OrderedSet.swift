//
//  OrderedSet.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

extension SequenceType where Self.Generator.Element:Hashable {
  var hashValues: [Int] { return map {$0.hashValue} }
}

internal struct OrderedSetHashMapStorageHeader {
  var count: Int
  let capacity: Int
  let bytesAllocated: Int
  var maxLoadFactorInverse: Double

  init(count: Int = 0, capacity: Int, bytesAllocated: Int, maxLoadFactorInverse: Double = 1 / 0.75) {
    self.count = count
    self.capacity = capacity
    self.bytesAllocated = bytesAllocated
    self.maxLoadFactorInverse = maxLoadFactorInverse
  }
}

internal final class OrderedSetHashMapStorage: ManagedBuffer<OrderedSetHashMapStorageHeader, UInt8> {
  typealias Storage = OrderedSetHashMapStorage
  typealias Header = OrderedSetHashMapStorageHeader

  var capacity: Int { return value.capacity }

  var count: Int { get { return value.count } set { value.count = newValue } }

  static func bytesForBitMap(capacity: Int) -> Int {
    let numWords = BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) + alignof(UInt)
  }

  var bitMapBytes: Int { return Storage.bytesForBitMap(capacity) }

  static func bytesForValues(capacity: Int) -> Int {
    let padding = max(0, alignof(Int) - alignof(UInt))
    return strideof(Int) * capacity + padding
  }

  var valuesBytes: Int { return Storage.bytesForValues(capacity) }

  var bytesAllocated: Int { return value.bytesAllocated }

  var maxLoadFactorInverse: Double {
    get { return value.maxLoadFactorInverse }
    set { value.maxLoadFactorInverse = newValue }
  }

  var bitMap: UnsafeMutablePointer<UInt> {
    return UnsafeMutablePointer<UInt>(withUnsafeMutablePointerToElements({$0}))
  }

  var values: UnsafeMutablePointer<Int> {
    return UnsafeMutablePointer<Int>(UnsafePointer<UInt8>(bitMap) + bitMapBytes)
  }

  static func capacityForMinimumCapacity(minimumCapacity: Int) -> Int {
    var capacity = 2
    while capacity < minimumCapacity { capacity <<= 1 }
    return capacity
  }

  static func create(minimumCapacity: Int) -> Storage {
    let capacity = capacityForMinimumCapacity(minimumCapacity)
    let bitMapBytes = bytesForBitMap(capacity)
    let requiredCapacity = bitMapBytes + bytesForValues(capacity)

    let storage = super.create(requiredCapacity) {
      $0.withUnsafeMutablePointerToElements {
        BitMap(storage: UnsafeMutablePointer<UInt>($0), bitCount: capacity).initializeToZero()
        let bucketMap = UnsafeMutablePointer<Int>($0 + bitMapBytes)
        for i in 0 ..< capacity { (bucketMap + i).initialize(-1) }
      }
      return Header(capacity: capacity, bytesAllocated: $0.allocatedElementCount)
    }

    return storage as! Storage
  }

  func clone() -> Storage {

    let storage = Storage.create(capacity)

    func initialize<Memory>(target: UnsafeMutablePointer<Memory>,
                    from: UnsafeMutablePointer<Memory>,
                    count: Int)
    {
      UnsafeMutablePointer<UInt8>(target).initializeFrom(UnsafeMutablePointer<UInt8>(from), count: count)
    }

    initialize(storage.bitMap, from: bitMap, count: bitMapBytes)
    initialize(storage.values, from: values, count: valuesBytes)
    storage.count = count

    return storage
  }
  
}


internal struct OrderedSetHashMapBuffer {

  internal typealias Index = Int
  internal typealias Element = Int

  internal typealias Buffer = OrderedSetHashMapBuffer
  internal typealias Storage = OrderedSetHashMapStorage
  internal typealias Bucket = Int

  internal var storage: Storage
  internal var bitMap: BitMap
  internal var values: UnsafeMutablePointer<Int>

  internal var capacity: Int { return storage.capacity }

  internal var count: Int {
    get { return storage.count }
    nonmutating set { storage.count = newValue }
  }

  internal var maxLoadFactorInverse: Double {
    get { return storage.maxLoadFactorInverse }
    set { storage.maxLoadFactorInverse = newValue }
  }

  internal init(minimumCapacity: Int = 2) {
    self.init(storage: Storage.create(Buffer.minimumCapacityForCount(minimumCapacity, 1 / 0.75)))
  }

  internal static func minimumCapacityForCount(count: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count + 1)
  }

  internal init(storage: Storage) {
    self.storage = storage
    bitMap = BitMap(storage: storage.bitMap, bitCount: storage.capacity)
    values = storage.values
  }

  internal init<S:SequenceType where S.Generator.Element == Element>(elements: S, capacity: Int? = nil) {
    let minimumCapacity = Buffer.minimumCapacityForCount(elements.underestimateCount(), 1 / 0.75)
    let requiredCapacity = max(minimumCapacity, capacity ?? 0)
    let buffer = Buffer(minimumCapacity: requiredCapacity)

    var count = 0
    var duplicates = 0

    for value in elements {
      let (bucket, found) = buffer.find(value)
      if found {
        duplicates += 1
        continue
      } else {
        buffer.initializeValue(value, bucket: bucket)
        count += 1
      }
    }
    buffer.count = count

    self = buffer
  }

  internal var bucketMask: Int { return capacity &- 1 }

  internal func bucketForValue(value: Int) -> Bucket {
    return _squeezeHashValue(value.hashValue, 0 ..< capacity)
  }

  internal func nextBucket(bucket: Bucket) -> Bucket { return (bucket &+ 1) & bucketMask }

  internal func previousBucket(bucket: Bucket) -> Bucket { return (bucket &- 1) & bucketMask }

  internal func find(value: Int) -> (bucket: Bucket, found: Bool) {

    let startBucket = bucketForValue(value)
    var bucket = startBucket

    repeat {
      guard isInitializedBucket(bucket) else { return (bucket, false) }
      guard valueInBucket(bucket) != value  else { return (bucket, true) }
      bucket = nextBucket(bucket)
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  internal func valueInBucket(bucket: Bucket) -> Int { return values[bucket] }

  internal func isInitializedBucket(bucket: Bucket) -> Bool { return bitMap[bucket] }

  internal func destroyValueInBucket(bucket: Bucket) { bitMap[bucket] = false }

  internal func initializeValue(value: Int, bucket: Int) {
    defer { _fixLifetime(self) }
    (values + bucket).initialize(value)
    bitMap[bucket] = true
  }


  internal func setValue(value: Int, inBucket bucket: Bucket) {
    (values + bucket).initialize(value)
  }

}

extension OrderedSetHashMapBuffer : CustomStringConvertible, CustomDebugStringConvertible {

  internal var elementsDescription: String {
    if count == 0 { return "[:]" }

    var result = "["
    var first = true
    for bucket in UnsafeBufferPointer(start: values, count: count) {
      if first { first = false } else { result += ", " }
      debugPrint(values[bucket], terminator: "",   toStream: &result)
    }
    result += "]"
    return result
  }

  internal var description: String { return elementsDescription }

  internal var debugDescription: String {
    var result = elementsDescription + "\n"
    result += "count = \(count)\n"
    result += "capacity = \(capacity)\n"
    for position in 0 ..< capacity {
      let bucket = values[position]
      if bucket > -1 {
        result += "position \(position) ➞ bucket \(bucket)\n"
      } else {
        result += "position \(position), empty\n"
      }
    }
    for bucket in 0 ..< capacity {
      if isInitializedBucket(bucket) {
        let value = valueInBucket(bucket)
        result += "bucket \(bucket), ideal bucket = \(bucketForValue(value))\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }
}

internal final class OrderedSetHashMapStorageOwner: NonObjectiveCBase {

  typealias Buffer = OrderedSetHashMapBuffer

  var buffer: Buffer

  init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }

  init(buffer: Buffer) { self.buffer = buffer }

}

internal struct OrderedSetHashMapGenerator: GeneratorType {
  typealias Index = OrderedSetHashMapIndex
  typealias Buffer = OrderedSetHashMapBuffer
  var index: Index
  init(buffer: Buffer) { index = Index.startIndexForBuffer(buffer) }
  mutating func next() -> Int? {
    guard index.bucket != Index.endBucket else { return nil }
    defer { index._successorInPlace() }
    return index.buffer.valueInBucket(index.bucket)
  }
}

internal struct OrderedSetHashMapIndex: ForwardIndexType, Comparable {

  typealias Buffer = OrderedSetHashMapBuffer
  typealias Index = OrderedSetHashMapIndex

  static let endBucket = -1

  var buffer: Buffer
  var bucket: Int

  static func startIndexForBuffer(buffer: Buffer) -> Index {
    guard buffer.count > 0 else { return endIndexForBuffer(buffer) }
    for bucket in 0 ..< buffer.capacity where buffer.isInitializedBucket(bucket) {
      return Index(buffer: buffer, bucket: bucket)
    }
    return endIndexForBuffer(buffer)
  }

  static func endIndexForBuffer(buffer: Buffer) -> Index {
    return Index(buffer: buffer, bucket: endBucket)
  }

  /// Returns the next consecutive value after `self`.
  ///
  /// - Requires: The next value is representable.
  @warn_unused_result
  func successor() -> Index {
    guard bucket != Index.endBucket else { return self }
    for bucket in self.bucket ..< buffer.capacity where buffer.isInitializedBucket(bucket) {
      return Index(buffer: buffer, bucket: bucket)
    }
    return Index(buffer: buffer, bucket: Index.endBucket)
  }
}

internal func ==(lhs: OrderedSetHashMapIndex, rhs: OrderedSetHashMapIndex) -> Bool {
  guard lhs.buffer.storage === rhs.buffer.storage else { return false }
  return lhs.bucket == rhs.bucket
}

internal func <(lhs: OrderedSetHashMapIndex, rhs: OrderedSetHashMapIndex) -> Bool {
  guard lhs.buffer.storage === rhs.buffer.storage else { return false }
  return lhs.bucket < rhs.bucket
}

internal struct OrderedSetHashMap {

  typealias Index = OrderedSetHashMapIndex
  typealias Generator = OrderedSetHashMapGenerator
  typealias Element = Int
  typealias _Element = Element
  internal typealias Storage = OrderedSetHashMapStorage
  internal typealias Buffer = OrderedSetHashMapBuffer
  internal typealias Owner = OrderedSetHashMapStorageOwner

  internal var buffer: Buffer {
    get { return owner.buffer }
    set { owner.buffer = newValue }
  }

  internal var owner: Owner

  internal mutating func ensureUniqueWithCapacity(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool)
  {

    if capacity >= minimumCapacity {
      guard !isUniquelyReferenced(&owner) else { return(reallocated: false, capacityChanged: false) }
      owner = Owner(buffer: Buffer(storage: buffer.storage.clone()))
      return (reallocated: true, capacityChanged: false)
    }

    let newBuffer = Buffer(minimumCapacity: minimumCapacity * 2)
    for bucket in 0 ..< capacity where buffer.isInitializedBucket(bucket) {
      let value = buffer.values[bucket]
      let (bucket, _) = newBuffer.find(value)
      newBuffer.initializeValue(value, bucket: bucket)
    }
    newBuffer.count = buffer.count
    owner = Owner(buffer: newBuffer)
    return (reallocated: true, capacityChanged: true)

  }

  init(minimumCapacity: Int) { owner = Owner(minimumCapacity: minimumCapacity) }

  internal init(buffer: Buffer) { owner = Owner(buffer: buffer) }

  var startIndex: Index { return Index.startIndexForBuffer(buffer)  }

  var endIndex: Index { return Index.endIndexForBuffer(buffer) }

  private var _hashValue: UnsafeMutablePointer<Int> = nil

  var hashValue: Int {
    guard _hashValue == nil else { return _hashValue.memory }
    _hashValue.initialize(reduce(_mixInt(0)) { $0 ^ _mixInt($1) })
    return _hashValue.memory
  }

  @warn_unused_result
  func _customContainsEquatableElement(value: Int) -> Bool? { return contains(value) }

  @warn_unused_result
  func indexOf(value: Int) -> Index? {
    let (bucket, found) = buffer.find(value)
    guard found else { return nil }
    return Index(buffer: buffer, bucket: bucket)
  }

  @warn_unused_result
  func _customIndexOfEquatableElement(value: Element) -> Index?? {
    return Optional(indexOf(value))
  }

  subscript(index: Index) -> Int {
    get {
      precondition(index.bucket != Index.endBucket, "endIndex is not subscriptable")
      return buffer.valueInBucket(index.bucket)
    }
    set {
      precondition(index.bucket != Index.endBucket, "endIndex is not subscriptable")
      guard !contains(newValue) else { return }
      buffer.setValue(newValue, inBucket: index.bucket)
      updateCount(offset: 0)
    }
  }

  @warn_unused_result
  func contains(value: Int) -> Bool { let (_, found) = buffer.find(value); return found }

  internal mutating func updateCount(offset offset: Int) {
    guard (0 ... capacity).contains(count + offset) else { return }
    buffer.count += offset
    _hashValue = nil
  }

  internal mutating func _removeValue(value: Int, oldValue: UnsafeMutablePointer<Int?>) {
    let (bucket, found) = buffer.find(value)
    guard found else {
      if oldValue != nil { oldValue.initialize(nil) }
      return
    }
    if oldValue != nil {
      oldValue.initialize(value)
    }
    buffer.destroyValueInBucket(bucket)
    updateCount(offset: -1)
  }

  mutating func remove(value: Int) -> Int? {
    let oldValue = UnsafeMutablePointer<Int?>.alloc(1)
    _removeValue(value, oldValue: oldValue)
    return oldValue.memory
  }

  mutating func removeFirst() -> Int {
    guard let bucket = (0 ..< capacity).first({ buffer.isInitializedBucket($0) }) else {
      fatalError("removeFirst() requires the collection not be empty")
    }
    let value = buffer.valueInBucket(bucket)
    buffer.destroyValueInBucket(bucket)
    return value
  }

  mutating func insert(value: Int) {
    ensureUniqueWithCapacity(count + 1)
    let (bucket, found) = buffer.find(value)
    guard !found else { return }
    buffer.initializeValue(value, bucket: bucket)
    updateCount(offset: 1)
  }

  var count: Int { return buffer.count }
  var capacity: Int { return buffer.capacity }

  func generate() -> Generator { return Generator(buffer: buffer) }

  var isEmpty: Bool { return count == 0 }

  var first: Element? {
    guard let bucket = (0 ..< capacity).first({ buffer.isInitializedBucket($0) }) else {
      return nil
    }
    return buffer.valueInBucket(bucket)
  }

  mutating func popFirst() -> Element? {
    guard count > 0 else { return nil }; return removeFirst()
  }

}

extension OrderedSetHashMap: SetType {

  init<S : SequenceType where S.Generator.Element == Int>(_ elements: S) {
    self.init(buffer: Buffer(elements: elements)) // Uniqueness checked by `Buffer`
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set`.
  @warn_unused_result
  func isSubsetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    for value in self where !hashMap.contains(value) { return false }
    return true
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    return isSubsetOf(hashMap) && hashMap.count > count
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set`.
  @warn_unused_result
  func isSupersetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    for value in sequence where !contains(value) { return false }
    return true
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    return isSupersetOf(hashMap) && hashMap.count > count
  }

  /// Returns true if no members in the set are in a finite sequence as a `Set`.
  @warn_unused_result
  func isDisjointWith<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> Bool {
    for value in sequence where contains(value){ return false }
    return true
  }

  /// Return a new `Set` with items in both this set and a finite sequence.
  @warn_unused_result
  func union<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> OrderedSetHashMap {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  /// Insert elements of a finite sequence into this `Set`.
  mutating func unionInPlace<S:SequenceType where S.Generator.Element == Int>(sequence: S) {
    for value in sequence where !contains(value) { insert(value) }
  }

  /// Return a new set with elements in this set that do not occur in a finite sequence.
  @warn_unused_result
  func subtract<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> OrderedSetHashMap {
    var result = self
    result.subtractInPlace(sequence)
    return result
  }

  /// Remove all members in the set that occur in a finite sequence.
  mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Int>(sequence: S) {
    for value in sequence where contains(value) { _removeValue(value, oldValue: nil) }
  }

  /// Return a new set with elements common to this set and a finite sequence.
  @warn_unused_result
  func intersect<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> OrderedSetHashMap {
    var result = self
    result.intersectInPlace(sequence)
    return result
  }

  /// Remove any members of this set that aren't also in a finite sequence.
  mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Int>(sequence: S) {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    var result = OrderedSetHashMap(minimumCapacity: capacity)
    for element in self where hashMap.contains(element) { result.insert(element) }
    self = result
  }

  /// Return a new set with elements that are either in the set or a finite sequence but do not occur in both.
  @warn_unused_result
  func exclusiveOr<S:SequenceType where S.Generator.Element == Int>(sequence: S) -> OrderedSetHashMap {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  /// For each element of a finite sequence, remove it from the set if it is a common element, otherwise add it
  /// to the set. Repeated elements of the sequence will be ignored.
  mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Int>(sequence: S) {
    let hashMap = sequence as? OrderedSetHashMap ?? OrderedSetHashMap(sequence)
    var result = OrderedSetHashMap(minimumCapacity: capacity + hashMap.count)
    for element in self where !hashMap.contains(element) { result.insert(element) }
    for element in hashMap where !contains(element) { result.insert(element) }
    self = result
  }
}

extension OrderedSetHashMap: ArrayLiteralConvertible {
  init(arrayLiteral elements: Int...) {
    self.init(buffer: Buffer(elements: elements))
  }
}

extension OrderedSetHashMap: CustomStringConvertible, CustomDebugStringConvertible {

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

  var description: String { return elementsDescription }

  var debugDescription: String { return elementsDescription }
}

func ==(lhs: OrderedSetHashMap, rhs: OrderedSetHashMap) -> Bool {

  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }

  return lhs.hashValue == rhs.hashValue
}

public struct OrderedSet<Element:Hashable>: CollectionType {

  internal typealias Base = ContiguousArray<Element>

  internal var _base: Base
  internal var _hashValues: Set<Int>

  public var count: Int { return _base.count }

  public init(minimumCapacity: Int) {
    _base = Base(minimumCapacity: minimumCapacity)
    _hashValues = Set<Int>(minimumCapacity: minimumCapacity)
  }

  /**
   init:

   - parameter collection: C
   */
  public init<C:CollectionType where C.Generator.Element == Element>(_ collection: C) {
    self.init(minimumCapacity: numericCast(collection.count))
    for element in collection {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.append(element)
      _hashValues.insert(hashValue)
    }
  }

  /**
   init:

   - parameter sequence: S
   */
  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    self.init(minimumCapacity: numericCast(sequence.underestimateCount()))
    for element in sequence {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.append(element)
      _hashValues.insert(hashValue)
    }
  }
  
}

extension OrderedSet: MutableIndexable {
  public typealias Index = Base.Index
  public var startIndex: Index { return _base.startIndex }
  public var endIndex: Index { return _base.endIndex }

  public subscript(index: Index) -> Element {
    get { return _base[index] }
    set {
      let hashValue = newValue.hashValue
      guard _hashValues ∌ hashValue else { return }
      _hashValues.remove(_base[index].hashValue)
      _hashValues.insert(hashValue)
      _base[index] = newValue
    }
  }

}

extension OrderedSet: MutableCollectionType {

  public subscript(bounds: Range<Int>) -> SubSequence {
    get { return SubSequence(_base[bounds]) }
    set { _base[bounds] = newValue._base }
  }

}

extension OrderedSet: RangeReplaceableCollectionType {

  public init() { _base = []; _hashValues = [] }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    var elements = Array<Element>(minimumCapacity: numericCast(newElements.count))
    for element in newElements where elements ∌ element { elements.append(element) }
    _hashValues.subtractInPlace(_base[subRange].hashValues)
    _base.replaceRange(subRange, with: elements)
    _hashValues.unionInPlace(elements.hashValues)
  }

  public mutating func append(element: Element) {
    let hashValue = element.hashValue
    guard _hashValues ∌ hashValue else { return }
    _hashValues.insert(hashValue)

    _base.append(element)
  }

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  public mutating func appendContentsOf<S : SequenceType
    where S.Generator.Element == Element>(newElements: S)
  {
    var elements: [Element] = []
    elements.reserveCapacity(newElements.underestimateCount())
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      elements.append(element)
    }
    _base.appendContentsOf(elements)
  }

  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAtIndex(i: Int) -> Element {
    let result = _base.removeAtIndex(i)
    _hashValues.remove(result.hashValue)
    return result
  }

  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  public mutating func removeFirst() -> Element {
    let result = _base.removeFirst()
    assert(_hashValues ∌ result.hashValue)
    return result
  }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `self.count >= n`.
  public mutating func removeFirst(n: Int) {
    precondition(_base.count >= n, "Cannot remove more items than are actually contained")
    _hashValues.subtractInPlace(_base[..<n].hashValues)
    _base.removeFirst(n)
  }


  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeRange(subRange: Range<Int>) {
    _hashValues.subtractInPlace(_base[subRange].hashValues)
    _base.removeRange(subRange)
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
  public mutating func removeAll(keepCapacity: Bool = false) {
    _base.removeAll(keepCapacity: keepCapacity)
    _hashValues.removeAll(keepCapacity: keepCapacity)
  }

  /// Reserve enough space to store minimumCapacity elements.
  ///
  /// - Postcondition: `capacity >= minimumCapacity` and the array has
  ///   mutable contiguous storage.
  ///
  /// - Complexity: O(`count`).
  public mutating func reserveCapacity(minimumCapacity: Int) {
    _base.reserveCapacity(minimumCapacity)
    var hashValuesCopy = Set<Int>(minimumCapacity: minimumCapacity)
    hashValuesCopy.unionInPlace(_hashValues)
    _hashValues = hashValuesCopy
  }

  /// Insert `newElement` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  ///
  /// - Requires: `atIndex <= count`.
  public mutating func insert(newElement: Element, atIndex i: Int) {
    let hashValue = newElement.hashValue
    guard _hashValues ∌ hashValue else { return }
    _hashValues.insert(hashValue)
    _base.insert(newElement, atIndex: i)
  }

  /// Insert `newElements` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count + newElements.count`).
  public mutating func insertContentsOf<S:CollectionType
    where S.Generator.Element == Element>(newElements: S, at i: Int)
  {
    var elements: [Element] = []
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      elements.append(element)
    }
    _base.insertContentsOf(elements, at: i)
  }

}


extension OrderedSet: SequenceType {
  public typealias Generator = AnyGenerator<Element>
  public typealias SubSequence = OrderedSetSlice<Element>

  public func generate() -> Generator { return AnyGenerator(_base.generate()) }
  public func dropFirst(n: Int) -> SubSequence { return OrderedSetSlice(_base.dropFirst(n)) }
  public func dropLast(n: Int) -> SubSequence { return OrderedSetSlice(_base.dropLast(n)) }
  public func prefix(maxLength: Int) -> SubSequence { return OrderedSetSlice(_base.prefix(maxLength)) }
  public func suffix(maxLength: Int) -> SubSequence { return OrderedSetSlice(_base.suffix(maxLength)) }
  public func split(maxSplit: Int,
              allowEmptySlices: Bool,
              @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    return try _base.split(maxSplit, allowEmptySlices: allowEmptySlices, isSeparator: isSeparator).map {
      OrderedSetSlice($0)
    }
  }
}

extension OrderedSet: _ArrayType {

  public typealias _Buffer = _ContiguousArrayBuffer<Element>

  /// The number of elements the Array can store without reallocation.
  public var capacity: Int { return _base.capacity }

  /// An object that guarantees the lifetime of this array's elements.
  public var _owner: AnyObject? { return _base._owner }

  /// If the elements are stored contiguously, a pointer to the first
  /// element. Otherwise, `nil`.
  public var _baseAddressIfContiguous: UnsafeMutablePointer<Element> {
    return _base._baseAddressIfContiguous
  }

  public internal(set) var _buffer: _Buffer {
    get { return _base._buffer }
    set { _base._buffer = newValue }
  }

  public init(count: Int, repeatedValue: Element) {
    _base = [repeatedValue]
    _hashValues = [repeatedValue.hashValue]
  }

  public init(_ buffer: _Buffer) {
    self.init()
    let base = Base(buffer)
    for element in base {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      _base.append(element)
    }
  }

}


/// Operator form of `appendContentsOf`.
public func +=<Element, S: SequenceType
  where S.Generator.Element == Element>(inout lhs: OrderedSet<Element>, rhs: S)
{
  lhs ∪= rhs
}

extension OrderedSet: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension OrderedSet: CustomStringConvertible {
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

extension OrderedSet: SetType {

  public mutating func insert(member: Element) { append(member) }

  public mutating func remove(member: Element) -> Element? {
    guard _hashValues.remove(member.hashValue) != nil, let idx = _base.indexOf(member) else { return nil }
    return _base.removeAtIndex(idx)
  }

  public func contains(element: Element) -> Bool { return _hashValues ∋ element.hashValue }

  public func isSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isSubsetOf(sequence.hashValues)
  }

  public func isStrictSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isStrictSubsetOf(sequence.hashValues)
  }

  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return _hashValues.isSupersetOf(sequence.hashValues)
  }

  public func isStrictSupersetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isStrictSupersetOf(sequence.hashValues)
  }

  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return _hashValues.isDisjointWith(sequence.hashValues)
  }

  public func union<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence where _hashValues ∌ element.hashValue {
      append(element)
    }
  }

  public func subtract<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.subtractInPlace(sequence)
    return result
  }

  public mutating func subtractInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    for element in sequence where _hashValues ∋ element.hashValue {
      remove(element)
    }
  }

  public func intersect<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.intersectInPlace(sequence)
    return result
  }

  public mutating func intersectInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let elements = sequence as? Set<Element> ?? Set(sequence)
    for element in _base where elements ∌ element { remove(element) }
  }

  public func exclusiveOr<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  public mutating func exclusiveOrInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let set = sequence as? Set<Element> ?? Set(sequence)
    var result = OrderedSet<Element>(minimumCapacity: capacity + set.count)
    for element in self where !set.contains(element) { result.insert(element) }
    for element in set where !contains(element) { result.insert(element) }
    self = result
  }

}

public struct OrderedSetSlice<Element:Hashable>: CollectionType {
  public typealias Base = ArraySlice<Element>
  internal var _base: Base
  internal var _hashValues: Set<Int>
  internal init(_ base: Base) { _base = base; _hashValues = Set(_base.hashValues) }
}

extension OrderedSetSlice: CustomStringConvertible {
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

  public init<C:CollectionType where C.Generator.Element == Element>(_ collection: C) {
    self.init(minimumCapacity: numericCast(collection.count))
    for element in collection {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.append(element)
      _hashValues.insert(hashValue)
    }
  }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    self.init(minimumCapacity: numericCast(sequence.underestimateCount()))
    for element in sequence {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.append(element)
      _hashValues.insert(hashValue)
    }
  }

}

extension OrderedSetSlice: MutableIndexable {
  public typealias Index = Base.Index
  public var startIndex: Index { return _base.startIndex }
  public var endIndex: Index { return _base.endIndex }

  public subscript(index: Index) -> Element {
    get { return _base[index] }
    set {
      let hashValue = newValue.hashValue
      guard _hashValues ∌ hashValue else { return }
      _hashValues.remove(_base[index].hashValue)
      _hashValues.insert(hashValue)
      _base[index] = newValue
    }
  }

}

extension OrderedSetSlice: MutableCollectionType {

  public subscript(bounds: Range<Int>) -> SubSequence {
    get { return SubSequence(_base[bounds]) }
    set { _base[bounds] = newValue._base }
  }

}

extension OrderedSetSlice: RangeReplaceableCollectionType {

  public init() { _base = []; _hashValues = [] }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    var elements = Array<Element>(minimumCapacity: numericCast(newElements.count))
    for element in newElements where elements ∌ element { elements.append(element) }
    _hashValues.subtractInPlace(_base[subRange].hashValues)
    _base.replaceRange(subRange, with: elements)
    _hashValues.unionInPlace(elements.hashValues)
  }

  public mutating func append(element: Element) {
    let hashValue = element.hashValue
    guard _hashValues ∌ hashValue else { return }
    _hashValues.insert(hashValue)

    _base.append(element)
  }

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  public mutating func appendContentsOf<S : SequenceType
    where S.Generator.Element == Element>(newElements: S)
  {
    var elements: [Element] = []
    elements.reserveCapacity(newElements.underestimateCount())
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      elements.append(element)
    }
    _base.appendContentsOf(elements)
  }

  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAtIndex(i: Int) -> Element {
    let result = _base.removeAtIndex(i)
    _hashValues.remove(result.hashValue)
    return result
  }

  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  public mutating func removeFirst() -> Element {
    let result = _base.removeFirst()
    assert(_hashValues ∌ result.hashValue)
    return result
  }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `self.count >= n`.
  public mutating func removeFirst(n: Int) {
    _hashValues.subtractInPlace(_base[..<n].hashValues)
    _base.removeFirst(n)
  }


  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeRange(subRange: Range<Int>) {
    _hashValues.subtractInPlace(_base[subRange].hashValues)
    _base.removeRange(subRange)
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
  public mutating func removeAll(keepCapacity: Bool = false) {
    _base.removeAll(keepCapacity: keepCapacity)
    _hashValues.removeAll(keepCapacity: keepCapacity)
  }

  /// Reserve enough space to store minimumCapacity elements.
  ///
  /// - Postcondition: `capacity >= minimumCapacity` and the array has
  ///   mutable contiguous storage.
  ///
  /// - Complexity: O(`count`).
  public mutating func reserveCapacity(minimumCapacity: Int) {
    _base.reserveCapacity(minimumCapacity)
    var hashValuesCopy = Set<Int>(minimumCapacity: minimumCapacity)
    hashValuesCopy.unionInPlace(_hashValues)
    _hashValues = hashValuesCopy
  }

  /// Insert `newElement` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  ///
  /// - Requires: `atIndex <= count`.
  public mutating func insert(newElement: Element, atIndex i: Int) {
    let hashValue = newElement.hashValue
    guard _hashValues ∌ hashValue else { return }
    _hashValues.insert(hashValue)
    _base.insert(newElement, atIndex: i)
  }

  /// Insert `newElements` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count + newElements.count`).
  public mutating func insertContentsOf<S:CollectionType
    where S.Generator.Element == Element>(newElements: S, at i: Int)
  {
    var elements: [Element] = []
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      elements.append(element)
    }
    _base.insertContentsOf(elements, at: i)
  }

}


extension OrderedSetSlice: SequenceType {
  public typealias Generator = AnyGenerator<Element>
  public typealias SubSequence = OrderedSetSlice<Element>

  public func generate() -> Generator { return AnyGenerator(_base.generate()) }
  public func dropFirst(n: Int) -> SubSequence { return OrderedSetSlice(_base.dropFirst(n)) }
  public func dropLast(n: Int) -> SubSequence { return OrderedSetSlice(_base.dropLast(n)) }
  public func prefix(maxLength: Int) -> SubSequence { return OrderedSetSlice(_base.prefix(maxLength)) }
  public func suffix(maxLength: Int) -> SubSequence { return OrderedSetSlice(_base.suffix(maxLength)) }
  public func split(maxSplit: Int,
                    allowEmptySlices: Bool,
                    @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    return try _base.split(maxSplit, allowEmptySlices: allowEmptySlices, isSeparator: isSeparator).map {
      SubSequence($0)
    }
  }
}

extension OrderedSetSlice: _ArrayType {

  public typealias _Buffer = ArraySlice<Element>._Buffer

  /// The number of elements the Array can store without reallocation.
  public var capacity: Int { return _base.capacity }

  /// An object that guarantees the lifetime of this array's elements.
  public var _owner: AnyObject? { return _base._owner }

  /// If the elements are stored contiguously, a pointer to the first
  /// element. Otherwise, `nil`.
  public var _baseAddressIfContiguous: UnsafeMutablePointer<Element> {
    return _base._baseAddressIfContiguous
  }

  public internal(set) var _buffer: _Buffer {
    get { return _base._buffer }
    set { _base._buffer = newValue }
  }

  public init(count: Int, repeatedValue: Element) {
    _base = [repeatedValue]
    _hashValues = [repeatedValue.hashValue]
  }

  public init(_ buffer: _Buffer) {
    self.init()
    let base = Base(buffer)
    for element in base {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _hashValues.insert(hashValue)
      _base.append(element)
    }
  }

}


/// Operator form of `appendContentsOf`.
public func +=<Element, S: SequenceType
  where S.Generator.Element == Element>(inout lhs: OrderedSetSlice<Element>, rhs: S)
{
  lhs ∪= rhs
}

extension OrderedSetSlice: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension OrderedSetSlice: SetType {

  public mutating func insert(member: Element) { append(member) }

  public mutating func remove(member: Element) -> Element? {
    guard _hashValues.remove(member.hashValue) != nil, let idx = _base.indexOf(member) else { return nil }
    return _base.removeAtIndex(idx)
  }

  public func contains(element: Element) -> Bool { return _hashValues ∋ element.hashValue }

  public func isSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isSubsetOf(sequence.hashValues)
  }

  public func isStrictSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isStrictSubsetOf(sequence.hashValues)
  }

  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return _hashValues.isSupersetOf(sequence.hashValues)
  }

  public func isStrictSupersetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return _hashValues.isStrictSupersetOf(sequence.hashValues)
  }

  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return _hashValues.isDisjointWith(sequence.hashValues)
  }

  public func union<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSetSlice<Element>
  {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence where _hashValues ∌ element.hashValue {
      append(element)
    }
  }

  public func subtract<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSetSlice<Element>
  {
    var result = self
    result.subtractInPlace(sequence)
    return result
  }

  public mutating func subtractInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    for element in sequence where _hashValues ∋ element.hashValue {
      remove(element)
    }
  }

  public func intersect<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSetSlice<Element>
  {
    var result = self
    result.intersectInPlace(sequence)
    return result
  }

  public mutating func intersectInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let elements = sequence as? Set<Element> ?? Set(sequence)
    for element in _base where elements ∌ element { remove(element) }
  }

  public func exclusiveOr<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSetSlice<Element>
  {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  public mutating func exclusiveOrInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let set = sequence as? Set<Element> ?? Set(sequence)
    var result = OrderedSetSlice<Element>(minimumCapacity: capacity + set.count)
    for element in self where !set.contains(element) { result.insert(element) }
    for element in set where !contains(element) { result.insert(element) }
    self = result
  }
  
}
