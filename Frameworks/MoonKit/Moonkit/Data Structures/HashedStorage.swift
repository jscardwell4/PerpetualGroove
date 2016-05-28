//
//  HashedStorageBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

// MARK: - Supporting functions

/// Returns a copy of the `buffer` with room for `minimumCapacity` elements and offset by `buffer.startIndex`
private func cloneBuffer<
  S:ConcreteHashedStorage
  >(buffer: HashedStorageBuffer<S>, minimumCapacity: Int? = nil) -> HashedStorageBuffer<S>
{
  var clone = HashedStorageBuffer<S>(minimumCapacity: minimumCapacity ?? buffer.capacity, offsetBy: buffer.startIndex)
  clone.appendContentsOf(buffer)
  return clone
}


// MARK: - OrderedSet

/// A hash-based mapping from `Key` to `Element` instances that preserves elment order.
public struct OrderedSet<Member:Hashable>: CollectionType {

  private typealias Buffer = HashedStorageBuffer<Storage>
  private typealias Storage = OrderedSetStorage<Element>

  public typealias Index = Int
  public typealias Element = Member
  public typealias _Element = Element
  public typealias SubSequence = OrderedSet<Element>

  private var buffer: Buffer

  /// Checks that `owner` has only the one strong reference
  private mutating func ensureUnique() -> (reallocated: Bool, capacityChanged: Bool) {
    guard !buffer.isUniquelyReferenced() else { return (false, false) }
    buffer = cloneBuffer(buffer)
    return (true, false)
  }

  /// Checks that `owner` has only the one strong reference and that it's `buffer` has at least `minimumCapacity` capacity
  private mutating func ensureUniqueWithCapacity(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool)
  {
    switch (isUnique: buffer.isUniquelyReferenced(), hasCapacity: capacity >= minimumCapacity) {

      case (isUnique: true, hasCapacity: true):
        return (reallocated: false, capacityChanged: false)

      case (isUnique: true, hasCapacity: false):
        buffer = cloneBuffer(buffer, minimumCapacity: Buffer.minimumCapacityForCount(minimumCapacity))
        return (reallocated: true, capacityChanged: true)

      case (isUnique: false, hasCapacity: true):
        buffer = cloneBuffer(buffer)
        return (reallocated: true, capacityChanged: false)

      case (isUnique: false, hasCapacity: false):
        buffer = cloneBuffer(buffer, minimumCapacity: Buffer.minimumCapacityForCount(minimumCapacity))
        return (reallocated: true, capacityChanged: true)
    }

  }

  /// The current number of elements
  public var count: Int { return buffer.count }

  /// The number of elements this collection can hold without reallocating
  public var capacity: Int { return buffer.capacity }


  public init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }

  private init(buffer: Buffer) { self.buffer = buffer }

  /// - note: Copied source from stdlib `Set`
  public var hashValue: Int {
    var result: Int = _mixInt(0)
    for element in self { result ^= _mixInt(element.hashValue) }
    return result
  }

  @warn_unused_result
  public func _customContainsEquatableElement(element: Element) -> Bool? { return buffer.containsKey(element) }

  @warn_unused_result
  public func _customIndexOfEquatableElement(element: Element) -> Index?? {
    return Optional(indexOf(element))
  }
  

  public func indexOf(element: Element) -> Index? { return buffer.indexOf(element) }

  @warn_unused_result
  public func contains(element: Element) -> Bool { return buffer.containsKey(element) }

}

// MARK: MutableIndexable
extension OrderedSet: MutableIndexable {

  public var startIndex: Index { return buffer.startIndex }

  public var endIndex: Index { return buffer.endIndex }

  public subscript(index: Index) -> Element {
    get { return buffer[index] }
    set {
      ensureUnique()
      buffer[index] = newValue
    }
  }

}

// MARK: SetType
extension OrderedSet: SetType {

  /// Inserts `element` into the collection.
  public mutating func insert(element: Element) { append(element)  }

  /// Removes and returns `element` from the collection, returns `nil` if `element` was not contained.
  public mutating func remove(element: Element) -> Element? {
    guard let index = buffer.indexOf(element) else { return nil }
    let result = buffer[index]
    ensureUnique()
    buffer.destroyAt(index)
    return result
  }

  /// Initialize with the unique members of `elements`.
  public init<S:SequenceType where S.Generator.Element == Element>(_ elements: S) {
    self.init(buffer: Buffer(elements: elements)) // Uniqueness checked by `Buffer`
  }

