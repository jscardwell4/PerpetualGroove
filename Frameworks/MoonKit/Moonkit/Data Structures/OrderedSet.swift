//
//  OrderedSet.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public struct OrderedSetSlice<Element:Hashable>: CollectionType {
  public typealias Index = Int
  public let startIndex: Int
  public let endIndex: Int
  private let _base: ArraySlice<Element>
  public subscript(position: Index) -> Element { return _base[position] }
  private init(_ base: ArraySlice<Element>) {
    startIndex = base.startIndex
    endIndex = base.endIndex
    _base = base
  }
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
}


public struct OrderedSet<Element:Hashable>: CollectionType {

  private typealias Base = ContiguousArray<Element>
  private var _base: Base

  private var hashValues: Set<Int>

  public var count: Int { return _base.count }

  /**
   initWithMinimumCapacity:

   - parameter minimumCapacity: Int
   */
  public init(minimumCapacity: Int) {
    _base = []
    _base.reserveCapacity(minimumCapacity)
    hashValues = Set<Int>(minimumCapacity: minimumCapacity)
  }

  /**
   init:

   - parameter collection: C
   */
  public init<C:CollectionType where C.Generator.Element == Element>(_ collection: C) {
    self.init(minimumCapacity: numericCast(collection.count))
    for element in collection {
      let hashValue = element.hashValue
      guard hashValues ∌ hashValue else { continue }
      _base.append(element)
      hashValues.insert(hashValue)
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
      guard hashValues ∌ hashValue else { continue }
      _base.append(element)
      hashValues.insert(hashValue)
    }
  }
  
}

extension OrderedSet: MutableIndexable {
  public typealias Index = Int
  public var startIndex: Int { return _base.startIndex }
  public var endIndex: Int { return _base.endIndex }

  /**
   subscript:

   - parameter index: Int

    - returns: Element
  */
  public subscript(index: Int) -> Element {
    get { return _base[index] }
    set {
      let hashValue = newValue.hashValue
      guard hashValues ∌ hashValue else { return }
      hashValues.remove(_base[index].hashValue)
      hashValues.insert(hashValue)
      _base[index] = newValue
    }
  }

}

extension OrderedSet: MutableCollectionType {

  public subscript(bounds: Range<Int>) -> SubSequence {
    get { return OrderedSetSlice(_base[bounds]) }
    set { _base[bounds] = newValue._base }
  }

}

extension OrderedSet: RangeReplaceableCollectionType {

  /** init */
  public init() { _base = []; hashValues = [] }

  /**
   replaceRange:with:

   - parameter subRange: Range<Int>
   - parameter newElements: C
  */
  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element>(subRange: Range<Int>, with newElements: C)
  {
    var elements: [Element] = []
    elements.reserveCapacity(numericCast(newElements.count))
    for element in newElements {
      guard elements ∌ element else { continue }
      elements.append(element)
    }
    hashValues.subtractInPlace(_base[subRange].map({$0.hashValue}))
    _base.replaceRange(subRange, with: elements)
    hashValues.unionInPlace(elements.map({$0.hashValue}))
  }

  public mutating func append(element: Element) {
    let hashValue = element.hashValue
    guard hashValues ∌ hashValue else { return }
    hashValues.insert(hashValue)

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
      guard hashValues ∌ hashValue else { continue }
      hashValues.insert(hashValue)
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
    hashValues.remove(result.hashValue)
    return result
  }

  /// Remove the element at `startIndex` and return it.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `!self.isEmpty`.
  public mutating func removeFirst() -> Element {
    let result = _base.removeFirst()
    assert(hashValues ∌ result.hashValue)
    return result
  }

  /// Remove the first `n` elements.
  ///
  /// - Complexity: O(`self.count`)
  /// - Requires: `self.count >= n`.
  public mutating func removeFirst(n: Int) {
    precondition(_base.count >= n, "Cannot remove more items than are actually contained")
    hashValues.subtractInPlace(_base[..<n].map({$0.hashValue}))
    _base.removeFirst(n)
  }


