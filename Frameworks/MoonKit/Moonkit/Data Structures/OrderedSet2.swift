//
//  OrderedSet2.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/24/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

extension SequenceType where Self.Generator.Element:Hashable {
  private var hashValues: [Int] { return map {$0.hashValue} }
}

public struct OrderedSet2<Element:Hashable>: CollectionType {

  internal typealias Base = ContiguousArray<Element>

  internal var _base: Base
  internal var _hashValues: Dictionary<Int, Int>

  public var count: Int { return _base.count }

  public init(minimumCapacity: Int) {
    _base = Base(minimumCapacity: minimumCapacity)
    _hashValues = Dictionary<Int, Int>(minimumCapacity: minimumCapacity)
  }

  public init<C:CollectionType where C.Generator.Element == Element>(_ collection: C) {
    self.init(minimumCapacity: numericCast(collection.count))
    for element in collection {
      let hashValue = element.hashValue
      guard _hashValues[hashValue] == nil else { continue }
      _hashValues[hashValue] = _base.count
      _base.append(element)
    }
  }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    self.init(minimumCapacity: numericCast(sequence.underestimateCount()))
    for element in sequence {
      let hashValue = element.hashValue
      guard _hashValues[hashValue] == nil else { continue }
      _hashValues[hashValue] = _base.count
      _base.append(element)
    }
  }
  
}

extension OrderedSet2: MutableIndexable {
  public typealias Index = Base.Index
  public var startIndex: Index { return _base.startIndex }
  public var endIndex: Index { return _base.endIndex }

  public subscript(index: Index) -> Element {
    get { return _base[index] }
    set {
      let hashValue = newValue.hashValue
      guard _hashValues[hashValue] == nil else { return }
      let oldHashValue = _base[index].hashValue
      _hashValues[oldHashValue] = nil
      _hashValues[hashValue] = index
      _base[index] = newValue
    }
  }

}

extension OrderedSet2: MutableCollectionType {

  public subscript(bounds: Range<Index>) -> SubSequence {
    get { return SubSequence(_base[bounds]) }
    set { replaceRange(bounds, with: newValue) }
  }

}

extension OrderedSet2: RangeReplaceableCollectionType {

  public init() { _base = []; _hashValues = [:] }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Index>, with newElements: C)
  {
    let newElements = newElements.filter {
      guard let existingIndex = _hashValues[$0.hashValue] else { return true }
      return subRange.contains(existingIndex)
    }

    _base[subRange].hashValues.forEach { _hashValues[$0] = nil }

    newElements.hashValues.enumerate().forEach {
      _hashValues[$1] = subRange.startIndex + $0
    }

    _base.replaceRange(subRange, with: newElements)

    let delta = newElements.count - subRange.count

    guard delta != 0 && subRange.endIndex < _base.endIndex else { return }

    self[subRange.endIndex..<].enumerate().forEach {
      _hashValues[$1.hashValue] = subRange.endIndex.advancedBy($0)
    }
  }

  public mutating func append(element: Element) {
    let hashValue = element.hashValue
    guard _hashValues[hashValue] == nil else { return }
    _hashValues[hashValue] = _base.count
    _base.append(element)
  }

  /// Append the elements of `newElements` to `self`.
  ///
  /// - Complexity: O(*length of result*).
  public mutating func appendContentsOf<S : SequenceType
    where S.Generator.Element == Element>(newElements: S)
  {
    for element in newElements { append(element) }
  }

  /// Remove the element at index `i`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAtIndex(i: Int) -> Element {
    let result = _base.removeAtIndex(i)
    _hashValues[result.hashValue] = nil
    _base[i..<].enumerate().forEach { _hashValues[$1.hashValue] = $0 + i }
    return result
  }

  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  public mutating func removeFirst() -> Element {
    return removeAtIndex(0)
  }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `self.count >= n`.
  public mutating func removeFirst(n: Int) {
//    precondition(_base.count >= n, "Cannot remove more items than are actually contained")
    _base[..<n].hashValues.forEach { _hashValues[$0] = nil }
    _base.removeFirst(n)
    _base.hashValues.enumerate().forEach { _hashValues[$1.hashValue] = $0 }
  }


  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeRange(subRange: Range<Int>) {
    _base[subRange].hashValues.forEach { _hashValues[$0] = nil }
    _base.removeRange(subRange)
    _base[subRange.startIndex..<].enumerate().forEach { _hashValues[$1.hashValue] = $0 + subRange.startIndex }
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
    var hashValuesCopy = Dictionary<Int, Int>(minimumCapacity: minimumCapacity)
    for (k, v) in _hashValues { hashValuesCopy[k] = v }
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
    guard _hashValues[hashValue] == nil else { return }
    _hashValues[hashValue] = i

    _base[i..<].enumerate().forEach {
      _hashValues[$1.hashValue] = $0 + 1
    }
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
    let newElements = newElements.filter { _hashValues[$0.hashValue] == nil }

    let offset = newElements.count + i

    _base[i..<].enumerate().forEach { _hashValues[$1.hashValue] = $0 + offset }

    newElements.enumerate().forEach { _hashValues[$1.hashValue] = $0 + i }

    _base.insertContentsOf(newElements, at: i)
  }

}