  /// Returns true if the set is a subset of a finite sequence as a set.
  @warn_unused_result
  public func isSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var hitCount = 0
    for element in sequence where contains(element) {
      hitCount += 1
      guard hitCount < count else { return true }
    }
    return hitCount == count
  }
  /// Returns true if the set is a subset of a finite sequence as a set but not equal.
  @warn_unused_result
  public func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var hitCount = 0, totalCount = 0
    for element in sequence {
      if contains(element) { hitCount += 1 }
      totalCount += 1
      guard hitCount < count || totalCount <= count else { return true }
    }
    return hitCount == count && totalCount > count
  }

  /// Returns true if the set is a superset of a finite sequence as a set.
  @warn_unused_result
  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    for element in sequence { guard contains(element) else { return false } }
    return true
  }

  /// Returns true if the set is a superset of a finite sequence as a set but not equal.
  @warn_unused_result
  public func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var totalCount = 0
    for element in sequence {
      totalCount += 1
      guard contains(element) else { return false }
    }
    return totalCount < count
  }

  /// Returns true if no members in the set are in a finite sequence as a set.
  @warn_unused_result
  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    for element in sequence { guard !contains(element) else { return false } }
    return true
  }

  /// Return a new `Set` with items in both this set and a finite sequence.
  @warn_unused_result
  public func union<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  /// Insert elements of a finite sequence into this set.
  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    appendContentsOf(sequence)
  }

  /// Insert elements of a finite collection into this set.
  public mutating func unionInPlace<C:CollectionType where C.Generator.Element == Element>(sequence: C) {
    appendContentsOf(sequence)
  }

  /// Return a new set with elements in this set that do not occur in a finite sequence.
  @warn_unused_result
  public func subtract<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self
    result.subtractInPlace(sequence)
    return result
  }

  /// Remove all members in the set that occur in a finite sequence.
  public mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    ensureUnique()
    buffer.removeContentsOf(sequence)
  }

  /// Return a new set with elements common to this set and a finite sequence.
  @warn_unused_result
  public func intersect<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self
    result.intersectInPlace(sequence)
    return result
  }

  /// Remove any members of this set that aren't also in `set`.
  public mutating func intersectInPlace<S:SetType where S.Generator.Element == Element>(set: S) {
    var ranges = RangeMap<Int>()
    if count < numericCast(set.count) {
      for index in indices where !set.contains(self[index]) { ranges.insert(index) }
    } else {
      for index in set.flatMap({indexOf($0)}) { ranges.insert(index) }
      ranges.invertInPlace(coverage: indices)
    }
    var removedCount = 0
    for range in ranges {
      let adjustedRange = range - removedCount
      buffer.removeRange(adjustedRange)
      removedCount = removedCount &+ adjustedRange.count
    }
  }

  /// Remove any members of this set that aren't also in a finite sequence.
  public mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    switch sequence {
      case let other as OrderedSet<Element>:
        intersectInPlace(other)
      case let other as Set<Element>:
        intersectInPlace(other)
      default:
        let other = Set(sequence)
        intersectInPlace(other)
    }
  }

  /// Return a new set with elements that are either in the set or a finite sequence but do not occur in both.
  @warn_unused_result
  public func exclusiveOr<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  /// Modify collection to contain elements that are either in this set or `set` but do not occur in both.
  public mutating func exclusiveOrInPlace(set: Set<Element>)
  {
    var ranges = RangeMap<Int>()
    var otherRanges = RangeMap<Set<Element>.Index>()
    for otherIndex in set.indices {
      guard let index = indexOf(set[otherIndex]) else { continue }
      ranges.insert(index)
      otherRanges.insert(otherIndex)
    }
    otherRanges.invertInPlace(coverage: set.indices)
    let removeCount = ranges.indexCount
    let addCount = otherRanges.indexCount

    guard removeCount > 0 || addCount > 0 else { return }

    ensureUniqueWithCapacity(count + addCount - removeCount)

    var removedCount = 0
    for range in ranges {
      let adjustedRange = range - removedCount
      buffer.removeRange(adjustedRange)
      removedCount = removedCount &+ adjustedRange.count
    }

    for range in otherRanges { buffer.appendContentsOf(set[range]) }
  }

  /// Modify collection to contain elements that are either in this set or `set` but do not occur in both.
  public mutating func exclusiveOrInPlace(orderedSet: OrderedSet<Element>)
  {
    var ranges = RangeMap<Int>()
    var otherRanges = RangeMap<Int>()
    for otherIndex in orderedSet.indices {
      guard let index = indexOf(orderedSet[otherIndex]) else { continue }
      ranges.insert(index)
      otherRanges.insert(otherIndex)
    }
    otherRanges.invertInPlace(coverage: orderedSet.indices)
    let removeCount = ranges.indexCount
    let addCount = otherRanges.indexCount

    guard removeCount > 0 || addCount > 0 else { return }

    ensureUniqueWithCapacity(count + addCount - removeCount)

    var removedCount = 0
    for range in ranges {
      let adjustedRange = range - removedCount
      buffer.removeRange(adjustedRange)
      removedCount = removedCount &+ adjustedRange.count
    }

    for range in otherRanges { buffer.appendContentsOf(orderedSet[range]) }
  }

  /// For each element of a finite sequence, remove it from the set if it is a common element, otherwise add it
  /// to the set. Repeated elements of the sequence will be ignored.
  public mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    switch sequence {
      case let other as OrderedSet<Element>:
        exclusiveOrInPlace(other)
      case let other as Set<Element>:
        exclusiveOrInPlace(other)
      default:
        let other = OrderedSet(sequence)
        exclusiveOrInPlace(other)
    }
  }
}

// MARK: MutableCollectionType
extension OrderedSet: MutableCollectionType {
  public subscript(subRange: Range<Int>) -> SubSequence {
    get { return SubSequence(buffer: buffer[subRange]) }
    set { replaceRange(subRange, with: newValue) }
  }
}

// MARK: RangeReplaceableCollectionType
extension OrderedSet: RangeReplaceableCollectionType {

  /// Create an empty instance.
  public init() { buffer = Buffer(minimumCapacity: 0, offsetBy: 0) }

  /// A non-binding request to ensure `n` elements of available storage.
  ///
  /// This works as an optimization to avoid multiple reallocations of
  /// linear data structures like `Array`.  Conforming types may
  /// reserve more than `n`, exactly `n`, less than `n` elements of
  /// storage, or even ignore the request completely.
  public mutating func reserveCapacity(minimumCapacity: Int) { ensureUniqueWithCapacity(minimumCapacity) }

  /// Replace the given `subRange` of elements with `newElements`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`subRange.count`) if
  ///   `subRange.endIndex == self.endIndex` and `newElements.isEmpty`,
  ///   O(`self.count` + `newElements.count`) otherwise.
  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {

    let requiredCapacity = count - subRange.count + numericCast(newElements.count)
    ensureUniqueWithCapacity(requiredCapacity)

    // Replace with uniqued collection
    buffer.replaceRange(subRange, with: newElements)
  }

  /// Append `x` to `self`.
  ///
  /// Applying `successor()` to the index of the new element yields
  /// `self.endIndex`.
  ///
  /// - Complexity: Amortized O(1).
  public mutating func append(x: Element) {
    ensureUniqueWithCapacity(Buffer.minimumCapacityForCount(count &+ 1))
    buffer.append(x)
  }

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  public mutating func appendContentsOf<S:SequenceType where S.Generator.Element == Element>(newElements: S) {
    ensureUnique()
    for element in newElements { append(element) }
  }

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  public mutating func appendContentsOf<C:CollectionType where C.Generator.Element == Element>(newElements: C) {
    ensureUniqueWithCapacity(Buffer.minimumCapacityForCount(count + numericCast(newElements.count)))
    buffer.appendContentsOf(newElements)
  }

