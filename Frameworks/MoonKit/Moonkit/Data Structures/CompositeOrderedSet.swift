//
//  CompositeOrderedSet.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

extension SequenceType where Self.Generator.Element:Hashable {
  private var hashValues: [Int] { return map {$0.hashValue} }
}


public struct CompositeOrderedSet<Element:Hashable>: CollectionType {

  internal typealias Base = ContiguousArray<Element>

  internal var _base: Base
  internal var _hashValues: Set<Int>

  public var count: Int { return _base.count }

  public init(minimumCapacity: Int) {
    _base = Base(minimumCapacity: minimumCapacity)
    _hashValues = Set<Int>(minimumCapacity: minimumCapacity)
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

extension CompositeOrderedSet: MutableIndexable {
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

extension CompositeOrderedSet: MutableCollectionType {

  public subscript(bounds: Range<Index>) -> SubSequence {
    get { return SubSequence(_base[bounds]) }
    set { _base[bounds] = newValue._base }
  }

}

extension CompositeOrderedSet: RangeReplaceableCollectionType {

  public init() { _base = []; _hashValues = [] }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Index>, with newElements: C)
  {
    // TODO: Revisit for performance
    var elements = Array<Element>(minimumCapacity: numericCast(newElements.count))
    for element in newElements where !elements.contains(element) { elements.append(element) }
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
    for element in newElements { append(element) }
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
    _hashValues.remove(result.hashValue)
    return result
  }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `self.count >= n`.
  public mutating func removeFirst(n: Int) {
//    precondition(_base.count >= n, "Cannot remove more items than are actually contained")
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
    var i = i
    for element in newElements {
      let hashValue = element.hashValue
      guard _hashValues ∌ hashValue else { continue }
      _base.insert(element, atIndex: i)
      _hashValues.insert(hashValue)
      i += 1
    }
  }

}


extension CompositeOrderedSet: SequenceType {
  public typealias Generator = AnyGenerator<Element>
  public typealias SubSequence = CompositeOrderedSetSlice<Element>

  public func generate() -> Generator { return AnyGenerator(_base.generate()) }
  public func dropFirst(n: Int) -> SubSequence { return CompositeOrderedSetSlice(_base.dropFirst(n)) }
  public func dropLast(n: Int) -> SubSequence { return CompositeOrderedSetSlice(_base.dropLast(n)) }
  public func prefix(maxLength: Int) -> SubSequence { return CompositeOrderedSetSlice(_base.prefix(maxLength)) }
  public func suffix(maxLength: Int) -> SubSequence { return CompositeOrderedSetSlice(_base.suffix(maxLength)) }
  public func split(maxSplit: Int,
              allowEmptySlices: Bool,
              @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    return try _base.split(maxSplit, allowEmptySlices: allowEmptySlices, isSeparator: isSeparator).map {
      CompositeOrderedSetSlice($0)
    }
  }
}

extension CompositeOrderedSet: _ArrayType {

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
  where S.Generator.Element == Element>(inout lhs: CompositeOrderedSet<Element>, rhs: S)
{
  lhs ∪= rhs
}

extension CompositeOrderedSet: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension CompositeOrderedSet: CustomStringConvertible {
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

extension CompositeOrderedSet: SetType {

  public mutating func insert(member: Element) { append(member) }

  public mutating func remove(member: Element) -> Element? {
    guard _hashValues ∋ member.hashValue else { return nil }
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
    where S.Generator.Element == Element>(sequence: S) -> CompositeOrderedSet<Element>
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
    where S.Generator.Element == Element>(sequence: S) -> CompositeOrderedSet<Element>
  {
    switch sequence {
    case let other as CompositeOrderedSet<Element>:
      var result = CompositeOrderedSet<Element>(minimumCapacity: capacity)
      for member in self where other ∌ member { result.append(member) }
      return result
    case let other as Set<Element>:
      var result = CompositeOrderedSet<Element>(minimumCapacity: capacity)
      for member in self where other ∌ member { result.append(member) }
      return result
    default:
      let other = Set(sequence)
      var result = CompositeOrderedSet<Element>(minimumCapacity: capacity)
      for member in self where other ∌ member { result.append(member) }
      return result
    }
  }

  public mutating func subtractInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    self = subtract(sequence)
  }

  public func intersect<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> CompositeOrderedSet<Element>
  {
    switch sequence {
    case let other as CompositeOrderedSet<Element>:
      var result = CompositeOrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    case let other as Set<Element>:
      var result = CompositeOrderedSet<Element>(minimumCapacity: capacity)
      for element in self where other ∋ element { result.append(element) }
      return result
    default:
      let other = Set(sequence)
      var result = CompositeOrderedSet<Element>(minimumCapacity: capacity)
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
    where S.Generator.Element == Element>(sequence: S) -> CompositeOrderedSet<Element>
  {
    switch sequence {
    case let other as CompositeOrderedSet<Element>:
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

public struct CompositeOrderedSetSlice<Element:Hashable>: CollectionType {
  public typealias Base = ArraySlice<Element>
  internal var _base: Base
  internal var _hashValues: Set<Int>
  internal init(_ base: Base) { _base = base; _hashValues = Set(_base.hashValues) }
}

extension CompositeOrderedSetSlice: CustomStringConvertible {
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

extension CompositeOrderedSetSlice: MutableIndexable {
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

extension CompositeOrderedSetSlice: MutableCollectionType {

  public subscript(bounds: Range<Int>) -> SubSequence {
    get { return SubSequence(_base[bounds]) }
    set { _base[bounds] = newValue._base }
  }

}

extension CompositeOrderedSetSlice: RangeReplaceableCollectionType {

  public init() { _base = []; _hashValues = [] }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    var elements = Array<Element>(minimumCapacity: numericCast(newElements.count))
    for element in newElements where !elements.contains(element) { elements.append(element) }
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


extension CompositeOrderedSetSlice: SequenceType {
  public typealias Generator = AnyGenerator<Element>
  public typealias SubSequence = CompositeOrderedSetSlice<Element>

  public func generate() -> Generator { return AnyGenerator(_base.generate()) }
  public func dropFirst(n: Int) -> SubSequence { return CompositeOrderedSetSlice(_base.dropFirst(n)) }
  public func dropLast(n: Int) -> SubSequence { return CompositeOrderedSetSlice(_base.dropLast(n)) }
  public func prefix(maxLength: Int) -> SubSequence { return CompositeOrderedSetSlice(_base.prefix(maxLength)) }
  public func suffix(maxLength: Int) -> SubSequence { return CompositeOrderedSetSlice(_base.suffix(maxLength)) }
  public func split(maxSplit: Int,
                    allowEmptySlices: Bool,
                    @noescape isSeparator: (Element) throws -> Bool) rethrows -> [SubSequence]
  {
    return try _base.split(maxSplit, allowEmptySlices: allowEmptySlices, isSeparator: isSeparator).map {
      SubSequence($0)
    }
  }
}

extension CompositeOrderedSetSlice: _ArrayType {

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
  where S.Generator.Element == Element>(inout lhs: CompositeOrderedSetSlice<Element>, rhs: S)
{
  lhs ∪= rhs
}

extension CompositeOrderedSetSlice: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension CompositeOrderedSetSlice: SetType {

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
    where S.Generator.Element == Element>(sequence: S) -> CompositeOrderedSetSlice<Element>
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
    where S.Generator.Element == Element>(sequence: S) -> CompositeOrderedSetSlice<Element>
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
    where S.Generator.Element == Element>(sequence: S) -> CompositeOrderedSetSlice<Element>
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
    where S.Generator.Element == Element>(sequence: S) -> CompositeOrderedSetSlice<Element>
  {
    var result = self
    result.exclusiveOrInPlace(sequence)
    return result
  }

  public mutating func exclusiveOrInPlace<S:SequenceType
    where S.Generator.Element == Element>(sequence: S)
  {
    let set = sequence as? Set<Element> ?? Set(sequence)
    var result = CompositeOrderedSetSlice<Element>(minimumCapacity: capacity + set.count)
    for element in self where !set.contains(element) { result.insert(element) }
    for element in set where !contains(element) { result.insert(element) }
    self = result
  }
  
}