extension OrderedSet2: SequenceType {
  public typealias Generator = AnyGenerator<Element>
  public typealias SubSequence = OrderedSet2<Element>

  public func generate() -> Generator { return AnyGenerator(_base.generate()) }
  public func dropFirst(n: Int) -> SubSequence { return OrderedSet2(_base.dropFirst(n)) }
  public func dropLast(n: Int) -> SubSequence { return OrderedSet2(_base.dropLast(n)) }
  public func prefix(maxLength: Int) -> SubSequence { return OrderedSet2(_base.prefix(maxLength)) }
  public func suffix(maxLength: Int) -> SubSequence { return OrderedSet2(_base.suffix(maxLength)) }
  public func split(maxSplit: Int,
              allowEmptySlices: Bool,
              @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    return try _base.split(maxSplit, allowEmptySlices: allowEmptySlices, isSeparator: isSeparator).map {
      OrderedSet2($0)
    }
  }
}

extension OrderedSet2: _ArrayType {

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
    _hashValues = [repeatedValue.hashValue: 0]
  }

  public init(_ buffer: _Buffer) {
    self.init()
    appendContentsOf(Base(buffer))
  }

}


/// Operator form of `appendContentsOf`.
public func +=<Element, S: SequenceType
  where S.Generator.Element == Element>(inout lhs: OrderedSet2<Element>, rhs: S)
{
  lhs ∪= rhs
}

extension OrderedSet2: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension OrderedSet2: CustomStringConvertible {
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

extension OrderedSet2: SetType {

  public mutating func insert(member: Element) { append(member) }

  public mutating func remove(member: Element) -> Element? {
    guard let index = _hashValues[member.hashValue] else { return nil }
    return removeAtIndex(index)
  }

  public func contains(element: Element) -> Bool { return _hashValues[element.hashValue] != nil }

  public func isSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return Set(_hashValues.keys).isSubsetOf(sequence.hashValues)
  }

  public func isStrictSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return Set(_hashValues.keys).isStrictSubsetOf(sequence.hashValues)
  }

  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return Set(_hashValues.keys).isSupersetOf(sequence.hashValues)
  }

  public func isStrictSupersetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return Set(_hashValues.keys).isStrictSupersetOf(sequence.hashValues)
  }

  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return Set(_hashValues.keys).isDisjointWith(sequence.hashValues)
  }

  public func union<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet2<Element>
  {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    appendContentsOf(sequence)
  }

  public func subtract<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet2<Element>
  {
    switch sequence {
    case let other as OrderedSet2<Element>:
      var result = OrderedSet2<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = OrderedSet2<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet2<Element>(minimumCapacity: capacity)
      for element in self where other ∌ element { result.append(element) }
      return result
    }
  }

  public mutating func subtractInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    self = subtract(sequence)
  }

  public func intersect<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet2<Element>
  {
    switch sequence {
    case let other as OrderedSet2<Element>:
      var result = OrderedSet2<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = OrderedSet2<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = OrderedSet2<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    }
  }

  public mutating func intersectInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    self = intersect(sequence)
  }

  public func exclusiveOr<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet2<Element>
  {
    switch sequence {
    case let other as OrderedSet2<Element>:
      let common = intersect(other)
      let uniqueSelf = subtract(common)
      let uniqueOther = other.subtract(common)
      return uniqueSelf.union(uniqueOther)
    case let other as Set<Element>:
      let common = intersect(other)
      let uniqueSelf = subtract(common)
      let uniqueOther = other.subtract(common)
      return uniqueSelf.union(uniqueOther)
    default:
      let other = Set(sequence)
      let common = intersect(other)
      let uniqueSelf = subtract(common)
      let uniqueOther = other.subtract(common)
      return uniqueSelf.union(uniqueOther)
    }
  }

  public mutating func exclusiveOrInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    self = exclusiveOr(sequence)
  }

}