  /// Insert `newElement` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func insert(newElement: Element, atIndex i: Index) {
    ensureUniqueWithCapacity(count + 1)
    buffer.insert(newElement, atIndex: i)
  }

  /// Insert `newElements` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count + newElements.count`).
  public mutating func insertContentsOf<
    C:CollectionType where C.Generator.Element == Element
    >(newElements: C, at i: Index)
  {
    ensureUniqueWithCapacity(count + numericCast(newElements.count))
    buffer.insertContentsOf(newElements, at: i)
  }

  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAtIndex(i: Index) -> Element {
    let result = buffer[i]
    ensureUnique()
    buffer.destroyAt(i)
    return result
  }

  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  public mutating func removeFirst() -> Element { return removeAtIndex(startIndex) }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `n >= 0 && self.count >= n`.
  public mutating func removeFirst(n: Int) { ensureUnique(); buffer.removeFirst(n) }

  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeRange(subRange: Range<Index>) {
    ensureUnique()
    buffer.removeRange(subRange)
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
  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    guard count > 0 else { return }
    buffer.removeAll(keepCapacity: keepCapacity)
  }

}

// MARK: ArrayLiteralConvertible
extension OrderedSet: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(buffer: Buffer(elements: elements))
  }
}

// MARK: CustomStringConvertible, CustomDebugStringConvertible
extension OrderedSet: CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    guard count > 0 else { return "[]" }

    var result = "["
    var first = true
    for element in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(element, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  public var description: String { return elementsDescription }

  public var debugDescription: String { return elementsDescription }
}

// MARK: Equatable
extension OrderedSet: Equatable {}

public func == <Element:Hashable>
  (lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  
  guard !(lhs.buffer.identity == rhs.buffer.identity && lhs.count == rhs.count) else { return true }

  for (v1, v2) in zip(lhs, rhs) { guard v1 == v2 else { return false } }
  
  return true
}

// MARK: - OrderedDictionary
/// A hash-based mapping from `Key` to `Value` instances that preserves elment order.
public struct OrderedDictionary<Key: Hashable, Value>: _DestructorSafeContainer {

  private typealias Storage = OrderedDictionaryStorage<Key, Value>
  private typealias Buffer = HashedStorageBuffer<Storage>

  public typealias Index = Int
  public typealias Element = (Key, Value)
  public typealias _Element = Element
  public typealias SubSequence = OrderedDictionary<Key, Value>

  private var buffer: Buffer

  /// Checks that `owner` has only the one strong reference
  private mutating func ensureUnique() -> (reallocated: Bool, capacityChanged: Bool) {
    guard !buffer.isUniquelyReferenced() else { return (false, false) }
    buffer = cloneBuffer(buffer)
    return (true, false)
  }

  /// Checks that `owner` has only the one strong reference and that it's `buffer` has at least `minimumCapacity` capacity
  private mutating func ensureUniqueWithCapacity(minimumCapacity: Int) -> (reallocated: Bool, capacityChanged: Bool) {
    switch (isUnique: buffer.isUniquelyReferenced(), hasCapacity: capacity >= minimumCapacity) {

      case (isUnique: true, hasCapacity: true):
        return (reallocated: false, capacityChanged: false)

      case (isUnique: true, hasCapacity: false):
        buffer = cloneBuffer(buffer, minimumCapacity: Buffer.minimumCapacityForCount(minimumCapacity))
        return (reallocated: true, capacityChanged: true)

      case (isUnique: false, hasCapacity: true):
        buffer = cloneBuffer(buffer)
        return (reallocated: true, capacityChanged: false)

      case (isUnique: false, hasCapacity: false):
        buffer = cloneBuffer(buffer, minimumCapacity: Buffer.minimumCapacityForCount(minimumCapacity))
        return (reallocated: true, capacityChanged: true)
    }

  }

  public init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }

  private init(buffer: Buffer) { self.buffer = buffer }

  private mutating func _remove(index: Index) {
    ensureUniqueWithCapacity(capacity)
    buffer.destroyAt(index)
  }

  private mutating func _removeAndReturn(index: Index) -> Element {
    let result = buffer[index]
    _remove(index)
    return result
  }

  private mutating func _removeValueForKey(key: Key) {
    guard let index = buffer.indexForKey(key) else { return }
    _remove(index)
  }

  private mutating func _removeAndReturnValueForKey(key: Key) -> Value? {
    guard let index = buffer.indexForKey(key) else { return nil }
    return _removeAndReturn(index).1
  }

  private mutating func _updateValue(value: Value, forKey key: Key) {
    let found = buffer.containsKey(key)

    let minCapacity = found
      ? capacity
      : Buffer.minimumCapacityForCount(buffer.count + 1)

    ensureUniqueWithCapacity(minCapacity)

    if found { buffer.updateElement((key, value)) }
    else { buffer.append((key, value)) }
  }

  private mutating func _updateAndReturnValue(value: Value, forKey key: Key) -> Element? {
    let found = buffer.containsKey(key)

    let minCapacity = found
      ? capacity
      : Buffer.minimumCapacityForCount(buffer.count + 1)

    ensureUniqueWithCapacity(minCapacity)

    if found { return buffer.updateElement((key, value)) }
    else { buffer.append((key, value)); return nil }
  }

  public mutating func insertValue(value: Value, forKey key: Key, atIndex index: Index) {
    replaceRange(index ..< index, with: CollectionOfOne((key, value)))
  }

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public init<S:SequenceType where S.Generator.Element == Element>(_ elements: S) {
    var keys: Set<Int> = []
    var filteredElements: [Element] = []
    for element in elements where !keys.contains(element.0.hashValue) {
      keys.insert(element.0.hashValue)
      filteredElements.append(element)
    }
    let buffer = Buffer(elements: filteredElements)
    self.init(buffer: buffer)
  }

}

// MARK: OrderedDictionary where Value:Equatable
extension OrderedDictionary where Value:Equatable {

  public func _customContainsEquatableElement(element: Element) -> Bool? {
    guard let value = self[element.0] else { return false }
    return element.1 == value
  }

  public func _customIndexOfEquatableElement(element: Element) -> Index?? {
    guard self[element.0] == element.1 else { return Optional(nil) }
    return Optional(buffer.indexForKey(element.0))
  }
}

// MARK: DictionaryLiteralConvertible
extension OrderedDictionary: DictionaryLiteralConvertible {

  public init(dictionaryLiteral elements: Element...) {
    self.init(elements)
  }

}

