//
//  OrderedDictionary.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/7/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

internal let maxLoadFactorInverse = 1/0.75

/// A hash-based mapping from `Key` to `Value` instances that preserves elment order.
public struct OrderedDictionary<Key: Hashable, Value>: CollectionType, DictionaryLiteralConvertible, _DestructorSafeContainer {

  typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  typealias Storage = OrderedDictionaryStorage<Key, Value>

  public typealias Index = Int
  public typealias Element = (Key, Value)
  public typealias _Element = Element

  private(set) var buffer: Buffer

  func cloneBuffer(newCapacity: Int) -> Buffer {

    let clone = Buffer(minimumCapacity: newCapacity)

    if clone.capacity == buffer.capacity {
      for (position, bucket) in buffer.bucketMap.enumerate() {
        let (key, value) = buffer.elementInBucket(bucket)
        clone.initializeKey(key, forValue: value, position: position, bucket: bucket)
      }
    } else {
      for (position, bucket) in buffer.bucketMap.enumerate() {
        let (key, value) = buffer.elementInBucket(bucket)
        clone.initializeKey(key, forValue: value, position: position)
      }
    }

    clone.count = buffer.count

    return clone
  }

  /// Checks that `owner` has only the one strong reference and that it's `buffer` has at least `minimumCapacity` capacity
  mutating func ensureUniqueWithCapacity(minimumCapacity: Int) -> (reallocated: Bool, capacityChanged: Bool) {
    switch (isUnique: buffer.isUniquelyReferenced(), hasCapacity: capacity >= minimumCapacity) {

      case (isUnique: true, hasCapacity: true):
        return (reallocated: false, capacityChanged: false)

      case (isUnique: true, hasCapacity: false):
        buffer = cloneBuffer(Int(Double(minimumCapacity) * maxLoadFactorInverse))
        return (reallocated: true, capacityChanged: true)

      case (isUnique: false, hasCapacity: true):
        buffer = cloneBuffer(capacity)
        return (reallocated: true, capacityChanged: false)

      case (isUnique: false, hasCapacity: false):
        buffer = cloneBuffer(Int(Double(minimumCapacity) * maxLoadFactorInverse))
        return (reallocated: true, capacityChanged: true)
    }

  }

  public init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }

  init(buffer: Buffer) { self.buffer = buffer }

  mutating func _removeAtIndex(index: Index, oldElement: UnsafeMutablePointer<Element>) {
    if oldElement != nil { oldElement.initialize(buffer.elementInBucket(buffer.bucketForPosition(index))) }
    ensureUniqueWithCapacity(capacity)
    buffer.destroyElementAt(index)
  }

  public mutating func removeAtIndex(index: Index) -> Element {
    let oldElement = UnsafeMutablePointer<Element>.alloc(1)
    _removeAtIndex(index, oldElement: oldElement)
    return oldElement.memory
  }

  mutating func _removeValueForKey(key: Key, oldValue: UnsafeMutablePointer<Value?>) {
    guard let index = buffer.positionForKey(key) else {
      if oldValue != nil { oldValue.initialize(nil) }
      return
    }
    if oldValue != nil {
      let oldElement = UnsafeMutablePointer<Element>.alloc(1)
      _removeAtIndex(index, oldElement: oldElement)
      oldValue.initialize(oldElement.memory.1)
    } else {
      _removeAtIndex(index, oldElement: nil)
    }
  }

  /// Removes the value associated with `key` and returns it. Returns `nil` if `key` is not present.
  public mutating func removeValueForKey(key: Key) -> Value? {
    let oldValue = UnsafeMutablePointer<Value?>.alloc(1)
    _removeValueForKey(key, oldValue: oldValue)
    return oldValue.memory
  }

  /// Returns the index of `key` or `nil` if `key` is not present.
  public func indexForKey(key: Key) -> Index? { return buffer.positionForKey(key) }

  /// Returns the value associated with `key` or `nil` if `key` is not present.
  public func valueForKey(key: Key) -> Value? {
    return buffer.valueForKey(key)
  }

  /// Access the value associated with the given key.
  /// Reading a key that is not present in self yields nil. Writing nil as the value for a given key erases that key from self.
  /// - attention: Is there a conflict when `Key` = `Index` or do the differing return types resolve ambiguity?
  public subscript(key: Key) -> Value? {
    get { return buffer.valueForKey(key) }
    set {
      if let value = newValue { _updateValue(value, forKey: key, oldValue: nil, oldKey: nil) }
      else { _removeValueForKey(key, oldValue: nil) }
    }
  }

  mutating func _updateValue(value: Value,
                              forKey key: Key,
                            oldValue: UnsafeMutablePointer<Value?>,
                              oldKey: UnsafeMutablePointer<Key?>)
  {
    var (bucket, found) = buffer.find(key)

    if oldValue != nil || oldKey != nil {
      if found {
        let (key, value) = buffer.elementInBucket(bucket)
        if oldKey != nil { oldKey.initialize(key) }
        if oldValue != nil { oldValue.initialize(value) }
      } else {
        if oldKey != nil { oldKey.initialize(nil) }
        if oldValue != nil { oldValue.initialize(nil) }
      }
    }

    let minCapacity = found
      ? capacity
      : Buffer.minimumCapacityForCount(buffer.count + 1)

    let (_, capacityChanged) = ensureUniqueWithCapacity(minCapacity)
    if capacityChanged { (bucket, found) = buffer.find(key) }

    if found {
      buffer.setValue(value, inBucket: bucket)
    } else {
      buffer.initializeKey(key, forValue: value, bucket: bucket)
      buffer.count += 1
    }
  }

  public mutating func insertValue(value: Value, forKey key: Key) {
    _updateValue(value, forKey: key, oldValue: nil, oldKey: nil)
  }

  public mutating func updateValue(value: Value, forKey key: Key) -> Value? {
    let oldValue = UnsafeMutablePointer<Value?>.alloc(1)
    _updateValue(value, forKey: key, oldValue: oldValue, oldKey: nil)
    return oldValue.memory
  }

  public mutating func removeFirst() -> Element { return removeAtIndex(0) }

  public var first: Element? { guard count > 0 else { return nil }; return buffer.elementAtPosition(0) }

  public mutating func popFirst() -> Element? { guard count > 0 else { return nil }; return removeAtIndex(0) }

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public init(elements: [Element]) {
    var keys: Set<Int> = []
    var filteredElements: [Element] = []
    for element in elements where !keys.contains(element.0.hashValue) {
      keys.insert(element.0.hashValue)
      filteredElements.append(element)
    }
    let buffer = Buffer(elements: filteredElements)
    self.init(buffer: buffer)
  }

  public init(dictionaryLiteral elements: Element...) {
    self.init(elements: elements)
  }

  public var keys: LazyMapCollection<OrderedDictionary<Key, Value>, Key> {
    return lazy.map { $0.0 }
  }

  public var values: LazyMapCollection<OrderedDictionary<Key, Value>, Value> {
    return lazy.map { $0.1 }
  }

  public var isEmpty: Bool { return count == 0 }

}

