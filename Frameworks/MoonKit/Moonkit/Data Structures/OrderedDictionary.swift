//
//  OrderedDictionary.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/7/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

/// A hash-based mapping from `Key` to `Value` instances that preserves elment order.
public struct OrderedDictionary<Key: Hashable, Value>: _DestructorSafeContainer {

  typealias Storage = OrderedDictionaryStorage<Key, Value>
  typealias Buffer = HashedStorageBuffer<Storage>//OrderedDictionaryBuffer<Key, Value>

  public typealias Index = Int
  public typealias Element = (Key, Value)
  public typealias _Element = Element
  public typealias SubSequence = OrderedDictionary<Key, Value>

  private(set) var buffer: Buffer

  /// Returns a new buffer backed by storage cloned from the existing buffer.
  /// Unreachable elements are not copied; however, `startIndex` and `endIndex` values are preserved.
  func cloneBuffer(newCapacity: Int) -> Buffer {

    var clone = Buffer(minimumCapacity: newCapacity, offsetBy: startIndex)

    for position in buffer.indices {
      clone.initializeElement(buffer.elementForPosition(position), at: position)
      clone.endIndex += 1
    }

    clone.storage.count = buffer.count

    return clone
  }

  /// Checks that `owner` has only the one strong reference
  mutating func ensureUnique() -> (reallocated: Bool, capacityChanged: Bool) {
    guard !buffer.isUniquelyReferenced() else { return (false, false) }
    buffer = cloneBuffer(capacity)
    return (true, false)
  }

  /// Checks that `owner` has only the one strong reference and that it's `buffer` has at least `minimumCapacity` capacity
  mutating func ensureUniqueWithCapacity(minimumCapacity: Int) -> (reallocated: Bool, capacityChanged: Bool) {
    switch (isUnique: buffer.isUniquelyReferenced(), hasCapacity: capacity >= minimumCapacity) {

      case (isUnique: true, hasCapacity: true):
        return (reallocated: false, capacityChanged: false)

      case (isUnique: true, hasCapacity: false):
        buffer = cloneBuffer(Buffer.minimumCapacityForCount(minimumCapacity))
        return (reallocated: true, capacityChanged: true)

      case (isUnique: false, hasCapacity: true):
        buffer = cloneBuffer(capacity)
        return (reallocated: true, capacityChanged: false)

      case (isUnique: false, hasCapacity: false):
        buffer = cloneBuffer(Buffer.minimumCapacityForCount(minimumCapacity))
        return (reallocated: true, capacityChanged: true)
    }

  }

  public init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }

  init(buffer: Buffer) { self.buffer = buffer }

  mutating func _remove(index: Index) {
    ensureUniqueWithCapacity(capacity)
    buffer.destroyAt(index)
  }

  mutating func _removeAndReturn(index: Index) -> Element {
    let result = buffer.elementForPosition(index)
    _remove(index)
    return result
  }

  mutating func _removeValueForKey(key: Key) {
    guard let index = buffer.indexForKey(key) else { return }
    _remove(index)
  }

  mutating func _removeAndReturnValueForKey(key: Key) -> Value? {
    guard let index = buffer.indexForKey(key) else { return nil }
    return _removeAndReturn(index).1
  }

  mutating func _updateValue(value: Value, forKey key: Key) {
    let found = buffer.containsKey(key)

    let minCapacity = found
      ? capacity
      : Buffer.minimumCapacityForCount(buffer.count + 1)

    ensureUniqueWithCapacity(minCapacity)

    if found { buffer.updateElement((key, value)) }
    else { buffer.append((key, value)) }
  }

  mutating func _updateAndReturnValue(value: Value, forKey key: Key) -> Element? {
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
    get { return buffer.elementForPosition(index) }
    set {
      ensureUniqueWithCapacity(count)
      buffer.replaceElementAt(index, with: newValue)
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

  public var description: String { return elementsDescription }
  
  public var debugDescription: String { return elementsDescription }
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
