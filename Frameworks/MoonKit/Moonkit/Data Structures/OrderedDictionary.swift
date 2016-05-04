//
//  OrderedDictionary.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/7/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

internal let maxLoadFactorInverse = 1/0.75

// MARK: - Generator
// MARK: -

public struct OrderedDictionaryGenerator<Key: Hashable, Value>: GeneratorType {
  typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  let buffer: Buffer
  var index: Int = 0
  init(buffer: Buffer) { self.buffer = buffer }
    
  public mutating func next() -> (Key, Value)? {
    guard index < buffer.count else { return nil }
    defer { index = index.successor() }
    return buffer.elementAtPosition(index)
  }
}

// MARK: - Owner
// MARK: -

final class OrderedDictionaryStorageOwner<Key: Hashable, Value>: NonObjectiveCBase {

  typealias Buffer = OrderedDictionaryBuffer<Key, Value>

  var buffer: Buffer

  init(minimumCapacity: Int) {
    buffer = Buffer(minimumCapacity: minimumCapacity)
  }

  init(buffer: Buffer) {
    self.buffer = buffer
  }

}

// MARK: - OrderedDictionary
// MARK: -

/// A hash-based mapping from `Key` to `Value` instances that preserves elment order.
public struct OrderedDictionary<Key: Hashable, Value>: CollectionType, DictionaryLiteralConvertible {

  typealias Buffer = OrderedDictionaryBuffer<Key, Value>
  typealias Storage = OrderedDictionaryStorage<Key, Value>
  typealias Owner = OrderedDictionaryStorageOwner<Key, Value>

  public typealias Index = Int
  public typealias Generator = OrderedDictionaryGenerator<Key, Value>
  public typealias Element = (Key, Value)
  public typealias _Element = Element

  var buffer: Buffer {
    get { return owner.buffer }
    set { owner.buffer = newValue }
  }

  var owner: Owner

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
    switch (isUnique: isUniquelyReferenced(&owner), hasCapacity: capacity >= minimumCapacity) {

      case (isUnique: true, hasCapacity: true):
        return (reallocated: false, capacityChanged: false)

      case (isUnique: true, hasCapacity: false):
        owner.buffer = cloneBuffer(Int(Double(minimumCapacity) * maxLoadFactorInverse))
        return (reallocated: true, capacityChanged: true)

      case (isUnique: false, hasCapacity: true):
        owner = Owner(buffer: cloneBuffer(capacity))
        return (reallocated: true, capacityChanged: false)

      case (isUnique: false, hasCapacity: false):
        owner = Owner(buffer: cloneBuffer(Int(Double(minimumCapacity) * maxLoadFactorInverse)))
        return (reallocated: true, capacityChanged: true)
    }

  }


  public init() { owner = Owner(minimumCapacity: 0) }

  public init(minimumCapacity: Int) { owner = Owner(minimumCapacity: minimumCapacity) }

  init(buffer: Buffer) { owner = Owner(buffer: buffer) }

  public var startIndex: Index { return 0 }

  public var endIndex: Index { return count }

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

  public mutating func removeValueForKey(key: Key) -> Value? {
    let oldValue = UnsafeMutablePointer<Value?>.alloc(1)
    _removeValueForKey(key, oldValue: oldValue)
    return oldValue.memory
  }

  public func indexForKey(key: Key) -> Index? { return buffer.positionForKey(key) }

  public subscript(position: Index) -> (Key, Value) { return buffer.elementAtPosition(position) }

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

  public mutating func updateValue(value: Value, forKey key: Key) -> Value? {
    let oldValue = UnsafeMutablePointer<Value?>.alloc(1)
    _updateValue(value, forKey: key, oldValue: oldValue, oldKey: nil)
    return oldValue.memory
  }

  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {

    let capacity = keepCapacity ? self.capacity : 0
    owner = Owner(buffer: Buffer(storage: Storage.create(capacity)))
  }

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public func generate() -> Generator { return Generator(buffer: buffer) }

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

  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }

  for ((k1, _), (k2, _)) in zip(lhs, rhs) {
    guard k1 == k2 else { return false }
  }

  return true
}


public func == <Key: Hashable, Value: Equatable>
  (lhs: OrderedDictionary<Key, Value>, rhs: OrderedDictionary<Key, Value>) -> Bool
{
    
  guard lhs.owner !== rhs.owner else { return true }
  guard lhs.count == rhs.count else { return false }
  
  for ((k1, v1), (k2, v2)) in zip(lhs, rhs) {
    guard k1 == k2 && v1 == v2 else { return false }
  }
  
  return true
}
