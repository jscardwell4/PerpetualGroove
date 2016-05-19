//
//  OrderedSet.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/30/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

/// A hash-based mapping from `Key` to `Element` instances that preserves elment order.
public struct OrderedSet<Element:Hashable>: CollectionType {
  public typealias Index = Int
  public typealias _Element = Element
  typealias Storage = OrderedSetStorage<Element>
  typealias Buffer = OrderedSetBuffer<Element>

  public typealias SubSequence = OrderedSetSlice<Element>

  private(set) var buffer: Buffer

  /// The current number of elements
  public var count: Int { return buffer.count }

  /// The number of elements this collection can hold without reallocating
  public var capacity: Int { return buffer.capacity }


  /// Returns a copy of the current buffer with room for `newCapacity` elements
  func cloneBuffer(newCapacity: Int) -> Buffer {

    var clone = Buffer(minimumCapacity: newCapacity)

    for position in buffer.indices {
      let bucket = buffer.bucketForPosition(position)
      let element = buffer.elementInBucket(bucket)
      clone.initializeElement(element, position: position)
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
  mutating func ensureUniqueWithCapacity(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool)
  {
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

  /// - note: Copied source from stdlib `Set`
  public var hashValue: Int {
    // FIXME: <rdar://problem/18915294> Cache Set<T> hashValue
    var result: Int = _mixInt(0)
    for member in self {
      result ^= _mixInt(member.hashValue)
    }
    return result
  }

  @warn_unused_result
  public func _customContainsEquatableElement(member: Element) -> Bool? {
    return contains(member)
  }

  @warn_unused_result
  public func _customIndexOfEquatableElement(member: Element) -> Index?? {
    return Optional(indexOf(member))
  }
  

  public func indexOf(member: Element) -> Index? { return buffer.positionForElement(member) }

  @warn_unused_result
  public func contains(member: Element) -> Bool { let (_, found) = buffer.find(member); return found }

  // MARK: Removing elements

  mutating func _remove(index: Index) {
    ensureUnique()
    buffer.destroyElementAt(index)
  }

  mutating func _removeAndReturn(index: Index) -> Element {
    let result = buffer.elementInBucket(buffer.bucketForPosition(index))
    _remove(index)
    return result
  }

  mutating func _removeAndReturn(member: Element) -> Element? {
    guard let index = buffer.positionForElement(member) else { return nil }
    return _removeAndReturn(index)
  }

  mutating func _remove(member: Element) {
    guard let index = buffer.positionForElement(member) else { return }
    _remove(index)
  }

  // MARK: Inserting elements
  mutating func _append(member: Element) {
    let (bucket, found) = buffer.find(member)
    guard !found else { return }
    ensureUniqueWithCapacity(Buffer.minimumCapacityForCount(count + 1))
    buffer.initializeElement(member, bucket: bucket)
    buffer.endIndex += 1
  }

  // MARK: Replacing elements

  mutating func _replace(index: Index, with element: Element) {
    ensureUnique()
    buffer.replaceElementAtPosition(index, with: element)
  }

}

// MARK: MutableIndexable
extension OrderedSet: MutableIndexable {

  public var startIndex: Index { return 0 }

  public var endIndex: Index { return count }

  public subscript(index: Index) -> Element {
    get { return buffer.elementAtPosition(index) }
    set { _replace(index, with: newValue) }
  }

}

// MARK: SetType
extension OrderedSet: SetType {

  public mutating func insert(member: Element) { _append(member)  }

  public mutating func remove(member: Element) -> Element? { return _removeAndReturn(member) }
  
  public init<S : SequenceType where S.Generator.Element == Element>(_ elements: S) {
    self.init(buffer: Buffer(elements: elements)) // Uniqueness checked by `Buffer`
  }

  /// Returns true if the set is a subset of a finite sequence as a `Set`.
  @warn_unused_result
  public func isSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var hitCount = 0
    for element in sequence where contains(element) {
      hitCount += 1
      guard hitCount < count else { return true }
    }
    return hitCount == count
  }
  /// Returns true if the set is a subset of a finite sequence as a `Set` but not equal.
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

  /// Returns true if the set is a superset of a finite sequence as a `Set`.
  @warn_unused_result
  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    for element in sequence { guard contains(element) else { return false } }
    return true
  }

  /// Returns true if the set is a superset of a finite sequence as a `Set` but not equal.
  @warn_unused_result
  public func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    var totalCount = 0
    for element in sequence {
      totalCount += 1
      guard contains(element) else { return false }
    }
    return totalCount < count
  }

  /// Returns true if no members in the set are in a finite sequence as a `Set`.
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

  /// Insert elements of a finite sequence into this `Set`.
  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence where !contains(element) { insert(element) }
  }

  /// Return a new set with elements in this set that do not occur in a finite sequence.
  @warn_unused_result
  public func subtract<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    switch sequence {
    case let other as OrderedSet<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    }
  }

  /// Remove all members in the set that occur in a finite sequence.
  public mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    self = subtract(sequence)
  }

  /// Return a new set with elements common to this set and a finite sequence.
  @warn_unused_result
  public func intersect<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    switch sequence {
    case let other as OrderedSet<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    }
  }

  /// Remove any members of this set that aren't also in a finite sequence.
  public mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    self = intersect(sequence)
  }

  /// Return a new set with elements that are either in the set or a finite sequence but do not occur in both.
  @warn_unused_result
  public func exclusiveOr<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    switch sequence {
    case let other as OrderedSet<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity + other.count)
      for element in self where other ∌ element { result.append(element) }
      for element in other where self ∌ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = OrderedSet<Element>(minimumCapacity: capacity + other.count)
      for element in self where other ∌ element { result.append(element) }
      for element in other where self ∌ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet<Element>(minimumCapacity: capacity + other.count)
      for element in self where other ∌ element { result.append(element) }
      for element in other where self ∌ element { result.append(element) }
      return result
    }
  }

  /// For each element of a finite sequence, remove it from the set if it is a common element, otherwise add it
  /// to the set. Repeated elements of the sequence will be ignored.
  public mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    self = exclusiveOr(sequence)
  }
}

extension OrderedSet: MutableCollectionType {
  public subscript(bounds: Range<Int>) -> SubSequence {
    get {
      return SubSequence(buffer: buffer, bounds: bounds)
    }
    set {
      replaceRange(bounds, with: newValue)
    }
  }
}

extension OrderedSet: RangeReplaceableCollectionType {

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

}

extension OrderedSet: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(buffer: Buffer(elements: elements))
  }
}

extension OrderedSet: CustomStringConvertible, CustomDebugStringConvertible {

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

  public var description: String { return elementsDescription }

  public var debugDescription: String { return elementsDescription }
}

extension OrderedSet: Equatable {}

public func == <Element:Hashable>
  (lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  
  guard !(lhs.buffer.identity == rhs.buffer.identity && lhs.count == rhs.count) else { return true }

  for (v1, v2) in zip(lhs, rhs) { guard v1 == v2 else { return false } }
  
  return true
}