// MARK: MutableKeyValueCollection
extension OrderedDictionary: MutableKeyValueCollection {

  public mutating func insertValue(value: Value, forKey key: Key) {
    _updateValue(value, forKey: key)
  }

  public mutating func updateValue(value: Value, forKey key: Key) -> Value? {
    return _updateAndReturnValue(value, forKey: key)?.1
  }

  /// Removes the value associated with `key` and returns it. Returns `nil` if `key` is not present.
  public mutating func removeValueForKey(key: Key) -> Value? {
    return _removeAndReturnValueForKey(key)
  }

  /// Returns the index of `key` or `nil` if `key` is not present.
  public func indexForKey(key: Key) -> Index? { return buffer.indexForKey(key) }

  /// Returns the value associated with `key` or `nil` if `key` is not present.
  public func valueForKey(key: Key) -> Value? {
    guard let position = buffer.indexForKey(key) else { return nil }
    return buffer.valueForPosition(position)
  }

  /// Access the value associated with the given key.
  /// Reading a key that is not present in self yields nil. Writing nil as the value for a given key erases that key from self.
  /// - attention: Is there a conflict when `Key` = `Index` or do the differing return types resolve ambiguity?
  public subscript(key: Key) -> Value? {
    get { return valueForKey(key) }
    set {
      if let value = newValue { _updateValue(value, forKey: key) }
      else { _removeValueForKey(key) }
    }
  }


}

// MARK: MutableCollectionType
extension OrderedDictionary: MutableCollectionType {

  public var startIndex: Int { return buffer.startIndex }
  public var endIndex: Int  { return buffer.endIndex }

  public subscript(index: Index) -> Element {
    get { return buffer[index] }
    set {
      ensureUniqueWithCapacity(count)
      buffer[index] = newValue
    }
  }
  
  public subscript(subRange: Range<Int>) -> SubSequence {
    get {
      return SubSequence(buffer: buffer[subRange])
    }
    set {
      replaceRange(subRange, with: newValue)
    }
  }
  
}

// MARK: RangeReplaceableCollectionType
extension OrderedDictionary: RangeReplaceableCollectionType {

  /// Create an empty instance.
  public init() { buffer = Buffer(minimumCapacity: 0, offsetBy: 0) }

  /// A non-binding request to ensure `n` elements of available storage.
  ///
  /// This works as an optimization to avoid multiple reallocations of
  /// linear data structures like `Array`.  Conforming types may
  /// reserve more than `n`, exactly `n`, less than `n` elements of
  /// storage, or even ignore the request completely.
  public mutating func reserveCapacity(minimumCapacity: Int) { ensureUniqueWithCapacity(minimumCapacity) }

  /// Replace the given `subRange` of elements with `newElements`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`subRange.count`) if
  ///   `subRange.endIndex == self.endIndex` and `newElements.isEmpty`,
  ///   O(`self.count` + `newElements.count`) otherwise.
  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {

    let requiredCapacity = count - subRange.count + numericCast(newElements.count)
    ensureUniqueWithCapacity(requiredCapacity)

    // Replace with uniqued collection
    buffer.replaceRange(subRange, with: newElements)
  }

  /// Append `x` to `self`.
  ///
  /// Applying `successor()` to the index of the new element yields
  /// `self.endIndex`.
  ///
  /// - Complexity: Amortized O(1).
  public mutating func append(x: Element) {
    _updateValue(x.1, forKey: x.0)
  }

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  public mutating func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
    for (key, value) in newElements { _updateValue(value, forKey: key) }
  }

  /// Insert `newElement` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func insert(newElement: Element, atIndex i: Index) {
    replaceRange(i ..< i, with: CollectionOfOne(newElement))
  }

  /// Insert `newElements` at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count + newElements.count`).
  public mutating func insertContentsOf<S : CollectionType where S.Generator.Element == Element>(newElements: S, at i: Index) {
    replaceRange(i ..< i, with: newElements)
  }

  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAtIndex(i: Index) -> Element {
    return _removeAndReturn(i)
  }

  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  public mutating func removeFirst() -> Element {
    return removeAtIndex(startIndex)
  }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `n >= 0 && self.count >= n`.
  public mutating func removeFirst(n: Int) {
    replaceRange(startIndex ..< startIndex.advancedBy(n), with: EmptyCollection())
  }

  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeRange(subRange: Range<Index>) {
    replaceRange(subRange, with: EmptyCollection())
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
  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    guard count > 0 else { return }
    guard keepCapacity else { buffer = Buffer(); return }
    buffer.replaceRange(indices, with: EmptyCollection())
  }
  

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible
extension OrderedDictionary: CustomStringConvertible, CustomDebugStringConvertible {