  /// Remove the indicated `subRange` of elements.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeRange(subRange: Range<Int>) {
    hashValues.subtractInPlace(_base[subRange].map({$0.hashValue}))
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
    hashValues.removeAll(keepCapacity: keepCapacity)
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
    hashValuesCopy.unionInPlace(hashValues)
    hashValues = hashValuesCopy
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
    guard hashValues ∌ hashValue else { return }
    hashValues.insert(hashValue)
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
      guard hashValues ∌ hashValue else { continue }
      hashValues.insert(hashValue)
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

  public private(set) var _buffer: _Buffer {
    get { return _base._buffer }
    set { _base._buffer = newValue }
  }

  public init(count: Int, repeatedValue: Element) {
    _base = [repeatedValue]
    hashValues = [repeatedValue.hashValue]
  }

  /**
   init:

   - parameter buffer: ContiguousArray<Element>._Buffer
  */
  public init(_ buffer: _Buffer) {
    self.init()
    let base = Base(buffer)
    for element in base {
      let hashValue = element.hashValue
      guard hashValues ∌ hashValue else { continue }
      hashValues.insert(hashValue)
      _base.append(element)
    }
  }

}


/// Operator form of `appendContentsOf`.
public func +=<Element, S: SequenceType
  where S.Generator.Element == Element>(inout lhs: OrderedSet<Element>, rhs: S)
{
  for element in rhs {
    let hashValue = element.hashValue
    guard lhs.hashValues ∌ hashValue else { continue }
    lhs.hashValues.insert(hashValue)
    lhs._base.append(element)
  }
}

extension OrderedSet: ArrayLiteralConvertible {
  /**
   init:

   - parameter elements: Element...
   */
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

  public mutating func insert(member: Element) {
    append(member)
  }

  public mutating func remove(member: Element) -> Element? {
    let hashValue = member.hashValue
    guard hashValues.remove(hashValue) != nil,
      let idx = _base.indexOf(member) else { return nil }
    return _base.removeAtIndex(idx)
  }

  public func contains(element: Element) -> Bool { return hashValues ∋ element.hashValue }

  public func isSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return hashValues.isSubsetOf(Set(sequence.map{$0.hashValue}))
  }

  public func isStrictSubsetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return hashValues.isStrictSubsetOf(Set(sequence.map{$0.hashValue}))
  }

  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return hashValues.isSupersetOf(Set(sequence.map{$0.hashValue}))
  }

  public func isStrictSupersetOf<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return hashValues.isStrictSupersetOf(Set(sequence.map{$0.hashValue}))
  }

  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return hashValues.isDisjointWith(Set(sequence.map{$0.hashValue}))
  }

  public func union<S:SequenceType
    where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element>
  {
    var result = self
    result.unionInPlace(sequence)
    return result
  }

  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for element in sequence where hashValues ∌ element.hashValue { append(element) }
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
    for element in sequence where hashValues ∋ element.hashValue { remove(element) }
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
    let elements = Set(sequence)
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
    for element in sequence {
      if hashValues ∋ element.hashValue { remove(element) } else { insert(element) }
    }
  }

}

// contains
public func ∈<Element:Hashable>(lhs: Element, rhs: OrderedSet<Element>) -> Bool {
  return rhs.contains(lhs)
}
public func ∋<Element:Hashable>(lhs: OrderedSet<Element>, rhs: Element) -> Bool {
  return lhs.contains(rhs)
}

public func ∉<Element:Hashable>(lhs: Element, rhs: OrderedSet<Element>) -> Bool { return !(lhs ∈ rhs) }
public func ∌<Element:Hashable>(lhs: OrderedSet<Element>, rhs: Element) -> Bool { return !(lhs ∋ rhs) }