extension OrderedDictionary: MutableIndexable {

  public var startIndex: Index { return 0 }

  public var endIndex: Index { return count }

  public subscript(index: Index) -> Element {
    get { return buffer.elementAtPosition(index) }
    set { buffer.replaceElementAtPosition(index, with: newValue) }
  }
  
}

extension OrderedDictionary: SequenceType {

  public typealias Generator = IndexingGenerator<OrderedDictionary<Key, Value>> //OrderedDictionaryGenerator<Key, Value>
  public typealias SubSequence = OrderedDictionarySlice<Key, Value>

  public func generate() -> Generator { return Generator(self) } //buffer: buffer, bounds: indices) }

  public func dropFirst(n: Int) -> SubSequence { return self[n..<] }

  public func dropLast(n: Int) -> SubSequence { return self[..<endIndex.advancedBy(-n)] }

  public func prefix(maxLength: Int) -> SubSequence { return self[..<min(count, maxLength)] }

  public func suffix(maxLength: Int) -> SubSequence { return self[max(startIndex, endIndex.advancedBy(-maxLength))..<] }

  public func split(maxSplit: Int,
                    allowEmptySlices: Bool,
                    @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    var result: [SubSequence] = []
    var subSequenceStart = startIndex

    var currentIndex = startIndex

    // Iterate through indices
    while currentIndex < endIndex {

      // Check whether element at `currentIndex` is a separator
      if try isSeparator(buffer.elementAtPosition(currentIndex)) {

        // Check for a non-empty range from previous split to current index
        if subSequenceStart < currentIndex { result.append(self[subSequenceStart ..< currentIndex]) }


        // Iterate through consecutive separator elements
        repeat { currentIndex._successorInPlace() } while try (currentIndex < endIndex && isSeparator(buffer.elementAtPosition(currentIndex)))

        // Append empty slice if two or more consecutive separators were consumed and `allowEmptySlices` is set to `true`
        if currentIndex > subSequenceStart.successor() && allowEmptySlices {
          result.append(OrderedDictionarySlice<Key, Value>(buffer: buffer[subSequenceStart ..< subSequenceStart]))
        }
        subSequenceStart = currentIndex

      } else {

        currentIndex._successorInPlace()

      }

    }

    // Check for a trailing subsequence
    if subSequenceStart < currentIndex { result.append(self[subSequenceStart ..< currentIndex]) }
    
    return result
  }
}

extension OrderedDictionary: MutableCollectionType {
  public subscript(subRange: Range<Int>) -> SubSequence {
    get {
      return SubSequence(buffer: buffer[subRange])
    }
    set {
      buffer.replaceRange(subRange, with: newValue)
    }
  }
}

extension OrderedDictionary: RangeReplaceableCollectionType {

  public init() { buffer = Buffer(minimumCapacity: 0) }

  public mutating func reserveCapacity(minimumCapacity: Int) { ensureUniqueWithCapacity(minimumCapacity) }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {

    let requiredCapacity = count - subRange.count + numericCast(newElements.count)
    ensureUniqueWithCapacity(requiredCapacity)

    // Replace with uniqued collection
    buffer.replaceRange(subRange, with: newElements)
  }

  public mutating func append(element: Element) { self[element.0] = element.1 }

  public mutating func appendContentsOf<S:SequenceType where S.Generator.Element == Element>(newElements: S) {
    for element in newElements { self[element.0] = element.1 }
  }

  public mutating func insert(newElement: Element, atIndex i: Int) {
    replaceRange(i ..< i, with: CollectionOfOne(newElement))
  }

  public mutating func insertContentsOf<C:CollectionType
    where C.Generator.Element == Element>(newElements: C, at i: Int)
  {
    replaceRange(i ..< i, with: newElements)
  }

  public mutating func removeFirst(n: Int) {
    replaceRange(0 ..< n, with: EmptyCollection())
  }

  public mutating func removeRange(subRange: Range<Int>) {
    replaceRange(subRange, with: EmptyCollection())
  }

  public mutating func removeAll(keepCapacity: Bool = false) {
    buffer = Buffer(storage: Storage.create(keepCapacity ? capacity : 0))
  }
  
}

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