  private var elementsDescription: String {
    guard count > 0 else { return "[:]" }

    var result = "["
    var first = true
    for (key, value) in self {
      if first { first = false } else { result += ", " }
      debugPrint(key, terminator: "", toStream: &result)
      result += ": "
      debugPrint(value, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  public var description: String {
    guard count > 0 else { return "[:]" }

    var result = "["
    var first = true
    for (key, value) in self {
      if first { first = false } else { result += ", " }
      print(key, terminator: "", toStream: &result)
      result += ": "
      print(value, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }
  
  public var debugDescription: String {
    guard count > 0 else { return "[:]" }

    var result = "["
    var first = true
    for (key, value) in self {
      if first { first = false } else { result += ", " }
      debugPrint(key, terminator: "", toStream: &result)
      result += ": "
      debugPrint(value, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }
}

// MARK: Equatable
extension OrderedDictionary: Equatable {}

public func == <Key: Hashable, Value>
  (lhs: OrderedDictionary<Key, Value>, rhs: OrderedDictionary<Key, Value>) -> Bool
{

  guard !(lhs.buffer.identity == rhs.buffer.identity && lhs.count == rhs.count) else { return true }

  for ((k1, _), (k2, _)) in zip(lhs, rhs) {
    guard k1 == k2 else { return false }
  }

  return lhs.count == rhs.count
}


public func == <Key: Hashable, Value: Equatable>
  (lhs: OrderedDictionary<Key, Value>, rhs: OrderedDictionary<Key, Value>) -> Bool
{
    
  guard !(lhs.buffer.identity == rhs.buffer.identity && lhs.count == rhs.count) else { return true }

  for ((k1, v1), (k2, v2)) in zip(lhs, rhs) {
    guard k1 == k2 && v1 == v2 else { return false }
  }
  
  return lhs.count == rhs.count
}

// MARK: - HashBucket
private struct HashBucket: BidirectionalIndexType, Comparable, Hashable {
  let offset: Int
  let capacity: Int

  func predecessor() -> HashBucket {
    return HashBucket(offset: (offset &- 1) & (capacity &- 1), capacity: capacity)
  }

  func successor() -> HashBucket {
    return HashBucket(offset: (offset &+ 1) & (capacity &- 1), capacity: capacity)
  }

  var hashValue: Int { return offset ^ capacity }
}

// MARK: CustomStringConvertible
extension HashBucket: CustomStringConvertible {
  var description: String { return "\(offset)" }
}

private func ==(lhs: HashBucket, rhs: HashBucket) -> Bool { return lhs.offset == rhs.offset }
private func <(lhs: HashBucket, rhs: HashBucket) -> Bool { return lhs.offset < rhs.offset }


/// Returns the hash value of `value` squeezed into `capacity`
@inline(__always)
private func suggestBucketForValue<H:Hashable>(value: H, capacity: Int) -> HashBucket {
  return HashBucket(offset: _squeezeHashValue(value.hashValue, 0 ..< capacity), capacity: capacity)
}

/// - requires: `initializedBuckets` has an empty bucket (to avoid an infinite loop)
private func findBucketForValue<H:Hashable>(value: H, capacity: Int, initializedBuckets: BitMap) -> HashBucket {
  var bucket = suggestBucketForValue(value, capacity: capacity)
  repeat {
    guard initializedBuckets[bucket.offset] else { return bucket }
    bucket._successorInPlace()
  } while true
}

// MARK: - HashBucketMap
private struct HashBucketMap: CollectionType {

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
    replaceRange(index ... index, with: EmptyCollection())
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
    }

    switch insertCount - removeCount {
      case 0:
        // Nothing more to do
        break

      case let delta where delta < 0:
        // Empty remaining positions in `subRange`

        let lastReplacedSuccessor = subRange.endIndex.advancedBy(delta)
        for index in lastReplacedSuccessor ..< subRange.endIndex {
          let oldBucketOffset = positions[index]
          guard oldBucketOffset > -1 else { continue }
          positions[index] = -1
          let oldPosition = buckets[oldBucketOffset]
          guard oldPosition == index else { continue }
          buckets[oldBucketOffset] = -1
        }

        guard subRange.endIndex < endIndex else { endIndex = lastReplacedSuccessor; return }
        shiftPositionsFrom(subRange.endIndex, by: delta)

      default: /* case let delta where delta > 0 */
        // Insert remaining values

        insertContentsOf(newElements.dropFirst(removeCount), at: subRange.endIndex)

    }
  }

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible
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

// MARK: - HashedStorageHeader
private struct HashedStorageHeader: CustomStringConvertible {
  var count: Int = 0
  let capacity: Int
  let bytesAllocated: Int
  let bucketMap: HashBucketMap

  init(capacity: Int,
       bytesAllocated: Int,
       bucketMap: HashBucketMap)
  {
    self.capacity = capacity
    self.bytesAllocated = bytesAllocated
    self.bucketMap = bucketMap
  }

  var description: String {
    return "\n".join("count: \(count)",
                     "capacity: \(capacity)",
                     "bytesAllocated: \(bytesAllocated)",
                     "bucketMap: \(bucketMap)")
  }
}

private let maxLoadFactorInverse = 1.0/0.75

// MARK: - HashedStorage
private class HashedStorage: ManagedBuffer<HashedStorageHeader, UInt8> {

  typealias Header = HashedStorageHeader

  /// Returns the number of bytes required for the map of buckets to positions given `capacity`
  static func bytesForBucketMap(capacity: Int) -> Int {
    return HashBucketMap.wordsFor(capacity) + alignof(Int)
  }

  /// The number of bytes used to store the bucket map for this instance.
  final var bucketMapBytes: Int { return HashedStorage.bytesForBucketMap(capacity) }

  /// The total number of buckets
  final var capacity: Int { return value.capacity }

  /// The total number of initialized buckets
  final var count: Int { get { return value.count } set { value.count = newValue } }

  /// The total number of bytes managed by this instance; equal to
  /// `initializedBucketsBytes + bucketMapBytes + keysBytes + valuesBytes`
  final var bytesAllocated: Int { return value.bytesAllocated }

  /// Pointer to the first byte in memory allocated for the position map
  final var bucketMapAddress: UnsafeMutablePointer<UInt8> {
    return withUnsafeMutablePointerToElements {$0}
  }

  /// An index mapping buckets to positions and positions to buckets
  final var bucketMap: HashBucketMap { return value.bucketMap }

  var description: String {
    defer { _fixLifetime(self) }
    var result = "HashedStorage {\n"
    result += "\tcapacity: \(capacity)\n"
    result += "\tcount: \(count)\n"
    result += "\tbucketMap: \(bucketMap.debugDescription)\n"
    result += "\ttotal bytes: \(allocatedElementCount)\n"
    result += "\tbucketMapBytes: \(bucketMapBytes)\n"
    result += "\n}"
    return result
  }
}

// MARK: - ConcreteHashedStorage
private protocol ConcreteHashedStorage {
  associatedtype HashedKey: Hashable
  associatedtype HashedValue
  associatedtype Element

  var hashedKeyBaseAddress: UnsafeMutablePointer<HashedKey> { get }
  var hashedValueBaseAddress: UnsafeMutablePointer<HashedValue> { get }

  static func keyForElement(element: Element) -> HashedKey

  func elementAtOffset(offset: Int) -> Element
  func initializeAtOffset(offset: Int, element: Element) -> Void
  func destroyAtOffset(offset: Int) -> Void
  func moveAtOffset(offset: Int) -> Element
  func updateAtOffset(offset: Int, element: Element) -> Element

  static func create(minimumCapacity: Int) -> Self
}

// MARK: - OrderedSetStorage
/// Specialization of `HashedStorage` for an ordered set
private final class OrderedSetStorage<Value:Hashable>: HashedStorage, ConcreteHashedStorage {

  typealias Storage = OrderedSetStorage<Value>
  typealias Header = HashedStorageHeader
  typealias HashedValue = Value
  typealias Element = Value
  typealias HashedKey = Value

  /// Returns the number of bytes required to store the elements for a given `capacity`.
  static func bytesForValues(capacity: Int) -> Int {
    let padding = max(0, alignof(Value) - alignof(Int))
    return strideof(Value) * capacity + padding
  }

  /// The number of bytes used to store the elements for this instance
  var valuesBytes: Int { return Storage.bytesForValues(capacity) }

  /// Pointer to the first byte in memory allocated for the hash values
  var values: UnsafeMutablePointer<Value> {
    return UnsafeMutablePointer<Value>(bucketMapAddress + bucketMapBytes)
  }

  var hashedKeyBaseAddress: UnsafeMutablePointer<HashedKey> { return values }

  var hashedValueBaseAddress: UnsafeMutablePointer<HashedValue> { return values }

  @inline(__always)
  static func keyForElement(element: Element) -> HashedKey { return element }

  func elementAtOffset(offset: Int) -> Element {
    return values[offset]
  }

  func initializeAtOffset(offset: Int, element: Element) -> Void {
    (values + offset).initialize(element)
  }

  func destroyAtOffset(offset: Int) -> Void {
    (values + offset).destroy()
  }

  func moveAtOffset(offset: Int) -> Element {
    return (values + offset).move()
  }

  func updateAtOffset(offset: Int, element: Element) -> Element {
    let oldValue = (values + offset).move()
    (values + offset).initialize(element)
    return oldValue
  }

  /// Create a new storage instance.
  static func create(minimumCapacity: Int) -> OrderedSetStorage {
    let capacity = round2(minimumCapacity)

    let bucketMapBytes = bytesForBucketMap(capacity)
    let elementsBytes = bytesForValues(capacity)
    let requiredCapacity = bucketMapBytes + elementsBytes

    let storage = super.create(requiredCapacity) {
      let bucketMapStorage = $0.withUnsafeMutablePointerToElements {$0}
      let bucketMap = HashBucketMap(storage: pointerCast(bucketMapStorage), capacity: capacity)
      let bytesAllocated = $0.allocatedElementCount
      let header =  Header(capacity: capacity,
                           bytesAllocated: bytesAllocated,
                           bucketMap: bucketMap)
      return header
    }

    return storage as! Storage
  }

  deinit {
    guard count > 0 && !_isPOD(Value) else { return }
    defer { _fixLifetime(self) }
    let elements = self.values
    for bucket in bucketMap { (elements + bucket.offset).destroy() }
  }

  override var description: String {
    defer { _fixLifetime(self) }
    var components = "\n".split(super.description)[1..<8]
    components.append("\tvaluesBytes: \(valuesBytes)")
    var result = "OrderedSetStorage {\n"
    result += components.joinWithSeparator("\n")
    result += "\n}"
    return result
  }
}

// MARK: - OrderedDictionaryStorage
/// Specialization of `HashedStorage` for an ordered dictionary
private final class OrderedDictionaryStorage<Key:Hashable, Value>: HashedStorage, ConcreteHashedStorage {

  typealias Storage = OrderedDictionaryStorage<Key, Value>
  typealias Header = HashedStorageHeader
  typealias Element = (Key, Value)
  typealias HashedKey = Key
  typealias HashedValue = Value

  /// Returns the number of bytes required to store the keys for a given `capacity`.
  static func bytesForKeys(capacity: Int) -> Int {
    let padding = max(0, alignof(Key) - alignof(Int))
    return strideof(Key) * capacity + padding
  }

  /// The number of bytes used to store the keys for this instance
  var keysBytes: Int { return Storage.bytesForKeys(capacity) }

  /// Returns the number of bytes required to store the values for a given `capacity`.
  static func bytesForValues(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(Key), alignof(Int))
    let padding = max(0, alignof(Value) - maxPrevAlignment)
    return strideof(Value) * capacity + padding
  }

  /// The number of bytes used to store the values for this instance
  var valuesBytes: Int { return Storage.bytesForValues(capacity) }

  /// Pointer to the first byte in memory allocated for the keys
  var keys: UnsafeMutablePointer<Key> {
    return UnsafeMutablePointer<Key>(bucketMapAddress + bucketMapBytes)
  }

  var hashedKeyBaseAddress: UnsafeMutablePointer<HashedKey> { return keys }

  @inline(__always)
  static func keyForElement(element: Element) -> HashedKey { return element.0 }

  /// Pointer to the first byte in memory allocated for the values
  var values: UnsafeMutablePointer<Value> {
    // Conversion back to UInt8 pointer necessary for `+` operator to advance by byte
    return UnsafeMutablePointer<Value>(UnsafeMutablePointer<UInt8>(keys) + keysBytes)
  }

  var hashedValueBaseAddress: UnsafeMutablePointer<HashedValue> { return values }

  func elementAtOffset(offset: Int) -> Element {
    return (keys[offset], values[offset])
  }

  func initializeAtOffset(offset: Int, element: Element) -> Void {
    (keys + offset).initialize(element.0)
    (values + offset).initialize(element.1)
  }

  func destroyAtOffset(offset: Int) -> Void {
    (keys + offset).destroy()
    (values + offset).destroy()
  }

  func moveAtOffset(offset: Int) -> Element {
    return ((keys + offset).move(), (values + offset).move())
  }

  func updateAtOffset(offset: Int, element: Element) -> Element {
    assert(keys[offset] == element.0, "keys do not match")
    let oldKey = (keys + offset).move()
    (keys + offset).initialize(element.0)
    let oldValue = (values + offset).move()
    (values + offset).initialize(element.1)
    return (oldKey, oldValue)
  }

  /// Create a new storage instance.
  static func create(minimumCapacity: Int) -> OrderedDictionaryStorage {
    let capacity = round2(minimumCapacity)

    let bucketMapBytes = bytesForBucketMap(capacity)
    let keysBytes = bytesForKeys(capacity)
    let valuesBytes = bytesForValues(capacity)
    let requiredCapacity = bucketMapBytes + keysBytes + valuesBytes

    let storage = super.create(requiredCapacity) {
      let bucketMapStorage = $0.withUnsafeMutablePointerToElements {$0}
      let bucketMap = HashBucketMap(storage: pointerCast(bucketMapStorage), capacity: capacity)
      let bytesAllocated = $0.allocatedElementCount
      let header =  Header(capacity: capacity,
                           bytesAllocated: bytesAllocated,
                           bucketMap: bucketMap)
      return header
    }


    return storage as! Storage
  }

  deinit {
    guard count > 0 else { return }

    let (keys, values) = (self.keys, self.values)

    switch (_isPOD(Key), _isPOD(Value)) {
      case (true, true): return
      case (true, false):
        for bucket in bucketMap { (values + bucket.offset).destroy() }
      case (false, true):
        for bucket in bucketMap { (keys + bucket.offset).destroy() }
      case (false, false):
        for bucket in bucketMap { (keys + bucket.offset).destroy(); (values + bucket.offset).destroy() }
    }
  }

  override var description: String {
    defer { _fixLifetime(self) }
    var components = "\n".split(super.description)[1..<8]
    components.append("\tkeysBytes: \(keysBytes)")
    components.append("\tvaluesBytes: \(valuesBytes)")
    var result = "OrderedDictionaryStorage {\n"
    result += components.joinWithSeparator("\n")
    result += "\n}"
    return result
  }
}

// MARK: - HashedStorageBuffer
private struct HashedStorageBuffer<Storage: HashedStorage where Storage:ConcreteHashedStorage>: MutableCollectionType {

  typealias HashedKey = Storage.HashedKey
  typealias HashedValue = Storage.HashedValue
  typealias Element = Storage.Element
  typealias _Element = Element
  typealias Index = Int
  typealias Buffer = HashedStorageBuffer<Storage>
  typealias SubSequence = Buffer

  private(set) var storage: Storage

  let bucketMap: HashBucketMap
  let hashedKeys: UnsafeMutablePointer<HashedKey>
  let hashedValues: UnsafeMutablePointer<HashedValue>
  let keyIsValue: Bool

  @inline(__always) mutating func isUniquelyReferenced() -> Bool { return Swift.isUniquelyReferenced(&storage) }

  let indexOffset: Int

  var startIndex: Int
  var endIndex: Int

  @inline(__always) private func offsetPosition(position: Int) -> Int { return position &- indexOffset }
  @inline(__always) private func offsetPosition(position: Range<Int>) -> Range<Int> { return position &- indexOffset }
  @inline(__always) private func offsetIndex(index: Int) -> Int { return index &+ indexOffset }
  @inline(__always) private func offsetIndex(index: Range<Int>) -> Range<Int> { return index &+ indexOffset }

  var count: Int { return endIndex &- startIndex }
  var capacity: Int { return indexOffset == 0 ? storage.capacity &- startIndex : storage.capacity }

  /// Returns the minimum capacity for storing `count` elements.
  @inline(__always)
  static func minimumCapacityForCount(count: Int) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(count) * maxLoadFactorInverse), count &+ 1)
  }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(storage.withUnsafeMutablePointerToElements { $0 }) }

  init(storage: Storage, indices: Range<Int>, indexOffset: Int) {
    self.storage = storage
    bucketMap = storage.bucketMap
    hashedKeys = storage.hashedKeyBaseAddress
    hashedValues = storage.hashedValueBaseAddress
    keyIsValue = UnsafePointer<Void>(hashedKeys) == UnsafePointer<Void>(hashedValues)

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
  func idealBucketForKey(hashedKey: HashedKey) -> HashBucket {
    return suggestBucketForValue(hashedKey, capacity: storage.capacity)
  }

  /// Returns the bucket for `element` diregarding collisions
//  private func idealBucketForElement(element: Element) -> HashBucket {
//    return idealBucketForKey(Storage.keyForElement(element))
//  }

  /// Returns the position assigned to `bucket` or `nil` if no position is assigned
//  private func positionForBucket(bucket: HashBucket) -> Int? {
//    return bucketMap[bucket]
//  }

  /// Returns the bucket for the element assigned to `position`.
  /// - requires: A bucket has been assigned to `position`
//  private func bucketForPosition(position: Int) -> HashBucket {
//    return bucketMap[offsetPosition(position)]
//  }

  /// Returns `false` when `bucket` is empty and `true` otherwise.
//  private func isInitializedBucket(bucket: HashBucket) -> Bool {
//    return bucketMap[bucket] != nil
//  }

  /// Returns the hashed key for the specified bucket.
//  private func keyForBucket(bucket: HashBucket) -> HashedKey {
//    return hashedKeys[bucket.offset]
//  }

  /// Returns the hashed value for the specified bucket.
  func valueForBucket(bucket: HashBucket) -> HashedValue {
    return hashedValues[bucket.offset]
  }

  /// Returns the bucket containing `hashedKey` or `nil` if no bucket contains `element`.
  func currentBucketForKey(key: HashedKey) -> HashBucket? {
    let (bucket, found) = find(key)
    return found ? bucket : nil
  }

  /// Returns whether `key` is present in the buffer.
  func containsKey(key: HashedKey) -> Bool {
    let (_, found) = find(key)
    return found
  }

  /// Returns the bucket containing `element` or `nil` if no bucket contains `element`.
  func currentBucketForElement(element: Element) -> HashBucket? {
      return currentBucketForKey(Storage.keyForElement(element))
  }

  /// Returns an empty bucket suitable for holding `hashedKey` or `nil` if a bucket already contains `key`.
//  private func emptyBucketForKey(key: HashedKey) -> HashBucket? {
//    let (bucket, found) = find(key)
//    return found ? nil : bucket
//  }

  /// Returns an empty bucket suitable for holding `element` or `nil` if a bucket already contains `element`.
  func emptyBucketForElement(element: Element) -> HashBucket? {
    let (bucket, found) = find(Storage.keyForElement(element))
    return found ? nil : bucket
  }

  /// Returns the hashed key for the specified position.
  /// - requires: A bucket has been assigned to `position`
//  func keyForPosition(position: Int) -> HashedKey {
//    return hashedKeys[bucketMap[offsetPosition(position)].offset]
//  }

  /// Returns the hashed value for the specified position.
  /// - requires: A bucket has been assigned to `position`
  func valueForPosition(position: Int) -> HashedValue {
    return valueForBucket(bucketMap[offsetPosition(position)])
  }

  func indexForBucket(bucket: HashBucket) -> Int? {
    guard let index = bucketMap[bucket] else { return nil }
    return offsetIndex(index)
  }

  /// Returns the position for `hashedKey` or `nil` if `hashedKey` is not found.
  func indexForKey(hashedKey: HashedKey) -> Int? {
    guard count > 0, let bucket = currentBucketForKey(hashedKey) else { return nil }
    return indexForBucket(bucket)
  }

  /// Returns the position for `element` or `nil` if `element` is not found.
  func indexOf(element: Element) -> Int? {
    guard count > 0, let bucket = currentBucketForElement(element) else { return nil }
    return indexForBucket(bucket)
  }

  /// Returns the current bucket for `key` and `true` when `key` is located;
  /// returns an open bucket for `key` and `false` otherwise
  /// - requires: At least one empty bucket
  func find(key: HashedKey) -> (bucket: HashBucket, found: Bool) {
    let startBucket = idealBucketForKey(key)
    var bucket = startBucket

    repeat {
      guard bucketMap[bucket] != nil else { return (bucket, false) }
      guard hashedKeys[bucket.offset] != key  else { return (bucket, true) }
      bucket._successorInPlace()
    } while bucket != startBucket

    fatalError("failed to locate hole")
  }

  /// Initializes `bucket` with `element` at `position`.
  /// - requires: `bucket` is empty
  func initializeBucket(bucket: HashBucket, with element: Element, at position: Int) {
    storage.initializeAtOffset(bucket.offset, element: element)
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
    return storage.updateAtOffset(currentBucket.offset, element: element)
  }

  /// Attempts to move the values of the buckets near `hole` into buckets nearer to their 'ideal' bucket
  func patchHole(hole: HashBucket, idealBucket: HashBucket) {

    var hole = hole
    var start = idealBucket
    while bucketMap[start.predecessor()] != nil { start._predecessorInPlace() }

    var lastInChain = hole
    var last = lastInChain.successor()
    while bucketMap[last] != nil { lastInChain = last; last._successorInPlace() }

    while hole != lastInChain {
      last = lastInChain
      FillHole: while last != hole {
        let key = hashedKeys[last.offset]
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
      storage.initializeAtOffset(hole.offset, element: storage.moveAtOffset(last.offset))
      bucketMap.replaceBucket(last, with: hole)
      hole = last
    }

  }

  /// Removes elements common with `elements`.
  mutating func removeContentsOf<S:SequenceType where S.Generator.Element == Element>(elements: S) {

    var ranges = RangeMap<Int>()
    for element in elements {
      guard let index = indexForKey(Storage.keyForElement(element)) else { continue }
      ranges.insert(index)
    }

    guard ranges.count > 0 else { return }

    var removedCount = 0
    for range in ranges {
      let adjustedRange = range - removedCount
      removeRange(adjustedRange)
      removedCount = removedCount &+ adjustedRange.count
    }

  }

  /// Uninitializes the bucket for `position`, adjusts positions and `endIndex` and patches the hole.
  mutating func destroyAt(position: Index) {

    let hole = bucketMap[offsetPosition(position)]
    let idealBucket = idealBucketForKey(hashedKeys[hole.offset])

    storage.destroyAtOffset(hole.offset)
    bucketMap.removeBucketAt(offsetPosition(position))
    endIndex = endIndex &- 1
    patchHole(hole, idealBucket: idealBucket)
  }

  subscript(index: Int) -> Element {
    get { return storage.elementAtOffset(bucketMap[offsetPosition(index)].offset) }
    set {
      storage.destroyAtOffset(bucketMap[offsetPosition(index)].offset)
      initializeElement(newValue, at: index)
    }
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
  }

  /// A non-binding request to ensure `n` elements of available storage.
  ///
  /// This works as an optimization to avoid multiple reallocations of
  /// linear data structures like `Array`.  Conforming types may
  /// reserve more than `n`, exactly `n`, less than `n` elements of
  /// storage, or even ignore the request completely.
  mutating func reserveCapacity(n: Int) {
    //TODO: Test reserveCapacity
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
    storage.initializeAtOffset(bucket.offset, element: newElement)
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
      storage.initializeAtOffset(bucket.offset, element: element)
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
    let result = self[i]
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

    switch subRange.count {
      case 0: return
      case 1: destroyAt(subRange.startIndex)
      case let delta:
        let buckets = subRange.map { bucketMap[offsetPosition($0)] }
        let idealBuckets = buckets.map { idealBucketForKey(hashedKeys[$0.offset]) }
        buckets.forEach { storage.destroyAtOffset($0.offset) }
        zip(buckets, idealBuckets).forEach { patchHole($0, idealBucket: $1) }

        bucketMap.replaceRange(offsetPosition(subRange), with: EmptyCollection())
        storage.count = storage.count &- delta
        endIndex = endIndex &- delta
    }
    
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
    for bucket in bucketMap { storage.destroyAtOffset(bucket.offset) }
    bucketMap.removeAll()
  }

}

// MARK: CustomStringConvertible, CustomDebugStringConvertible
extension HashedStorageBuffer: CustomStringConvertible, CustomDebugStringConvertible {

  var elementsDescription: String {
    if count == 0 { return keyIsValue ? "[]" : "[:]" }

    var result = "["
    var first = true
    for position in startIndex ..< endIndex {
      if first { first = false } else { result += ", " }
      let bucket = bucketMap[offsetPosition(position)]
      let element = storage.elementAtOffset(bucket.offset)
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
      result += "position \(position) ➞ bucket \(bucket) [\(storage.elementAtOffset(bucket.offset))]\n"
    }
    for position in endIndex ..< capacity {
      result += "position \(position), empty\n"
    }
    for bucketOffset in 0 ..< bucketMap.capacity {
      let bucket = HashBucket(offset: bucketOffset, capacity: bucketMap.capacity)
      if let position = bucketMap[bucket] {
        let key = hashedKeys[bucket.offset]
        result += "bucket \(bucket), key = \(key), ideal bucket = \(idealBucketForKey(key)), position = \(position)\n"
      } else {
        result += "bucket \(bucket), empty\n"
      }
    }
    return result
  }


}