// subset/superset
public func ⊂<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return lhs.isStrictSubsetOf(rhs)
}
public func ⊃<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return lhs.isStrictSupersetOf(rhs)
}
public func ⊆<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return lhs.isSubsetOf(rhs)
}
public func ⊇<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return lhs.isSupersetOf(rhs)
}
public func ⊄<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return !(lhs ⊂ rhs)
}
public func ⊅<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return !(lhs ⊃ rhs)
}
public func ⊈<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return !(lhs ⊆ rhs)
}
public func ⊉<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return !(lhs ⊇ rhs)
}

// union
public func ∪<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> OrderedSet<Element>
{
  return lhs.union(rhs)
}
public func ∪=<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(inout lhs: OrderedSet<Element>, rhs: S)
{
  lhs.unionInPlace(rhs)
}

// minus
public func ∖<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> OrderedSet<Element>
{
  return lhs.subtract(rhs)
}
public func ∖=<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(inout lhs: OrderedSet<Element>, rhs: S)
{
  lhs.subtractInPlace(rhs)
}

// intersect
public func ∩<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> OrderedSet<Element>
{
  return lhs.intersect(rhs)
}
public func ∩=<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(inout lhs: OrderedSet<Element>, rhs: S)
{
  lhs.intersectInPlace(rhs)
}

// xor
public func ⊻<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> OrderedSet<Element>
{
  return lhs.exclusiveOr(rhs)
}
public func ⊻=<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(inout lhs: OrderedSet<Element>, rhs: S)
{
  lhs.exclusiveOrInPlace(rhs)
}

// disjoint
public func !⚭<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return lhs.isDisjointWith(rhs)
}
public func ⚭<S:SequenceType, Element:Hashable
  where S.Generator.Element == Element>(lhs: OrderedSet<Element>, rhs: S) -> Bool
{
  return !(lhs ⚭ rhs)
}

// subset/superset
public func ⊂<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return lhs.hashValues ⊂ rhs.hashValues
}
public func ⊃<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return lhs.hashValues ⊃ rhs.hashValues
}
public func ⊆<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return lhs.hashValues ⊆ rhs.hashValues
}
public func ⊇<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return lhs.hashValues ⊇ rhs.hashValues
}
public func ⊄<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return !(lhs ⊂ rhs)
}
public func ⊅<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return !(lhs ⊃ rhs)
}
public func ⊈<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return !(lhs ⊆ rhs)
}
public func ⊉<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return !(lhs ⊇ rhs)
}

// union
public func ∪<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> OrderedSet<Element>
{
  return lhs.union(rhs)
}
public func ∪=<Element:Hashable>(inout lhs: OrderedSet<Element>, rhs: OrderedSet<Element>)
{
  lhs.unionInPlace(rhs)
}

// minus
public func ∖<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> OrderedSet<Element>
{
  return lhs.subtract(rhs)
}
public func ∖=<Element:Hashable>(inout lhs: OrderedSet<Element>, rhs: OrderedSet<Element>)
{
  lhs.subtractInPlace(rhs)
}

// intersect
public func ∩<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> OrderedSet<Element>
{
  return lhs.intersect(rhs)
}
public func ∩=<Element:Hashable>(inout lhs: OrderedSet<Element>, rhs: OrderedSet<Element>)
{
  lhs.intersectInPlace(rhs)
}

// xor
public func ⊻<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> OrderedSet<Element>
{
  return lhs.exclusiveOr(rhs)
}
public func ⊻=<Element:Hashable>(inout lhs: OrderedSet<Element>, rhs: OrderedSet<Element>)
{
  lhs.exclusiveOrInPlace(rhs)
}

// disjoint
public func !⚭<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return lhs.isDisjointWith(rhs)
}
public func ⚭<Element:Hashable>(lhs: OrderedSet<Element>, rhs: OrderedSet<Element>) -> Bool
{
  return !lhs.isDisjointWith(rhs)
  
}