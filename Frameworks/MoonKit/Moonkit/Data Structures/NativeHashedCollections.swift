//
//  NativeHashedCollections.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/24/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation
import SwiftShims

/// This protocol is only used for compile-time checks that
/// every storage type implements all required operations.
internal protocol _HashStorageType {
  associatedtype Key
  associatedtype Value
  associatedtype Index
  associatedtype SequenceElement
  var startIndex: Index { get }
  var endIndex: Index { get }

  @warn_unused_result
  func indexForKey(key: Key) -> Index?

  @warn_unused_result
  func assertingGet(i: Index) -> SequenceElement

  @warn_unused_result
  func assertingGet(key: Key) -> Value

  @warn_unused_result
  func maybeGet(key: Key) -> Value?

  mutating func updateValue(value: Value, forKey: Key) -> Value?
  mutating func removeAtIndex(index: Index) -> SequenceElement
  mutating func removeValueForKey(key: Key) -> Value?
  mutating func removeAll(keepCapacity keepCapacity: Bool)
  var count: Int { get }

  @warn_unused_result
  static func fromArray(elements: [SequenceElement]) -> Self
}

/// The inverse of the default hash table load factor.  Factored out so that it
/// can be used in multiple places in the implementation and stay consistent.
/// Should not be used outside `NativeDictionary` implementation.
@_transparent
internal var _hashContainerDefaultMaxLoadFactorInverse: Double {
  return 1.0 / 0.75
}


/// A collection of unique `Element` instances with no defined ordering.
public struct NativeSet<Element : Hashable> :
Hashable, CollectionType, ArrayLiteralConvertible {

  internal typealias _Self = NativeSet<Element>
  internal typealias _VariantStorage = _VariantSetStorage<Element>
  internal typealias _NativeStorage = _NativeSetStorage<Element>
  public typealias Index = SetIndex<Element>

  internal var _variantStorage: _VariantStorage

  /// Create an empty set with at least the given number of
  /// elements worth of storage.  The actual capacity will be the
  /// smallest power of 2 that's >= `minimumCapacity`.
  public init(minimumCapacity: Int) {
    _variantStorage =
      _VariantStorage.Native(
        _NativeStorage.Owner(minimumCapacity: minimumCapacity))
  }

  /// Private initializer.
  internal init(_nativeStorage: _NativeSetStorage<Element>) {
    _variantStorage = _VariantStorage.Native(
      _NativeStorage.Owner(nativeStorage: _nativeStorage))
  }

  /// Private initializer.
  internal init(_nativeStorageOwner: _NativeSetStorageOwner<Element>) {
    _variantStorage = .Native(_nativeStorageOwner)
  }

  /// The position of the first element in a non-empty set.
  ///
  /// This is identical to `endIndex` in an empty set.
  ///
  /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
  ///   `NSSet`, O(N) otherwise.
  public var startIndex: Index {
    return _variantStorage.startIndex
  }

  /// The collection's "past the end" position.
  ///
  /// `endIndex` is not a valid argument to `subscript`, and is always
  /// reachable from `startIndex` by zero or more applications of
  /// `successor()`.
  ///
  /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
  ///   `NSSet`, O(N) otherwise.
  public var endIndex: Index {
    return _variantStorage.endIndex
  }

  /// Returns `true` if the set contains a member.
  @warn_unused_result
  public func contains(member: Element) -> Bool {
    return _variantStorage.maybeGet(member) != nil
  }

  /// Returns the `Index` of a given member, or `nil` if the member is not
  /// present in the set.
  @warn_unused_result
  public func indexOf(member: Element) -> Index? {
    return _variantStorage.indexForKey(member)
  }

  /// Insert a member into the set.
  public mutating func insert(member: Element) {
    _variantStorage.updateValue(member, forKey: member)
  }

  /// Remove the member from the set and return it if it was present.
  public mutating func remove(member: Element) -> Element? {
    return _variantStorage.removeValueForKey(member)
  }

  /// Remove the member referenced by the given index.
  public mutating func removeAtIndex(index: Index) -> Element {
    return _variantStorage.removeAtIndex(index)
  }

  /// Erase all the elements.  If `keepCapacity` is `true`, `capacity`
  /// will not decrease.
  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    _variantStorage.removeAll(keepCapacity: keepCapacity)
  }

  /// Remove a member from the set and return it.
  ///
  /// - Requires: `count > 0`.
  public mutating func removeFirst() -> Element {
    _precondition(count > 0, "can't removeFirst from an empty NativeSet")
    let member = first!
    remove(member)
    return member
  }

  /// The number of members in the set.
  ///
  /// - Complexity: O(1).
  public var count: Int {
    return _variantStorage.count
  }

  //
  // `SequenceType` conformance
  //

  /// Access the member at `position`.
  ///
  /// - Complexity: O(1).
  public subscript(position: Index) -> Element {
    return _variantStorage.assertingGet(position)
  }

  /// Returns a generator over the members.
  ///
  /// - Complexity: O(1).
  public func generate() -> SetGenerator<Element> {
    return _variantStorage.generate()
  }

  //
  // `ArrayLiteralConvertible` conformance
  //
  public init(arrayLiteral elements: Element...) {
    self.init(_nativeStorage: _NativeSetStorage.fromArray(elements))
  }

  //
  // APIs below this comment should be implemented strictly in terms of
  // *public* APIs above.  `_variantStorage` should not be accessed directly.
  //
  // This separates concerns for testing.  Tests for the following APIs need
  // not to concern themselves with testing correctness of behavior of
  // underlying storage (and different variants of it), only correctness of the
  // API itself.
  //

  /// Create an empty `NativeSet`.
  public init() {
    self = NativeSet<Element>(minimumCapacity: 0)
  }

  /// Create a `NativeSet` from a finite sequence of items.
  public init<S : SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    self.init()
    if let s = sequence as? NativeSet<Element> {
      // If this sequence is actually a native `NativeSet`, then we can quickly
      // adopt its native storage and let COW handle uniquing only
      // if necessary.
      switch (s._variantStorage) {
      case .Native(let owner):
        _variantStorage = .Native(owner)
      }
    } else {
      for item in sequence {
        insert(item)
      }
    }
  }

  /// Returns `true` if the set is a subset of a finite sequence as a `NativeSet`.
  @warn_unused_result
  public func isSubsetOf<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> Bool {
    let other = sequence as? NativeSet<Element> ?? NativeSet(sequence)
    let (isSubset, isEqual) = _compareSets(self, other)
    return isSubset || isEqual
  }

  /// Returns `true` if the set is a subset of a finite sequence as a `NativeSet`
  /// but not equal.
  @warn_unused_result
  public func isStrictSubsetOf<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> Bool {
    let other = sequence as? NativeSet<Element> ?? NativeSet(sequence)
    let (isSubset, isEqual) = _compareSets(self, other)
    return isSubset && !isEqual
  }

  /// Returns `true` if the set is a superset of a finite sequence as a `NativeSet`.
  @warn_unused_result
  public func isSupersetOf<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> Bool {
    let other = sequence as? NativeSet<Element> ?? NativeSet(sequence)
    return other.isSubsetOf(self)
  }

  /// Returns `true` if the set is a superset of a finite sequence as a `NativeSet`
  /// but not equal.
  @warn_unused_result
  public func isStrictSupersetOf<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> Bool {
    let other = sequence as? NativeSet<Element> ?? NativeSet(sequence)
    return other.isStrictSubsetOf(self)
  }

  /// Returns `true` if no members in the set are in a finite sequence as a `NativeSet`.
  @warn_unused_result
  public func isDisjointWith<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> Bool {
    let other = sequence as? NativeSet<Element> ?? NativeSet(sequence)
    for member in self {
      if other.contains(member) {
        return false
      }
    }
    return true
  }

  /// Returns a new `NativeSet` with items in both this set and a finite sequence.
  @warn_unused_result
  public func union<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> NativeSet<Element> {
    var newSet = self
    newSet.unionInPlace(sequence)
    return newSet
  }

  /// Inserts elements of a finite sequence into this `NativeSet`.
  public mutating func unionInPlace<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) {
    for item in sequence {
      insert(item)
    }
  }

  /// Returns a new set with elements in this set that do not occur
  /// in a finite sequence.
  @warn_unused_result
  public func subtract<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> NativeSet<Element> {
    var newSet = self
    newSet.subtractInPlace(sequence)
    return newSet
  }

  /// Removes all members in the set that occur in a finite sequence.
  public mutating func subtractInPlace<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) {
    for item in sequence {
      remove(item)
    }
  }

  /// Returns a new set with elements common to this set and a finite sequence.
  @warn_unused_result
  public func intersect<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> NativeSet<Element> {
    let other = sequence as? NativeSet<Element> ?? NativeSet(sequence)
    var newSet = NativeSet<Element>()
    for member in self {
      if other.contains(member) {
        newSet.insert(member)
      }
    }
    return newSet
  }

  /// Removes any members of this set that aren't also in a finite sequence.
  public mutating func intersectInPlace<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) {
    // Because `intersect` needs to both modify and iterate over
    // the left-hand side, the index may become invalidated during
    // traversal so an intermediate set must be created.
    //
    // FIXME(performance): perform this operation at a lower level
    // to avoid invalidating the index and avoiding a copy.
    let result = self.intersect(sequence)

    // The result can only have fewer or the same number of elements.
    // If no elements were removed, don't perform a reassignment
    // as this may cause an unnecessary uniquing COW.
    if result.count != count {
      self = result
    }
  }

  /// Returns a new set with elements that are either in the set or a finite
  /// sequence but do not occur in both.
  @warn_unused_result
  public func exclusiveOr<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) -> NativeSet<Element> {
    var newSet = self
    newSet.exclusiveOrInPlace(sequence)
    return newSet
  }

  /// For each element of a finite sequence, removes it from the set if it is a
  /// common element, otherwise adds it to the set. Repeated elements of the
  /// sequence will be ignored.
  public mutating func exclusiveOrInPlace<
    S : SequenceType where S.Generator.Element == Element
    >(sequence: S) {
    let other = sequence as? NativeSet<Element> ?? NativeSet(sequence)
    for member in other {
      if contains(member) {
        remove(member)
      } else {
        insert(member)
      }
    }
  }

  public var hashValue: Int {
    // FIXME: <rdar://problem/18915294> Cache NativeSet<T> hashValue
    var result: Int = _mixInt(0)
    for member in self {
      result ^= _mixInt(member.hashValue)
    }
    return result
  }

  //
  // `SequenceType` conformance
  //

  @warn_unused_result
  public func _customContainsEquatableElement(member: Element) -> Bool? {
    return contains(member)
  }

  @warn_unused_result
  public func _customIndexOfEquatableElement(member: Element) -> Index?? {
    return Optional(indexOf(member))
  }

  //
  // CollectionType conformance
  //

  /// `true` if the set is empty.
  public var isEmpty: Bool {
    return count == 0
  }

  /// The first element obtained when iterating, or `nil` if `self` is
  /// empty.  Equivalent to `self.generate().next()`.
  public var first: Element? {
    return count > 0 ? self[startIndex] : nil
  }
}

/// Check for both subset and equality relationship between
/// a set and some sequence (which may itself be a `NativeSet`).
///
/// (isSubset: lhs ⊂ rhs, isEqual: lhs ⊂ rhs and |lhs| = |rhs|)
@warn_unused_result
internal func _compareSets<Element>(lhs: NativeSet<Element>, _ rhs: NativeSet<Element>)
  -> (isSubset: Bool, isEqual: Bool) {
    for member in lhs {
      if !rhs.contains(member) {
        return (false, false)
      }
    }
    return (true, lhs.count == rhs.count)
}

@warn_unused_result
public func == <Element : Hashable>(lhs: NativeSet<Element>, rhs: NativeSet<Element>) -> Bool {
  switch (lhs._variantStorage, rhs._variantStorage) {
  case (.Native(let lhsNativeOwner), .Native(let rhsNativeOwner)):
    let lhsNative = lhsNativeOwner.nativeStorage
    let rhsNative = rhsNativeOwner.nativeStorage

    if lhsNativeOwner === rhsNativeOwner {
      return true
    }

    if lhsNative.count != rhsNative.count {
      return false
    }

    for member in lhs {
      let (_, found) = rhsNative._find(member, rhsNative._bucket(member))
      if !found {
        return false
      }
    }
    return true
  }
}

extension NativeSet: SetType {
  public mutating func reserveCapacity(capacity: Int) {
    // TODO: Implement this or rething `SetType` protocol
  }
}


extension NativeSet : CustomStringConvertible, CustomDebugStringConvertible {
  @warn_unused_result
  private func makeDescription(isDebug isDebug: Bool) -> String {
    var result = isDebug ? "NativeSet([" : "["
    var first = true
    for member in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(member, terminator: "", toStream: &result)
    }
    result += isDebug ? "])" : "]"
    return result
  }

  /// A textual representation of `self`.
  public var description: String {
    return makeDescription(isDebug: false)
  }

  /// A textual representation of `self`, suitable for debugging.
  public var debugDescription: String {
    return makeDescription(isDebug: true)
  }
}

/// A hash-based mapping from `Key` to `Value` instances.  Also a
/// collection of key-value pairs with no defined ordering.
public struct NativeDictionary<Key : Hashable, Value> :
CollectionType, DictionaryLiteralConvertible {

  internal typealias _Self = NativeDictionary<Key, Value>
  internal typealias _VariantStorage = _VariantDictionaryStorage<Key, Value>
  internal typealias _NativeStorage = _NativeDictionaryStorage<Key, Value>
  public typealias Element = (Key, Value)
  public typealias Index = DictionaryIndex<Key, Value>

  internal var _variantStorage: _VariantStorage

  /// Create an empty dictionary.
  public init() {
    self = NativeDictionary<Key, Value>(minimumCapacity: 0)
  }

  /// Create a dictionary with at least the given number of
  /// elements worth of storage.  The actual capacity will be the
  /// smallest power of 2 that's >= `minimumCapacity`.
  public init(minimumCapacity: Int) {
    _variantStorage =
      .Native(_NativeStorage.Owner(minimumCapacity: minimumCapacity))
  }

  /// Private initializer.
  internal init(_nativeStorage: _NativeDictionaryStorage<Key, Value>) {
    _variantStorage =
      .Native(_NativeStorage.Owner(nativeStorage: _nativeStorage))
  }

  /// Private initializer.
  internal init(_nativeStorageOwner:
    _NativeDictionaryStorageOwner<Key, Value>) {
    _variantStorage = .Native(_nativeStorageOwner)
  }

  /// The position of the first element in a non-empty dictionary.
  ///
  /// Identical to `endIndex` in an empty dictionary.
  ///
  /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
  ///   `NSDictionary`, O(N) otherwise.
  public var startIndex: Index {
    return _variantStorage.startIndex
  }

  /// The collection's "past the end" position.
  ///
  /// `endIndex` is not a valid argument to `subscript`, and is always
  /// reachable from `startIndex` by zero or more applications of
  /// `successor()`.
  ///
  /// - Complexity: Amortized O(1) if `self` does not wrap a bridged
  ///   `NSDictionary`, O(N) otherwise.
  public var endIndex: Index {
    return _variantStorage.endIndex
  }

  /// Returns the `Index` for the given key, or `nil` if the key is not
  /// present in the dictionary.
  @warn_unused_result
  public func indexForKey(key: Key) -> Index? {
    // Complexity: amortized O(1) for native storage, O(N) when wrapping an
    // NSDictionary.
    return _variantStorage.indexForKey(key)
  }

  /// Access the key-value pair at `position`.
  ///
  /// - Complexity: O(1).
  public subscript(position: Index) -> Element {
    return _variantStorage.assertingGet(position)
  }

  /// Access the value associated with the given key.
  ///
  /// Reading a key that is not present in `self` yields `nil`.
  /// Writing `nil` as the value for a given key erases that key from
  /// `self`.
  public subscript(key: Key) -> Value? {
    get {
      return _variantStorage.maybeGet(key)
    }
    set(newValue) {
      if let x = newValue {
        // FIXME(performance): this loads and discards the old value.
        _variantStorage.updateValue(x, forKey: key)
      }
      else {
        // FIXME(performance): this loads and discards the old value.
        removeValueForKey(key)
      }
    }
  }

  /// Update the value stored in the dictionary for the given key, or, if the
  /// key does not exist, add a new key-value pair to the dictionary.
  ///
  /// Returns the value that was replaced, or `nil` if a new key-value pair
  /// was added.
  public mutating func updateValue(
    value: Value, forKey key: Key
    ) -> Value? {
    return _variantStorage.updateValue(value, forKey: key)
  }

  /// Remove the key-value pair at `index`.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - Complexity: O(`self.count`).
  public mutating func removeAtIndex(index: Index) -> Element {
    return _variantStorage.removeAtIndex(index)
  }

  /// Remove a given key and the associated value from the dictionary.
  /// Returns the value that was removed, or `nil` if the key was not present
  /// in the dictionary.
  public mutating func removeValueForKey(key: Key) -> Value? {
    return _variantStorage.removeValueForKey(key)
  }

  /// Removes all elements.
  ///
  /// - Postcondition: `capacity == 0` if `keepCapacity` is `false`, otherwise
  ///   the capacity will not be decreased.
  ///
  /// Invalidates all indices with respect to `self`.
  ///
  /// - parameter keepCapacity: If `true`, the operation preserves the
  ///   storage capacity that the collection has, otherwise the underlying
  ///   storage is released.  The default is `false`.
  ///
  /// Complexity: O(`self.count`).
  public mutating func removeAll(keepCapacity keepCapacity: Bool = false) {
    // The 'will not decrease' part in the documentation comment is worded very
    // carefully.  The capacity can increase if we replace Cocoa storage with
    // native storage.
    _variantStorage.removeAll(keepCapacity: keepCapacity)
  }

  /// The number of entries in the dictionary.
  ///
  /// - Complexity: O(1).
  public var count: Int {
    return _variantStorage.count
  }

  //
  // `SequenceType` conformance
  //

  /// Returns a generator over the (key, value) pairs.
  ///
  /// - Complexity: O(1).
  public func generate() -> DictionaryGenerator<Key, Value> {
    return _variantStorage.generate()
  }

  //
  // DictionaryLiteralConvertible conformance
  //

  /// Create an instance initialized with `elements`.
  @effects(readonly)
  public init(dictionaryLiteral elements: (Key, Value)...) {
    self.init(_nativeStorage: _NativeDictionaryStorage.fromArray(elements))
  }

  /// A collection containing just the keys of `self`.
  ///
  /// Keys appear in the same order as they occur as the `.0` member
  /// of key-value pairs in `self`.  Each key in the result has a
  /// unique value.
  public var keys: LazyMapCollection<NativeDictionary, Key> {
    return self.lazy.map { $0.0 }
  }

  /// A collection containing just the values of `self`.
  ///
  /// Values appear in the same order as they occur as the `.1` member
  /// of key-value pairs in `self`.
  public var values: LazyMapCollection<NativeDictionary, Value> {
    return self.lazy.map { $0.1 }
  }

  //
  // CollectionType conformance
  //

  /// `true` iff `count == 0`.
  public var isEmpty: Bool {
    return count == 0
  }

}

@warn_unused_result
public func == <Key : Equatable, Value : Equatable>(
  lhs: NativeDictionary<Key, Value>,
  rhs: NativeDictionary<Key, Value>
  ) -> Bool {
  switch (lhs._variantStorage, rhs._variantStorage) {
  case (.Native(let lhsNativeOwner), .Native(let rhsNativeOwner)):
    let lhsNative = lhsNativeOwner.nativeStorage
    let rhsNative = rhsNativeOwner.nativeStorage

    if lhsNativeOwner === rhsNativeOwner {
      return true
    }

    if lhsNative.count != rhsNative.count {
      return false
    }

    for (k, v) in lhs {
      let (pos, found) = rhsNative._find(k, rhsNative._bucket(k))
      // FIXME: Can't write the simple code pending
      // <rdar://problem/15484639> Refcounting bug
      /*
       if !found || rhs[pos].value != lhsElement.value {
       return false
       }
       */
      if !found {
        return false
      }
      if rhsNative.valueAt(pos.offset) != v {
        return false
      }
    }
    return true
  }
}

@warn_unused_result
public func != <Key : Equatable, Value : Equatable>(
  lhs: NativeDictionary<Key, Value>,
  rhs: NativeDictionary<Key, Value>
  ) -> Bool {
  return !(lhs == rhs)
}

extension NativeDictionary : CustomStringConvertible, CustomDebugStringConvertible {
  @warn_unused_result
  internal func _makeDescription() -> String {
    if count == 0 {
      return "[:]"
    }

    var result = "["
    var first = true
    for (k, v) in self {
      if first {
        first = false
      } else {
        result += ", "
      }
      debugPrint(k, terminator: "", toStream: &result)
      result += ": "
      debugPrint(v, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }

  /// A textual representation of `self`.
  public var description: String {
    return _makeDescription()
  }

  /// A textual representation of `self`, suitable for debugging.
  public var debugDescription: String {
    return _makeDescription()
  }
}

/// A wrapper around a bitmap storage with room for at least bitCount bits.
internal struct _BitMap {
  internal let values: UnsafeMutablePointer<UInt>
  internal let bitCount: Int

  // Note: We use UInt here to get unsigned math (shifts).
  @warn_unused_result
  internal static func wordIndex(i: UInt) -> UInt {
    return i / UInt._sizeInBits
  }

  @warn_unused_result
  internal static func bitIndex(i: UInt) -> UInt {
    return i % UInt._sizeInBits
  }

  @warn_unused_result
  internal static func wordsFor(bitCount: Int) -> Int {
    return bitCount + Int._sizeInBytes - 1 / Int._sizeInBytes
  }

  internal init(storage: UnsafeMutablePointer<UInt>, bitCount: Int) {
    self.bitCount = bitCount
    self.values = storage
  }

  internal var numberOfWords: Int {
    @warn_unused_result
    get {
      return _BitMap.wordsFor(bitCount)
    }
  }

  internal func initializeToZero() {
    for i in 0 ..< numberOfWords {
      (values + i).initialize(0)
    }
  }

  internal subscript(i: Int) -> Bool {
    @warn_unused_result
    get {
      _sanityCheck(i < Int(bitCount) && i >= 0, "index out of bounds")
      let idx = UInt(i)
      let word = values[Int(_BitMap.wordIndex(idx))]
      let bit = word & (1 << _BitMap.bitIndex(idx))
      return bit != 0
    }
    nonmutating set {
      _sanityCheck(i < Int(bitCount) && i >= 0, "index out of bounds")
      let idx = UInt(i)
      let wordIdx = _BitMap.wordIndex(idx)
      if newValue {
        values[Int(wordIdx)] =
          values[Int(wordIdx)] | (1 << _BitMap.bitIndex(idx))
      } else {
        values[Int(wordIdx)] =
          values[Int(wordIdx)] & ~(1 << _BitMap.bitIndex(idx))
      }
    }
  }
}

/// Header part of the native storage.
internal struct _HashedContainerStorageHeader {
  internal init(capacity: Int) {
    self.capacity = capacity
  }

  internal var capacity: Int
  internal var count: Int = 0
  internal var maxLoadFactorInverse: Double =
  _hashContainerDefaultMaxLoadFactorInverse
}


/// An instance of this class has all `NativeSet` data tail-allocated.
/// Enough bytes are allocated to hold the bitmap for marking valid entries,
/// keys, and values. The data layout starts with the bitmap, followed by the
/// keys, followed by the values.
final internal class _NativeSetStorageImpl<Element> :
ManagedBuffer<_HashedContainerStorageHeader, UInt8> {
  // Note: It is intended that Element
  // (without : Hashable) is used here - this storage must work
  // with non-Hashable types.

  internal typealias BufferPointer =
    ManagedBufferPointer<_HashedContainerStorageHeader, UInt8>
  internal typealias StorageImpl = _NativeSetStorageImpl

  internal typealias Key = Element

  /// Returns the bytes necessary to store a bit map of 'capacity' bytes and
  /// padding to align the start to word alignment.
  @warn_unused_result
  internal static func bytesForBitMap(capacity: Int) -> Int {
    let numWords = _BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) + alignof(UInt)
  }

  /// Returns the bytes necessary to store 'capacity' keys and padding to align
  /// the start to the alignment of the 'Key' type assuming a word aligned base
  /// address.
  @warn_unused_result
  internal static func bytesForKeys(capacity: Int) -> Int {
    let padding = max(0, alignof(Key.self) - alignof(UInt))
    return strideof(Key.self) * capacity + padding
  }

  /// Returns the bytes necessary to store 'capacity' values and padding to
  /// align the start to the alignment of the 'Value' type assuming a base
  /// address aligned to the maximum of the alignment of the 'Key' type and the
  /// alignment of a word.


  internal var buffer: BufferPointer {
    @warn_unused_result
    get {
      return BufferPointer(unsafeBufferObject: self)
    }
  }

  // All underscored functions are unsafe and need a _fixLifetime in the caller.
  internal var _body: _HashedContainerStorageHeader {
    unsafeAddress {
      return UnsafePointer(buffer.withUnsafeMutablePointerToValue({$0}))
    }
    unsafeMutableAddress {
      return buffer.withUnsafeMutablePointerToValue({$0})
    }
  }

  internal var _capacity: Int {
    @warn_unused_result
    get {
      return _body.capacity
    }
  }

  internal var _count: Int {
    set {
      _body.count = newValue
    }
    @warn_unused_result
    get {
      return _body.count
    }
  }

  internal var _maxLoadFactorInverse : Double {
    @warn_unused_result
    get {
      return _body.maxLoadFactorInverse
    }
  }

  internal
  var _initializedHashtableEntriesBitMapStorage: UnsafeMutablePointer<UInt> {
    @warn_unused_result
    get {
      let start = unsafeBitCast(buffer.withUnsafeMutablePointerToElements({$0}), UInt.self)
      let alignment = UInt(alignof(UInt))
      let alignMask = alignment &- UInt(1)
      return UnsafeMutablePointer<UInt>(
        bitPattern:(start &+ alignMask) & ~alignMask)
    }
  }

  internal var _keys: UnsafeMutablePointer<Key> {
    @warn_unused_result
    get {
      let start =
        unsafeBitCast(_initializedHashtableEntriesBitMapStorage, UInt.self) &+
          UInt(_BitMap.wordsFor(_capacity)) &* UInt(strideof(UInt))
      let alignment = UInt(alignof(Key))
      let alignMask = alignment &- UInt(1)
      return UnsafeMutablePointer<Key>(
        bitPattern:(start &+ alignMask) & ~alignMask)
    }
  }


  /// Create a storage instance with room for 'capacity' entries and all entries
  /// marked invalid.
  internal class func create(capacity: Int) -> StorageImpl {
    let requiredCapacity = bytesForBitMap(capacity) + bytesForKeys(capacity)

    let r = super.create(requiredCapacity) { _ in
      return _HashedContainerStorageHeader(capacity: capacity)
    }
    let storage = r as! StorageImpl
    let initializedEntries = _BitMap(
      storage: storage._initializedHashtableEntriesBitMapStorage,
      bitCount: capacity)
    initializedEntries.initializeToZero()
    return storage
  }

  deinit {
    let capacity = _capacity
    let initializedEntries = _BitMap(
      storage: _initializedHashtableEntriesBitMapStorage, bitCount: capacity)
    let keys = _keys

    if !_isPOD(Key.self) {
      for i in 0 ..< capacity {
        if initializedEntries[i] {
          (keys+i).destroy()
        }
      }
    }

    buffer.withUnsafeMutablePointerToValue({$0.destroy()})
    _fixLifetime(self)
  }
}

public // @testable
struct _NativeSetStorage<Element : Hashable> :
_HashStorageType, CustomStringConvertible {
  internal typealias Owner = _NativeSetStorageOwner<Element>
  internal typealias StorageImpl = _NativeSetStorageImpl<Element>
  internal typealias SequenceElement = Element
  internal typealias Storage = _NativeSetStorage<Element>

  internal typealias Key = Element
  internal typealias Value = Element

  internal let buffer: StorageImpl

  internal let initializedEntries: _BitMap
  internal let keys: UnsafeMutablePointer<Key>

  internal init(capacity: Int) {
    buffer = StorageImpl.create(capacity)
    initializedEntries = _BitMap(
      storage: buffer._initializedHashtableEntriesBitMapStorage,
      bitCount: capacity)
    keys = buffer._keys
    _fixLifetime(buffer)
  }

  internal init(minimumCapacity: Int = 2) {
    // Make sure there's a representable power of 2 >= minimumCapacity
    _sanityCheck(minimumCapacity <= (Int.max >> 1) + 1)

    var capacity = 2
    while capacity < minimumCapacity {
      capacity <<= 1
    }

    self = _NativeSetStorage(capacity: capacity)
  }

  @_transparent
  public // @testable
  var capacity: Int {
    @warn_unused_result
    get {
      let c = buffer._capacity
      _fixLifetime(buffer)
      return c
    }
  }

  @_transparent
  internal var count: Int {
    @warn_unused_result
    get {
      let c  = buffer._count
      _fixLifetime(buffer)
      return c
    }
    nonmutating set(newValue) {
      buffer._count = newValue
      _fixLifetime(buffer)
    }
  }

  @_transparent
  internal var maxLoadFactorInverse: Double {
    @warn_unused_result
    get {
      let c = buffer._maxLoadFactorInverse
      _fixLifetime(buffer)
      return c
    }
  }

  @warn_unused_result
  internal func keyAt(i: Int) -> Key {
    _precondition(i >= 0 && i < capacity)
    _sanityCheck(isInitializedEntry(i))

    let res = (keys + i).memory
    _fixLifetime(self)
    return res
  }

  @warn_unused_result
  internal func isInitializedEntry(i: Int) -> Bool {
    _precondition(i >= 0 && i < capacity)
    return initializedEntries[i]
  }

  @_transparent
  internal func destroyEntryAt(i: Int) {
    _sanityCheck(isInitializedEntry(i))
    (keys + i).destroy()
    initializedEntries[i] = false
    _fixLifetime(self)
  }

  @_transparent
  internal func initializeKey(k: Key, at i: Int) {
    _sanityCheck(!isInitializedEntry(i))

    (keys + i).initialize(k)
    initializedEntries[i] = true
    _fixLifetime(self)
  }

  @_transparent
  internal func moveInitializeFrom(from: Storage, at: Int, toEntryAt: Int) {
    _sanityCheck(!isInitializedEntry(toEntryAt))
    (keys + toEntryAt).initialize((from.keys + at).move())
    from.initializedEntries[at] = false
    initializedEntries[toEntryAt] = true
  }

  internal func setKey(key: Key, at i: Int) {
    _precondition(i >= 0 && i < capacity)
    _sanityCheck(isInitializedEntry(i))

    (keys + i).memory = key
    _fixLifetime(self)
  }


  //
  // Implementation details
  //

  internal var _bucketMask: Int {
    // The capacity is not negative, therefore subtracting 1 will not overflow.
    return capacity &- 1
  }

  @warn_unused_result
  internal func _bucket(k: Key) -> Int {
    return _squeezeHashValue(k.hashValue, 0..<capacity)
  }

  @warn_unused_result
  internal func _next(bucket: Int) -> Int {
    // Bucket is within 0 and capacity. Therefore adding 1 does not overflow.
    return (bucket &+ 1) & _bucketMask
  }

  @warn_unused_result
  internal func _prev(bucket: Int) -> Int {
    // Bucket is not negative. Therefore subtracting 1 does not overflow.
    return (bucket &- 1) & _bucketMask
  }

  /// Search for a given key starting from the specified bucket.
  ///
  /// If the key is not present, returns the position where it could be
  /// inserted.
  @warn_unused_result
  internal
  func _find(key: Key, _ startBucket: Int) -> (pos: Index, found: Bool) {
    var bucket = startBucket

    // The invariant guarantees there's always a hole, so we just loop
    // until we find one
    while true {
      let isHole = !isInitializedEntry(bucket)
      if isHole {
        return (Index(nativeStorage: self, offset: bucket), false)
      }
      if keyAt(bucket) == key {
        return (Index(nativeStorage: self, offset: bucket), true)
      }
      bucket = _next(bucket)
    }
  }

  @_transparent
  @warn_unused_result
  internal static func getMinCapacity(
    requestedCount: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(requestedCount) * maxLoadFactorInverse),
               requestedCount + 1)
  }

  /// Storage should be uniquely referenced.
  /// The `key` should not be present in the NativeSet.
  /// This function does *not* update `count`.


  internal mutating func unsafeAddNew(key newKey: Element) {
    let (i, found) = _find(newKey, _bucket(newKey))
    _sanityCheck(
      !found, "unsafeAddNew was called, but the key is already present")
    initializeKey(newKey, at: i.offset)
  }


  /// A textual representation of `self`.
  public // @testable
  var description: String {
    var result = ""
    #if INTERNAL_CHECKS_ENABLED
      for i in 0..<capacity {
        if isInitializedEntry(i) {
          let key = keyAt(i)
          result += "bucket \(i), ideal bucket = \(_bucket(key)), key = \(key)\n"
        } else {
          result += "bucket \(i), empty\n"
        }
      }
    #endif
    return result
  }

  //
  // _HashStorageType conformance
  //

  internal typealias Index = _NativeSetIndex<Element>

  internal var startIndex: Index {
    return Index(nativeStorage: self, offset: -1).successor()
  }

  internal var endIndex: Index {
    return Index(nativeStorage: self, offset: capacity)
  }

  @warn_unused_result
  internal func indexForKey(key: Key) -> Index? {
    if count == 0 {
      // Fast path that avoids computing the hash of the key.
      return nil
    }
    let (i, found) = _find(key, _bucket(key))
    return found ? i : nil
  }

  @warn_unused_result
  internal func assertingGet(i: Index) -> SequenceElement {
    _precondition(
      isInitializedEntry(i.offset),
      "attempting to access NativeSet elements using an invalid Index")
    let key = keyAt(i.offset)
    return key

  }

  @warn_unused_result
  internal func assertingGet(key: Key) -> Value {
    let (i, found) = _find(key, _bucket(key))
    _precondition(found, "key not found")
    return keyAt(i.offset)
  }

  @warn_unused_result
  internal func maybeGet(key: Key) -> Value? {
    if count == 0 {
      // Fast path that avoids computing the hash of the key.
      return nil
    }

    let (i, found) = _find(key, _bucket(key))
    if found {
      return keyAt(i.offset)
    }
    return nil
  }

  internal mutating func updateValue(value: Value, forKey: Key) -> Value? {
    _sanityCheckFailure(
      "don't call mutating methods on _NativeSetStorage")
  }

  internal mutating func removeAtIndex(index: Index) -> SequenceElement {
    _sanityCheckFailure(
      "don't call mutating methods on _NativeSetStorage")
  }

  internal mutating func removeValueForKey(key: Key) -> Value? {
    _sanityCheckFailure(
      "don't call mutating methods on _NativeSetStorage")
  }

  internal mutating func removeAll(keepCapacity keepCapacity: Bool) {
    _sanityCheckFailure(
      "don't call mutating methods on _NativeSetStorage")
  }

  @warn_unused_result
  internal static func fromArray(elements: [SequenceElement])
    -> _NativeSetStorage<Element> {

      let requiredCapacity =
        _NativeSetStorage<Element>.getMinCapacity(
          elements.count, _hashContainerDefaultMaxLoadFactorInverse)
      let nativeStorage = _NativeSetStorage<Element>(
        minimumCapacity: requiredCapacity)


      var count = 0
      for key in elements {
        let (i, found) = nativeStorage._find(key, nativeStorage._bucket(key))
        if found {
          continue
        }
        nativeStorage.initializeKey(key, at: i.offset)
        count += 1
      }
      nativeStorage.count = count


      return nativeStorage
  }
}

/// This class is an artifact of the COW implementation.  This class only
/// exists to keep separate retain counts separate for:
/// - `NativeSet` and `NSSet`,
/// - `SetIndex`.
///
/// This is important because the uniqueness check for COW only cares about
/// retain counts of the first kind.
///
/// Specifically, `NativeSet` points to instances of this class.  This class
/// is also a proper `NSSet` subclass, which is returned to Objective-C
/// during bridging.  `SetIndex` points directly to
/// `_NativeSetStorage`.
final internal class _NativeSetStorageOwner<Element : Hashable>
: NonObjectiveCBase {

  internal typealias NativeStorage = _NativeSetStorage<Element>
  internal typealias Key = Element
  internal typealias Value = Element

  internal init(minimumCapacity: Int = 2) {
    nativeStorage = NativeStorage(minimumCapacity: minimumCapacity)
    super.init()
  }

  internal init(nativeStorage: NativeStorage) {
    self.nativeStorage = nativeStorage
    super.init()
  }

  // This stored property should be stored at offset zero.  We perform atomic
  // operations on it.
  //
  // Do not access this property directly.
  internal var _heapBufferBridged_DoNotUse: AnyObject? = nil

  internal var nativeStorage: NativeStorage
}

internal enum _VariantSetStorage<Element : Hashable> : _HashStorageType {

  internal typealias NativeStorage = _NativeSetStorage<Element>
  internal typealias NativeStorageOwner =
    _NativeSetStorageOwner<Element>
  internal typealias NativeIndex = _NativeSetIndex<Element>
  internal typealias SequenceElement = Element
  internal typealias SelfType = _VariantSetStorage

  internal typealias Key = Element
  internal typealias Value = Element

  case Native(NativeStorageOwner)

  @_transparent
  internal var guaranteedNative: Bool {
    return true
  }

  @warn_unused_result
  internal mutating func isUniquelyReferenced() -> Bool {
    return _isUnique_native(&self)
  }

  internal var native: NativeStorage {
    switch self {
    case .Native(let owner):
      return owner.nativeStorage
    }
  }

  /// Ensure this we hold a unique reference to a native storage
  /// having at least `minimumCapacity` elements.
  internal mutating func ensureUniqueNativeStorage(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool) {
      switch self {
      case .Native:
        let oldCapacity = native.capacity
        if isUniquelyReferenced() && oldCapacity >= minimumCapacity {
          return (reallocated: false, capacityChanged: false)
        }

        let oldNativeStorage = native
        let newNativeOwner = NativeStorageOwner(minimumCapacity: minimumCapacity)
        var newNativeStorage = newNativeOwner.nativeStorage
        let newCapacity = newNativeStorage.capacity
        for i in 0..<oldCapacity {
          if oldNativeStorage.isInitializedEntry(i) {
            if oldCapacity == newCapacity {
              let key = oldNativeStorage.keyAt(i)
              newNativeStorage.initializeKey(key, at: i)
            } else {
              let key = oldNativeStorage.keyAt(i)
              newNativeStorage.unsafeAddNew(key: key)
            }
          }
        }
        newNativeStorage.count = oldNativeStorage.count

        self = .Native(newNativeOwner)
        return (reallocated: true,
                capacityChanged: oldCapacity != newNativeStorage.capacity)
      }
  }
  //
  // _HashStorageType conformance
  //

  internal typealias Index = SetIndex<Element>

  internal var startIndex: Index {
    switch self {
    case .Native:
      return ._Native(native.startIndex)
    }
  }

  internal var endIndex: Index {
    switch self {
    case .Native:
      return ._Native(native.endIndex)
    }
  }

  @warn_unused_result
  internal func indexForKey(key: Key) -> Index? {
    switch self {
    case .Native:
      if let nativeIndex = native.indexForKey(key) {
        return ._Native(nativeIndex)
      }
      return nil
    }
  }

  @warn_unused_result
  internal func assertingGet(i: Index) -> SequenceElement {
    switch self {
    case .Native:
      return native.assertingGet(i._nativeIndex)
    }
  }

  @warn_unused_result
  internal func assertingGet(key: Key) -> Value {
    switch self {
    case .Native:
      return native.assertingGet(key)
    }
  }

  @warn_unused_result
  internal func maybeGet(key: Key) -> Value? {
    switch self {
    case .Native:
      return native.maybeGet(key)
    }
  }

  internal mutating func nativeUpdateValue(
    value: Value, forKey key: Key
    ) -> Value? {
    var (i, found) = native._find(key, native._bucket(key))

    let minCapacity = found
      ? native.capacity
      : NativeStorage.getMinCapacity(
        native.count + 1,
        native.maxLoadFactorInverse)

    let (_, capacityChanged) = ensureUniqueNativeStorage(minCapacity)
    if capacityChanged {
      i = native._find(key, native._bucket(key)).pos
    }

    let oldValue: Value? = found ? native.keyAt(i.offset) : nil
    if found {
      native.setKey(key, at: i.offset)
    } else {
      native.initializeKey(key, at: i.offset)
      native.count += 1
    }

    return oldValue
  }

  internal mutating func updateValue(
    value: Value, forKey key: Key
    ) -> Value? {
    return nativeUpdateValue(value, forKey: key)
  }

  /// - parameter idealBucket: The ideal bucket for the element being deleted.
  /// - parameter offset: The offset of the element that will be deleted.
  /// Requires an initialized entry at offset.
  internal mutating func nativeDeleteImpl(
    nativeStorage: NativeStorage, idealBucket: Int, offset: Int
    ) {
    _sanityCheck(
      nativeStorage.isInitializedEntry(offset), "expected initialized entry")

    // remove the element
    nativeStorage.destroyEntryAt(offset)
    nativeStorage.count -= 1

    // If we've put a hole in a chain of contiguous elements, some
    // element after the hole may belong where the new hole is.
    var hole = offset

    // Find the first bucket in the contiguous chain
    var start = idealBucket
    while nativeStorage.isInitializedEntry(nativeStorage._prev(start)) {
      start = nativeStorage._prev(start)
    }

    // Find the last bucket in the contiguous chain
    var lastInChain = hole
    var b = nativeStorage._next(lastInChain)
    while nativeStorage.isInitializedEntry(b) {
      lastInChain = b
      b = nativeStorage._next(b)
    }

    // Relocate out-of-place elements in the chain, repeating until
    // none are found.
    while hole != lastInChain {
      // Walk backwards from the end of the chain looking for
      // something out-of-place.
      var b = lastInChain
      while b != hole {
        let idealBucket = nativeStorage._bucket(nativeStorage.keyAt(b))

        // Does this element belong between start and hole?  We need
        // two separate tests depending on whether [start,hole] wraps
        // around the end of the buffer
        let c0 = idealBucket >= start
        let c1 = idealBucket <= hole
        if start <= hole ? (c0 && c1) : (c0 || c1) {
          break // Found it
        }
        b = nativeStorage._prev(b)
      }

      if b == hole { // No out-of-place elements found; we're done adjusting
        break
      }

      // Move the found element into the hole
      nativeStorage.moveInitializeFrom(nativeStorage, at: b, toEntryAt: hole)
      hole = b
    }
  }

  internal mutating func nativeRemoveObjectForKey(key: Key) -> Value? {
    var nativeStorage = native
    var idealBucket = nativeStorage._bucket(key)
    var (index, found) = nativeStorage._find(key, idealBucket)

    // Fast path: if the key is not present, we will not mutate the set,
    // so don't force unique storage.
    if !found {
      return nil
    }

    let (reallocated, capacityChanged) =
      ensureUniqueNativeStorage(nativeStorage.capacity)
    if reallocated {
      nativeStorage = native
    }
    if capacityChanged {
      idealBucket = nativeStorage._bucket(key)
      (index, found) = nativeStorage._find(key, idealBucket)
      _sanityCheck(found, "key was lost during storage migration")
    }
    let oldValue = nativeStorage.keyAt(index.offset)
    nativeDeleteImpl(nativeStorage, idealBucket: idealBucket,
                     offset: index.offset)
    return oldValue
  }

  internal mutating func nativeRemoveAtIndex(
    nativeIndex: NativeIndex
    ) -> SequenceElement {
    var nativeStorage = native

    // The provided index should be valid, so we will always mutating the
    // set storage.  Request unique storage.
    let (reallocated, _) = ensureUniqueNativeStorage(nativeStorage.capacity)
    if reallocated {
      nativeStorage = native
    }

    let result = nativeStorage.assertingGet(nativeIndex)
    let key = result

    nativeDeleteImpl(nativeStorage, idealBucket: nativeStorage._bucket(key),
                     offset: nativeIndex.offset)
    return result
  }

  internal mutating func removeAtIndex(index: Index) -> SequenceElement {
    return nativeRemoveAtIndex(index._nativeIndex)
  }

  internal mutating func removeValueForKey(key: Key) -> Value? {
    return nativeRemoveObjectForKey(key)
  }

  internal mutating func nativeRemoveAll() {
    var nativeStorage = native

    // FIXME(performance): if the storage is non-uniquely referenced, we
    // shouldn't be copying the elements into new storage and then immediately
    // deleting the elements. We should detect that the storage is not uniquely
    // referenced and allocate new empty storage of appropriate capacity.

    // We have already checked for the empty dictionary case, so we will always
    // mutating the dictionary storage.  Request unique storage.
    let (reallocated, _) = ensureUniqueNativeStorage(nativeStorage.capacity)
    if reallocated {
      nativeStorage = native
    }

    for b in 0..<nativeStorage.capacity {
      if nativeStorage.isInitializedEntry(b) {
        nativeStorage.destroyEntryAt(b)
      }
    }
    nativeStorage.count = 0
  }

  internal mutating func removeAll(keepCapacity keepCapacity: Bool) {
    if count == 0 {
      return
    }

    if !keepCapacity {
      self = .Native(NativeStorage.Owner(minimumCapacity: 2))
      return
    }

    nativeRemoveAll()
    return
  }

  internal var count: Int {
    switch self {
    case .Native:
      return native.count
    }
  }

  /// Returns a generator over the (Key, Value) pairs.
  ///
  /// - Complexity: O(1).
  internal func generate() -> SetGenerator<Element> {
    switch self {
    case .Native(let owner):
      return
        ._Native(start: native.startIndex, end: native.endIndex, owner: owner)
    }
  }

  @warn_unused_result
  internal static func fromArray(elements: [SequenceElement])
    -> _VariantSetStorage<Element> {

      _sanityCheckFailure("this function should never be called")
  }
}

internal struct _NativeSetIndex<Element : Hashable> :
ForwardIndexType, Comparable {

  internal typealias NativeStorage = _NativeSetStorage<Element>
  internal typealias NativeIndex = _NativeSetIndex<Element>

  internal var nativeStorage: NativeStorage
  internal var offset: Int

  internal init(nativeStorage: NativeStorage, offset: Int) {
    self.nativeStorage = nativeStorage
    self.offset = offset
  }

  /// Returns the next consecutive value after `self`.
  ///
  /// - Requires: The next value is representable.
  @warn_unused_result
  internal func successor() -> NativeIndex {
    var i = offset + 1
    // FIXME: Can't write the simple code pending
    // <rdar://problem/15484639> Refcounting bug
    while i < nativeStorage.capacity /*&& !nativeStorage[i]*/ {
      // FIXME: workaround for <rdar://problem/15484639>
      if nativeStorage.isInitializedEntry(i) {
        break
      }
      // end workaround
      i += 1
    }
    return NativeIndex(nativeStorage: nativeStorage, offset: i)
  }
}

internal func == <Element : Hashable> (
  lhs: _NativeSetIndex<Element>,
  rhs: _NativeSetIndex<Element>
  ) -> Bool {
  // FIXME: assert that lhs and rhs are from the same dictionary.
  return lhs.offset == rhs.offset
}

internal func < <Element : Hashable> (
  lhs: _NativeSetIndex<Element>,
  rhs: _NativeSetIndex<Element>
  ) -> Bool {
  // FIXME: assert that lhs and rhs are from the same dictionary.
  return lhs.offset < rhs.offset
}

internal enum SetIndexRepresentation<Element : Hashable> {
  typealias _Index = SetIndex<Element>
  typealias _NativeIndex = _Index._NativeIndex

  case _Native(_NativeIndex)
}


/// Used to access the members in an instance of `NativeSet<Element>`.
public struct SetIndex<Element : Hashable> :
ForwardIndexType, Comparable {
  // Index for native storage is efficient.  Index for bridged NSSet is
  // not, because neither NSEnumerator nor fast enumeration support moving
  // backwards.  Even if they did, there is another issue: NSEnumerator does
  // not support NSCopying, and fast enumeration does not document that it is
  // safe to copy the state.  So, we cannot implement Index that is a value
  // type for bridged NSSet in terms of Cocoa enumeration facilities.

  internal typealias _NativeIndex = _NativeSetIndex<Element>

  internal typealias Key = Element
  internal typealias Value = Element

  internal var _value: SetIndexRepresentation<Element>

  internal static func _Native(index: _NativeIndex) -> SetIndex {
    return SetIndex(_value: ._Native(index))
  }

  @_transparent
  internal var _guaranteedNative: Bool {
    return true
  }

  @_transparent
  internal var _nativeIndex: _NativeIndex {
    switch _value {
    case ._Native(let nativeIndex):
      return nativeIndex
    }
  }

  /// Returns the next consecutive value after `self`.
  ///
  /// - Requires: The next value is representable.
  public func successor() -> SetIndex<Element> {
    return ._Native(_nativeIndex.successor())
  }
}

@warn_unused_result
public func == <Element : Hashable> (
  lhs: SetIndex<Element>,
  rhs: SetIndex<Element>
  ) -> Bool {
  return lhs._nativeIndex == rhs._nativeIndex
}

@warn_unused_result
public func < <Element : Hashable> (
  lhs: SetIndex<Element>,
  rhs: SetIndex<Element>
  ) -> Bool {
  return lhs._nativeIndex < rhs._nativeIndex
}

internal enum SetGeneratorRepresentation<Element : Hashable> {
  internal typealias _Generator = SetGenerator<Element>
  internal typealias _NativeStorageOwner =
    _NativeSetStorageOwner<Element>
  internal typealias _NativeIndex = _Generator._NativeIndex

  // For native storage, we keep two indices to keep track of the iteration
  // progress and the storage owner to make the storage non-uniquely
  // referenced.
  //
  // While indices keep the storage alive, they don't affect reference count of
  // the storage.  Generator is iterating over a frozen view of the collection
  // state, so it should keep its own reference to the storage owner.
  case _Native(
    start: _NativeIndex, end: _NativeIndex, owner: _NativeStorageOwner)
}

/// A generator over the members of a `NativeSet<Element>`.
public struct SetGenerator<Element : Hashable> : GeneratorType {
  // NativeSet has a separate GeneratorType and Index because of efficiency
  // and implementability reasons.
  //
  // Index for native storage is efficient.  Index for bridged NSSet is
  // not.
  //
  // Even though fast enumeration is not suitable for implementing
  // Index, which is multi-pass, it is suitable for implementing a
  // GeneratorType, which is being consumed as iteration proceeds.

  internal typealias _NativeStorageOwner =
    _NativeSetStorageOwner<Element>
  internal typealias _NativeIndex = _NativeSetIndex<Element>

  internal var _state: SetGeneratorRepresentation<Element>

  internal static func _Native(
    start start: _NativeIndex, end: _NativeIndex, owner: _NativeStorageOwner
    ) -> SetGenerator {
    return SetGenerator(
      _state: ._Native(start: start, end: end, owner: owner))
  }

  @_transparent
  internal var _guaranteedNative: Bool {
    return true
  }

  internal mutating func _nativeNext() -> Element? {
    switch _state {
    case ._Native(let startIndex, let endIndex, let owner):
      if startIndex == endIndex {
        return nil
      }
      let result = startIndex.nativeStorage.assertingGet(startIndex)
      _state =
        ._Native(start: startIndex.successor(), end: endIndex, owner: owner)
      return result
    }
  }

  /// Advance to the next element and return it, or `nil` if no next
  /// element exists.
  ///
  /// - Requires: No preceding call to `self.next()` has returned `nil`.
  public mutating func next() -> Element? {
    return _nativeNext()
  }
}

internal struct SetMirrorPosition<Element : Hashable> {
  internal typealias MirroredType = NativeSet<Element>

  internal var _intPos: Int
  internal var SetPos: MirroredType.Index

  internal init(_ m: MirroredType) {
    _intPos = 0
    SetPos = m.startIndex
  }

  internal mutating func successor() {
    _intPos = _intPos + 1
    SetPos._successorInPlace()
  }

}

@warn_unused_result
internal func == <Element : Hashable> (
  lhs: SetMirrorPosition<Element>, rhs : Int
  ) -> Bool {
  return lhs._intPos == rhs
}

@warn_unused_result
internal func > <Element : Hashable> (
  lhs: SetMirrorPosition<Element>, rhs : Int
  ) -> Bool {
  return lhs._intPos > rhs
}

@warn_unused_result
internal func < <Element : Hashable> (
  lhs: SetMirrorPosition<Element>, rhs : Int
  ) -> Bool {
  return lhs._intPos < rhs
}

internal class SetMirror<Element : Hashable> : _MirrorType {
  typealias MirroredType = NativeSet<Element>
  internal let _mirror : MirroredType
  internal var _pos : SetMirrorPosition<Element>

  internal init(_ m : MirroredType) {
    _mirror = m
    _pos = SetMirrorPosition(m)
  }

  internal var value: Any { return (_mirror as Any) }

  internal var valueType: Any.Type { return (_mirror as Any).dynamicType }

  internal var objectIdentifier: ObjectIdentifier? { return nil }

  internal var count: Int { return _mirror.count }

  internal subscript(i: Int) -> (String, _MirrorType) {
    _precondition(i >= 0 && i < count, "_MirrorType access out of bounds")

    if _pos > i {
      _pos._intPos = 0
    }

    while _pos < i && !(_pos == i) {
      _pos.successor()
    }
    return ("[\(_pos._intPos)]", _reflect(_mirror[_pos.SetPos]))
  }

  internal var summary: String {
    if count == 1 {
      return "1 member"
    }
    return "\(count) members"
  }

  internal var quickLookObject: PlaygroundQuickLook? { return nil }

  internal var disposition: _MirrorDisposition { return .MembershipContainer }
}

extension NativeSet : _Reflectable {
  /// Returns a mirror that reflects `self`.
  @warn_unused_result
  public func _getMirror() -> _MirrorType {
    return SetMirror(self)
  }
}

/// Initializes `a NativeSet` from unique members.
///
/// Using a builder can be faster than inserting members into an empty
/// `NativeSet`.
public struct _SetBuilder<Element : Hashable> {
  public typealias Key = Element
  public typealias Value = Element

  internal var _result: NativeSet<Element>
  internal var _nativeStorage: _NativeSetStorage<Element>
  internal let _requestedCount: Int
  internal var _actualCount: Int

  public init(count: Int) {
    let requiredCapacity =
      _NativeSetStorage<Element>.getMinCapacity(
        count, _hashContainerDefaultMaxLoadFactorInverse)
    _result = NativeSet<Element>(minimumCapacity: requiredCapacity)
    _nativeStorage = _result._variantStorage.native
    _requestedCount = count
    _actualCount = 0
  }

  public mutating func add(member newKey: Key) {
    _nativeStorage.unsafeAddNew(key: newKey)
    _actualCount += 1
  }

  @warn_unused_result
  public mutating func take() -> NativeSet<Element> {
    _precondition(_actualCount >= 0,
                  "cannot take the result twice")
    _precondition(_actualCount == _requestedCount,
                  "the number of members added does not match the promised count")

    // Finish building the `NativeSet`.
    _nativeStorage.count = _requestedCount

    // Prevent taking the result twice.
    _actualCount = -1
    return _result
  }
}

extension NativeSet {
  /// If `!self.isEmpty`, return the first key-value pair in the sequence of
  /// elements, otherwise return `nil`.
  ///
  /// - Complexity: Amortized O(1)
  public mutating func popFirst() -> Element? {
    guard !isEmpty else { return nil }
    return removeAtIndex(startIndex)
  }
}

/// An instance of this class has all `NativeDictionary` data tail-allocated.
/// Enough bytes are allocated to hold the bitmap for marking valid entries,
/// keys, and values. The data layout starts with the bitmap, followed by the
/// keys, followed by the values.
final internal class _NativeDictionaryStorageImpl<Key, Value> :
ManagedBuffer<_HashedContainerStorageHeader, UInt8> {
  // Note: It is intended that Key, Value
  // (without : Hashable) is used here - this storage must work
  // with non-Hashable types.

  internal typealias BufferPointer =
    ManagedBufferPointer<_HashedContainerStorageHeader, UInt8>
  internal typealias StorageImpl = _NativeDictionaryStorageImpl


  /// Returns the bytes necessary to store a bit map of 'capacity' bytes and
  /// padding to align the start to word alignment.
  @warn_unused_result
  internal static func bytesForBitMap(capacity: Int) -> Int {
    let numWords = _BitMap.wordsFor(capacity)
    return numWords * sizeof(UInt) + alignof(UInt)
  }

  /// Returns the bytes necessary to store 'capacity' keys and padding to align
  /// the start to the alignment of the 'Key' type assuming a word aligned base
  /// address.
  @warn_unused_result
  internal static func bytesForKeys(capacity: Int) -> Int {
    let padding = max(0, alignof(Key.self) - alignof(UInt))
    return strideof(Key.self) * capacity + padding
  }

  /// Returns the bytes necessary to store 'capacity' values and padding to
  /// align the start to the alignment of the 'Value' type assuming a base
  /// address aligned to the maximum of the alignment of the 'Key' type and the
  /// alignment of a word.

  @warn_unused_result
  internal static func bytesForValues(capacity: Int) -> Int {
    let maxPrevAlignment = max(alignof(Key.self), alignof(UInt))
    let padding = max(0, alignof(Value.self) - maxPrevAlignment)
    return strideof(Value.self) * capacity + padding
  }

  internal var buffer: BufferPointer {
    @warn_unused_result
    get {
      return BufferPointer(unsafeBufferObject: self)
    }
  }

  // All underscored functions are unsafe and need a _fixLifetime in the caller.
  internal var _body: _HashedContainerStorageHeader {
    unsafeAddress {
      return UnsafePointer(buffer.withUnsafeMutablePointerToValue({$0}))
    }
    unsafeMutableAddress {
      return buffer.withUnsafeMutablePointerToValue({$0})
    }
  }

  internal var _capacity: Int {
    @warn_unused_result
    get {
      return _body.capacity
    }
  }

  internal var _count: Int {
    set {
      _body.count = newValue
    }
    @warn_unused_result
    get {
      return _body.count
    }
  }

  internal var _maxLoadFactorInverse : Double {
    @warn_unused_result
    get {
      return _body.maxLoadFactorInverse
    }
  }

  internal
  var _initializedHashtableEntriesBitMapStorage: UnsafeMutablePointer<UInt> {
    @warn_unused_result
    get {
      let start = unsafeBitCast(buffer.withUnsafeMutablePointerToElements({$0}), UInt.self)
      let alignment = UInt(alignof(UInt))
      let alignMask = alignment &- UInt(1)
      return UnsafeMutablePointer<UInt>(
        bitPattern:(start &+ alignMask) & ~alignMask)
    }
  }

  internal var _keys: UnsafeMutablePointer<Key> {
    @warn_unused_result
    get {
      let start =
        unsafeBitCast(_initializedHashtableEntriesBitMapStorage, UInt.self) &+
          UInt(_BitMap.wordsFor(_capacity)) &* UInt(strideof(UInt))
      let alignment = UInt(alignof(Key))
      let alignMask = alignment &- UInt(1)
      return UnsafeMutablePointer<Key>(
        bitPattern:(start &+ alignMask) & ~alignMask)
    }
  }

  internal var _values: UnsafeMutablePointer<Value> {
    @warn_unused_result
    get {
      let start = unsafeBitCast(_keys, UInt.self) &+
        UInt(_capacity) &* UInt(strideof(Key.self))
      let alignment = UInt(alignof(Value))
      let alignMask = alignment &- UInt(1)
      return UnsafeMutablePointer<Value>(
        bitPattern:(start &+ alignMask) & ~alignMask)
    }
  }

  /// Create a storage instance with room for 'capacity' entries and all entries
  /// marked invalid.
  internal class func create(capacity: Int) -> StorageImpl {
    let requiredCapacity = bytesForBitMap(capacity) + bytesForKeys(capacity)
      + bytesForValues(capacity)

    let r = super.create(requiredCapacity) { _ in
      return _HashedContainerStorageHeader(capacity: capacity)
    }
    let storage = r as! StorageImpl
    let initializedEntries = _BitMap(
      storage: storage._initializedHashtableEntriesBitMapStorage,
      bitCount: capacity)
    initializedEntries.initializeToZero()
    return storage
  }

  deinit {
    let capacity = _capacity
    let initializedEntries = _BitMap(
      storage: _initializedHashtableEntriesBitMapStorage, bitCount: capacity)
    let keys = _keys
    let values = _values

    if !_isPOD(Key.self) {
      for i in 0 ..< capacity {
        if initializedEntries[i] {
          (keys+i).destroy()
        }
      }
    }

    if !_isPOD(Value.self) {
      for i in 0 ..< capacity {
        if initializedEntries[i] {
          (values+i).destroy()
        }
      }
    }
    buffer.withUnsafeMutablePointerToValue({$0.destroy()})
    _fixLifetime(self)
  }
}

public // @testable
struct _NativeDictionaryStorage<Key : Hashable, Value> :
_HashStorageType, CustomStringConvertible {
  internal typealias Owner = _NativeDictionaryStorageOwner<Key, Value>
  internal typealias StorageImpl = _NativeDictionaryStorageImpl<Key, Value>
  internal typealias SequenceElement = (Key, Value)
  internal typealias Storage = _NativeDictionaryStorage<Key, Value>


  internal let buffer: StorageImpl

  internal let initializedEntries: _BitMap
  internal let keys: UnsafeMutablePointer<Key>
  internal let values: UnsafeMutablePointer<Value>

  internal init(capacity: Int) {
    buffer = StorageImpl.create(capacity)
    initializedEntries = _BitMap(
      storage: buffer._initializedHashtableEntriesBitMapStorage,
      bitCount: capacity)
    keys = buffer._keys
    values = buffer._values
    _fixLifetime(buffer)
  }

  internal init(minimumCapacity: Int = 2) {
    // Make sure there's a representable power of 2 >= minimumCapacity
    _sanityCheck(minimumCapacity <= (Int.max >> 1) + 1)

    var capacity = 2
    while capacity < minimumCapacity {
      capacity <<= 1
    }

    self = _NativeDictionaryStorage(capacity: capacity)
  }

  @_transparent
  public // @testable
  var capacity: Int {
    @warn_unused_result
    get {
      let c = buffer._capacity
      _fixLifetime(buffer)
      return c
    }
  }

  @_transparent
  internal var count: Int {
    @warn_unused_result
    get {
      let c  = buffer._count
      _fixLifetime(buffer)
      return c
    }
    nonmutating set(newValue) {
      buffer._count = newValue
      _fixLifetime(buffer)
    }
  }

  @_transparent
  internal var maxLoadFactorInverse: Double {
    @warn_unused_result
    get {
      let c = buffer._maxLoadFactorInverse
      _fixLifetime(buffer)
      return c
    }
  }

  @warn_unused_result
  internal func keyAt(i: Int) -> Key {
    _precondition(i >= 0 && i < capacity)
    _sanityCheck(isInitializedEntry(i))

    let res = (keys + i).memory
    _fixLifetime(self)
    return res
  }

  @warn_unused_result
  internal func isInitializedEntry(i: Int) -> Bool {
    _precondition(i >= 0 && i < capacity)
    return initializedEntries[i]
  }

  @_transparent
  internal func destroyEntryAt(i: Int) {
    _sanityCheck(isInitializedEntry(i))
    (keys + i).destroy()
    (values + i).destroy()
    initializedEntries[i] = false
    _fixLifetime(self)
  }

  @_transparent
  internal func initializeKey(k: Key, value v: Value, at i: Int) {
    _sanityCheck(!isInitializedEntry(i))

    (keys + i).initialize(k)
    (values + i).initialize(v)
    initializedEntries[i] = true
    _fixLifetime(self)
  }

  @_transparent
  internal func moveInitializeFrom(from: Storage, at: Int, toEntryAt: Int) {
    _sanityCheck(!isInitializedEntry(toEntryAt))
    (keys + toEntryAt).initialize((from.keys + at).move())
    (values + toEntryAt).initialize((from.values + at).move())
    from.initializedEntries[at] = false
    initializedEntries[toEntryAt] = true
  }

  @_transparent
  @warn_unused_result
  internal func valueAt(i: Int) -> Value {
    _sanityCheck(isInitializedEntry(i))

    let res = (values + i).memory
    _fixLifetime(self)
    return res
  }

  @_transparent
  internal func setKey(key: Key, value: Value, at i: Int) {
    _sanityCheck(isInitializedEntry(i))
    (keys + i).memory = key
    (values + i).memory = value
    _fixLifetime(self)
  }


  //
  // Implementation details
  //

  internal var _bucketMask: Int {
    // The capacity is not negative, therefore subtracting 1 will not overflow.
    return capacity &- 1
  }

  @warn_unused_result
  internal func _bucket(k: Key) -> Int {
    return _squeezeHashValue(k.hashValue, 0..<capacity)
  }

  @warn_unused_result
  internal func _next(bucket: Int) -> Int {
    // Bucket is within 0 and capacity. Therefore adding 1 does not overflow.
    return (bucket &+ 1) & _bucketMask
  }

  @warn_unused_result
  internal func _prev(bucket: Int) -> Int {
    // Bucket is not negative. Therefore subtracting 1 does not overflow.
    return (bucket &- 1) & _bucketMask
  }

  /// Search for a given key starting from the specified bucket.
  ///
  /// If the key is not present, returns the position where it could be
  /// inserted.
  @warn_unused_result
  internal
  func _find(key: Key, _ startBucket: Int) -> (pos: Index, found: Bool) {
    var bucket = startBucket

    // The invariant guarantees there's always a hole, so we just loop
    // until we find one
    while true {
      let isHole = !isInitializedEntry(bucket)
      if isHole {
        return (Index(nativeStorage: self, offset: bucket), false)
      }
      if keyAt(bucket) == key {
        return (Index(nativeStorage: self, offset: bucket), true)
      }
      bucket = _next(bucket)
    }
  }

  @_transparent
  @warn_unused_result
  internal static func getMinCapacity(
    requestedCount: Int, _ maxLoadFactorInverse: Double) -> Int {
    // `requestedCount + 1` below ensures that we don't fill in the last hole
    return max(Int(Double(requestedCount) * maxLoadFactorInverse),
               requestedCount + 1)
  }

  /// Storage should be uniquely referenced.
  /// The `key` should not be present in the NativeDictionary.
  /// This function does *not* update `count`.


  internal mutating func unsafeAddNew(key newKey: Key, value: Value) {
    let (i, found) = _find(newKey, _bucket(newKey))
    _sanityCheck(
      !found, "unsafeAddNew was called, but the key is already present")
    initializeKey(newKey, value: value, at: i.offset)
  }


  /// A textual representation of `self`.
  public // @testable
  var description: String {
    var result = ""
    #if INTERNAL_CHECKS_ENABLED
      for i in 0..<capacity {
        if isInitializedEntry(i) {
          let key = keyAt(i)
          result += "bucket \(i), ideal bucket = \(_bucket(key)), key = \(key)\n"
        } else {
          result += "bucket \(i), empty\n"
        }
      }
    #endif
    return result
  }

  //
  // _HashStorageType conformance
  //

  internal typealias Index = _NativeDictionaryIndex<Key, Value>

  internal var startIndex: Index {
    return Index(nativeStorage: self, offset: -1).successor()
  }

  internal var endIndex: Index {
    return Index(nativeStorage: self, offset: capacity)
  }

  @warn_unused_result
  internal func indexForKey(key: Key) -> Index? {
    if count == 0 {
      // Fast path that avoids computing the hash of the key.
      return nil
    }
    let (i, found) = _find(key, _bucket(key))
    return found ? i : nil
  }

  @warn_unused_result
  internal func assertingGet(i: Index) -> SequenceElement {
    _precondition(
      isInitializedEntry(i.offset),
      "attempting to access NativeDictionary elements using an invalid Index")
    let key = keyAt(i.offset)
    return (key, valueAt(i.offset))

  }

  @warn_unused_result
  internal func assertingGet(key: Key) -> Value {
    let (i, found) = _find(key, _bucket(key))
    _precondition(found, "key not found")
    return valueAt(i.offset)
  }

  @warn_unused_result
  internal func maybeGet(key: Key) -> Value? {
    if count == 0 {
      // Fast path that avoids computing the hash of the key.
      return nil
    }

    let (i, found) = _find(key, _bucket(key))
    if found {
      return valueAt(i.offset)
    }
    return nil
  }

  internal mutating func updateValue(value: Value, forKey: Key) -> Value? {
    _sanityCheckFailure(
      "don't call mutating methods on _NativeDictionaryStorage")
  }

  internal mutating func removeAtIndex(index: Index) -> SequenceElement {
    _sanityCheckFailure(
      "don't call mutating methods on _NativeDictionaryStorage")
  }

  internal mutating func removeValueForKey(key: Key) -> Value? {
    _sanityCheckFailure(
      "don't call mutating methods on _NativeDictionaryStorage")
  }

  internal mutating func removeAll(keepCapacity keepCapacity: Bool) {
    _sanityCheckFailure(
      "don't call mutating methods on _NativeDictionaryStorage")
  }

  @warn_unused_result
  internal static func fromArray(elements: [SequenceElement])
    -> _NativeDictionaryStorage<Key, Value> {

      let requiredCapacity =
        _NativeDictionaryStorage<Key, Value>.getMinCapacity(
          elements.count, _hashContainerDefaultMaxLoadFactorInverse)
      let nativeStorage = _NativeDictionaryStorage<Key, Value>(
        minimumCapacity: requiredCapacity)


      for (key, value) in elements {
        let (i, found) = nativeStorage._find(key, nativeStorage._bucket(key))
        _precondition(!found, "NativeDictionary literal contains duplicate keys")
        nativeStorage.initializeKey(key, value: value, at: i.offset)
      }
      nativeStorage.count = elements.count


      return nativeStorage
  }
}

/// This class is an artifact of the COW implementation.  This class only
/// exists to keep separate retain counts separate for:
/// - `NativeDictionary` and `NSDictionary`,
/// - `DictionaryIndex`.
///
/// This is important because the uniqueness check for COW only cares about
/// retain counts of the first kind.
///
/// Specifically, `NativeDictionary` points to instances of this class.  This class
/// is also a proper `NSDictionary` subclass, which is returned to Objective-C
/// during bridging.  `DictionaryIndex` points directly to
/// `_NativeDictionaryStorage`.
final internal class _NativeDictionaryStorageOwner<Key : Hashable, Value>
: NonObjectiveCBase {

  internal typealias NativeStorage = _NativeDictionaryStorage<Key, Value>


  internal init(minimumCapacity: Int = 2) {
    nativeStorage = NativeStorage(minimumCapacity: minimumCapacity)
    super.init()
  }

  internal init(nativeStorage: NativeStorage) {
    self.nativeStorage = nativeStorage
    super.init()
  }

  // This stored property should be stored at offset zero.  We perform atomic
  // operations on it.
  //
  // Do not access this property directly.
  internal var _heapBufferBridged_DoNotUse: AnyObject? = nil

  internal var nativeStorage: NativeStorage

}

internal enum _VariantDictionaryStorage<Key : Hashable, Value> : _HashStorageType {

  internal typealias NativeStorage = _NativeDictionaryStorage<Key, Value>
  internal typealias NativeStorageOwner =
    _NativeDictionaryStorageOwner<Key, Value>
  internal typealias NativeIndex = _NativeDictionaryIndex<Key, Value>
  internal typealias SequenceElement = (Key, Value)
  internal typealias SelfType = _VariantDictionaryStorage


  case Native(NativeStorageOwner)

  @_transparent
  internal var guaranteedNative: Bool {
    return true
  }

  @warn_unused_result
  internal mutating func isUniquelyReferenced() -> Bool {
    return _isUnique_native(&self)
  }

  internal var native: NativeStorage {
    switch self {
    case .Native(let owner):
      return owner.nativeStorage
    }
  }

  /// Ensure this we hold a unique reference to a native storage
  /// having at least `minimumCapacity` elements.
  internal mutating func ensureUniqueNativeStorage(minimumCapacity: Int)
    -> (reallocated: Bool, capacityChanged: Bool) {
      switch self {
      case .Native:
        let oldCapacity = native.capacity
        if isUniquelyReferenced() && oldCapacity >= minimumCapacity {
          return (reallocated: false, capacityChanged: false)
        }

        let oldNativeStorage = native
        let newNativeOwner = NativeStorageOwner(minimumCapacity: minimumCapacity)
        var newNativeStorage = newNativeOwner.nativeStorage
        let newCapacity = newNativeStorage.capacity
        for i in 0..<oldCapacity {
          if oldNativeStorage.isInitializedEntry(i) {
            if oldCapacity == newCapacity {
              let key = oldNativeStorage.keyAt(i)
              let value = oldNativeStorage.valueAt(i)
              newNativeStorage.initializeKey(key, value: value , at: i)
            } else {
              let key = oldNativeStorage.keyAt(i)
              newNativeStorage.unsafeAddNew(
                key: key,
                value: oldNativeStorage.valueAt(i))
            }
          }
        }
        newNativeStorage.count = oldNativeStorage.count

        self = .Native(newNativeOwner)
        return (reallocated: true,
                capacityChanged: oldCapacity != newNativeStorage.capacity)

      }
  }

  //
  // _HashStorageType conformance
  //

  internal typealias Index = DictionaryIndex<Key, Value>

  internal var startIndex: Index {
    switch self {
    case .Native:
      return ._Native(native.startIndex)
    }
  }

  internal var endIndex: Index {
    switch self {
    case .Native:
      return ._Native(native.endIndex)
    }
  }

  @warn_unused_result
  internal func indexForKey(key: Key) -> Index? {
    switch self {
    case .Native:
      if let nativeIndex = native.indexForKey(key) {
        return ._Native(nativeIndex)
      }
      return nil
    }
  }

  @warn_unused_result
  internal func assertingGet(i: Index) -> SequenceElement {
    switch self {
    case .Native:
      return native.assertingGet(i._nativeIndex)
    }
  }

  @warn_unused_result
  internal func assertingGet(key: Key) -> Value {
    switch self {
    case .Native:
      return native.assertingGet(key)
    }
  }

  @warn_unused_result
  internal func maybeGet(key: Key) -> Value? {
    switch self {
    case .Native:
      return native.maybeGet(key)
    }
  }

  internal mutating func nativeUpdateValue(
    value: Value, forKey key: Key
    ) -> Value? {
    var (i, found) = native._find(key, native._bucket(key))

    let minCapacity = found
      ? native.capacity
      : NativeStorage.getMinCapacity(
        native.count + 1,
        native.maxLoadFactorInverse)

    let (_, capacityChanged) = ensureUniqueNativeStorage(minCapacity)
    if capacityChanged {
      i = native._find(key, native._bucket(key)).pos
    }

    let oldValue: Value? = found ? native.valueAt(i.offset) : nil
    if found {
      native.setKey(key, value: value, at: i.offset)
    } else {
      native.initializeKey(key, value: value, at: i.offset)
      native.count += 1
    }

    return oldValue
  }

  internal mutating func updateValue(
    value: Value, forKey key: Key
    ) -> Value? {

    return nativeUpdateValue(value, forKey: key)
  }

  /// - parameter idealBucket: The ideal bucket for the element being deleted.
  /// - parameter offset: The offset of the element that will be deleted.
  /// Requires an initialized entry at offset.
  internal mutating func nativeDeleteImpl(
    nativeStorage: NativeStorage, idealBucket: Int, offset: Int
    ) {
    _sanityCheck(
      nativeStorage.isInitializedEntry(offset), "expected initialized entry")

    // remove the element
    nativeStorage.destroyEntryAt(offset)
    nativeStorage.count -= 1

    // If we've put a hole in a chain of contiguous elements, some
    // element after the hole may belong where the new hole is.
    var hole = offset

    // Find the first bucket in the contiguous chain
    var start = idealBucket
    while nativeStorage.isInitializedEntry(nativeStorage._prev(start)) {
      start = nativeStorage._prev(start)
    }

    // Find the last bucket in the contiguous chain
    var lastInChain = hole
    var b = nativeStorage._next(lastInChain)
    while nativeStorage.isInitializedEntry(b) {
      lastInChain = b
      b = nativeStorage._next(b)
    }

    // Relocate out-of-place elements in the chain, repeating until
    // none are found.
    while hole != lastInChain {
      // Walk backwards from the end of the chain looking for
      // something out-of-place.
      var b = lastInChain
      while b != hole {
        let idealBucket = nativeStorage._bucket(nativeStorage.keyAt(b))

        // Does this element belong between start and hole?  We need
        // two separate tests depending on whether [start,hole] wraps
        // around the end of the buffer
        let c0 = idealBucket >= start
        let c1 = idealBucket <= hole
        if start <= hole ? (c0 && c1) : (c0 || c1) {
          break // Found it
        }
        b = nativeStorage._prev(b)
      }

      if b == hole { // No out-of-place elements found; we're done adjusting
        break
      }

      // Move the found element into the hole
      nativeStorage.moveInitializeFrom(nativeStorage, at: b, toEntryAt: hole)
      hole = b
    }
  }

  internal mutating func nativeRemoveObjectForKey(key: Key) -> Value? {
    var nativeStorage = native
    var idealBucket = nativeStorage._bucket(key)
    var (index, found) = nativeStorage._find(key, idealBucket)

    // Fast path: if the key is not present, we will not mutate the set,
    // so don't force unique storage.
    if !found {
      return nil
    }

    let (reallocated, capacityChanged) =
      ensureUniqueNativeStorage(nativeStorage.capacity)
    if reallocated {
      nativeStorage = native
    }
    if capacityChanged {
      idealBucket = nativeStorage._bucket(key)
      (index, found) = nativeStorage._find(key, idealBucket)
      _sanityCheck(found, "key was lost during storage migration")
    }
    let oldValue = nativeStorage.valueAt(index.offset)
    nativeDeleteImpl(nativeStorage, idealBucket: idealBucket,
                     offset: index.offset)
    return oldValue
  }

  internal mutating func nativeRemoveAtIndex(
    nativeIndex: NativeIndex
    ) -> SequenceElement {
    var nativeStorage = native

    // The provided index should be valid, so we will always mutating the
    // set storage.  Request unique storage.
    let (reallocated, _) = ensureUniqueNativeStorage(nativeStorage.capacity)
    if reallocated {
      nativeStorage = native
    }

    let result = nativeStorage.assertingGet(nativeIndex)
    let key = result.0

    nativeDeleteImpl(nativeStorage, idealBucket: nativeStorage._bucket(key),
                     offset: nativeIndex.offset)
    return result
  }

  internal mutating func removeAtIndex(index: Index) -> SequenceElement {
    return nativeRemoveAtIndex(index._nativeIndex)
  }

  internal mutating func removeValueForKey(key: Key) -> Value? {
    return nativeRemoveObjectForKey(key)
  }

  internal mutating func nativeRemoveAll() {
    var nativeStorage = native

    // FIXME(performance): if the storage is non-uniquely referenced, we
    // shouldn't be copying the elements into new storage and then immediately
    // deleting the elements. We should detect that the storage is not uniquely
    // referenced and allocate new empty storage of appropriate capacity.

    // We have already checked for the empty dictionary case, so we will always
    // mutating the dictionary storage.  Request unique storage.
    let (reallocated, _) = ensureUniqueNativeStorage(nativeStorage.capacity)
    if reallocated {
      nativeStorage = native
    }

    for b in 0..<nativeStorage.capacity {
      if nativeStorage.isInitializedEntry(b) {
        nativeStorage.destroyEntryAt(b)
      }
    }
    nativeStorage.count = 0
  }

  internal mutating func removeAll(keepCapacity keepCapacity: Bool) {
    if count == 0 {
      return
    }

    if !keepCapacity {
      self = .Native(NativeStorage.Owner(minimumCapacity: 2))
      return
    }

    nativeRemoveAll()
    return
  }

  internal var count: Int {
    switch self {
    case .Native:
      return native.count
    }
  }

  /// Returns a generator over the (Key, Value) pairs.
  ///
  /// - Complexity: O(1).
  internal func generate() -> DictionaryGenerator<Key, Value> {
    switch self {
    case .Native(let owner):
      return
        ._Native(start: native.startIndex, end: native.endIndex, owner: owner)
    }
  }

  @warn_unused_result
  internal static func fromArray(elements: [SequenceElement])
    -> _VariantDictionaryStorage<Key, Value> {

      _sanityCheckFailure("this function should never be called")
  }
}

internal struct _NativeDictionaryIndex<Key : Hashable, Value> :
ForwardIndexType, Comparable {

  internal typealias NativeStorage = _NativeDictionaryStorage<Key, Value>
  internal typealias NativeIndex = _NativeDictionaryIndex<Key, Value>

  internal var nativeStorage: NativeStorage
  internal var offset: Int

  internal init(nativeStorage: NativeStorage, offset: Int) {
    self.nativeStorage = nativeStorage
    self.offset = offset
  }

  /// Returns the next consecutive value after `self`.
  ///
  /// - Requires: The next value is representable.
  @warn_unused_result
  internal func successor() -> NativeIndex {
    var i = offset + 1
    // FIXME: Can't write the simple code pending
    // <rdar://problem/15484639> Refcounting bug
    while i < nativeStorage.capacity /*&& !nativeStorage[i]*/ {
      // FIXME: workaround for <rdar://problem/15484639>
      if nativeStorage.isInitializedEntry(i) {
        break
      }
      // end workaround
      i += 1
    }
    return NativeIndex(nativeStorage: nativeStorage, offset: i)
  }
}

internal func == <Key : Hashable, Value> (
  lhs: _NativeDictionaryIndex<Key, Value>,
  rhs: _NativeDictionaryIndex<Key, Value>
  ) -> Bool {
  // FIXME: assert that lhs and rhs are from the same dictionary.
  return lhs.offset == rhs.offset
}

internal func < <Key : Hashable, Value> (
  lhs: _NativeDictionaryIndex<Key, Value>,
  rhs: _NativeDictionaryIndex<Key, Value>
  ) -> Bool {
  // FIXME: assert that lhs and rhs are from the same dictionary.
  return lhs.offset < rhs.offset
}

internal enum DictionaryIndexRepresentation<Key : Hashable, Value> {
  typealias _Index = DictionaryIndex<Key, Value>
  typealias _NativeIndex = _Index._NativeIndex

  case _Native(_NativeIndex)
}


/// Used to access the key-value pairs in an instance of
/// `NativeDictionary<Key, Value>`.
///
/// NativeDictionary has two subscripting interfaces:
///
/// 1. Subscripting with a key, yielding an optional value:
///
///        v = d[k]!
///
/// 2. Subscripting with an index, yielding a key-value pair:
///
///        (k,v) = d[i]
public struct DictionaryIndex<Key : Hashable, Value> :
ForwardIndexType, Comparable {
  // Index for native storage is efficient.  Index for bridged NSDictionary is
  // not, because neither NSEnumerator nor fast enumeration support moving
  // backwards.  Even if they did, there is another issue: NSEnumerator does
  // not support NSCopying, and fast enumeration does not document that it is
  // safe to copy the state.  So, we cannot implement Index that is a value
  // type for bridged NSDictionary in terms of Cocoa enumeration facilities.

  internal typealias _NativeIndex = _NativeDictionaryIndex<Key, Value>


  internal var _value: DictionaryIndexRepresentation<Key, Value>

  internal static func _Native(index: _NativeIndex) -> DictionaryIndex {
    return DictionaryIndex(_value: ._Native(index))
  }

  @_transparent
  internal var _guaranteedNative: Bool {
    return true
  }

  @_transparent
  internal var _nativeIndex: _NativeIndex {
    switch _value {
    case ._Native(let nativeIndex):
      return nativeIndex
    }
  }

  /// Returns the next consecutive value after `self`.
  ///
  /// - Requires: The next value is representable.
  public func successor() -> DictionaryIndex<Key, Value> {
    return ._Native(_nativeIndex.successor())
  }
}

@warn_unused_result
public func == <Key : Hashable, Value> (
  lhs: DictionaryIndex<Key, Value>,
  rhs: DictionaryIndex<Key, Value>
  ) -> Bool {
  return lhs._nativeIndex == rhs._nativeIndex
}

@warn_unused_result
public func < <Key : Hashable, Value> (
  lhs: DictionaryIndex<Key, Value>,
  rhs: DictionaryIndex<Key, Value>
  ) -> Bool {
  return lhs._nativeIndex < rhs._nativeIndex
}

internal enum DictionaryGeneratorRepresentation<Key : Hashable, Value> {
  internal typealias _Generator = DictionaryGenerator<Key, Value>
  internal typealias _NativeStorageOwner =
    _NativeDictionaryStorageOwner<Key, Value>
  internal typealias _NativeIndex = _Generator._NativeIndex

  // For native storage, we keep two indices to keep track of the iteration
  // progress and the storage owner to make the storage non-uniquely
  // referenced.
  //
  // While indices keep the storage alive, they don't affect reference count of
  // the storage.  Generator is iterating over a frozen view of the collection
  // state, so it should keep its own reference to the storage owner.
  case _Native(
    start: _NativeIndex, end: _NativeIndex, owner: _NativeStorageOwner)
}

/// A generator over the members of a `NativeDictionary<Key, Value>`.
public struct DictionaryGenerator<Key : Hashable, Value> : GeneratorType {
  // NativeDictionary has a separate GeneratorType and Index because of efficiency
  // and implementability reasons.
  //
  // Index for native storage is efficient.  Index for bridged NSDictionary is
  // not.
  //
  // Even though fast enumeration is not suitable for implementing
  // Index, which is multi-pass, it is suitable for implementing a
  // GeneratorType, which is being consumed as iteration proceeds.

  internal typealias _NativeStorageOwner =
    _NativeDictionaryStorageOwner<Key, Value>
  internal typealias _NativeIndex = _NativeDictionaryIndex<Key, Value>


  internal var _state: DictionaryGeneratorRepresentation<Key, Value>

  internal static func _Native(
    start start: _NativeIndex, end: _NativeIndex, owner: _NativeStorageOwner
    ) -> DictionaryGenerator {
    return DictionaryGenerator(
      _state: ._Native(start: start, end: end, owner: owner))
  }

  @_transparent
  internal var _guaranteedNative: Bool {
    return true
  }

  internal mutating func _nativeNext() -> (Key, Value)? {
    switch _state {
    case ._Native(let startIndex, let endIndex, let owner):
      if startIndex == endIndex {
        return nil
      }
      let result = startIndex.nativeStorage.assertingGet(startIndex)
      _state =
        ._Native(start: startIndex.successor(), end: endIndex, owner: owner)
      return result
    }
  }

  /// Advance to the next element and return it, or `nil` if no next
  /// element exists.
  ///
  /// - Requires: No preceding call to `self.next()` has returned `nil`.
  public mutating func next() -> (Key, Value)? {
    return _nativeNext()
  }
}

internal struct DictionaryMirrorPosition<Key : Hashable, Value> {
  internal typealias MirroredType = NativeDictionary<Key, Value>
  
  internal var _intPos: Int
  internal var DictionaryPos: MirroredType.Index
  
  internal init(_ m: MirroredType) {
    _intPos = 0
    DictionaryPos = m.startIndex
  }
  
  internal mutating func successor() {
    _intPos = _intPos + 1
    DictionaryPos._successorInPlace()
  }
  
}

@warn_unused_result
internal func == <Key : Hashable, Value> (
  lhs: DictionaryMirrorPosition<Key, Value>, rhs : Int
  ) -> Bool {
  return lhs._intPos == rhs
}

@warn_unused_result
internal func > <Key : Hashable, Value> (
  lhs: DictionaryMirrorPosition<Key, Value>, rhs : Int
  ) -> Bool {
  return lhs._intPos > rhs
}

@warn_unused_result
internal func < <Key : Hashable, Value> (
  lhs: DictionaryMirrorPosition<Key, Value>, rhs : Int
  ) -> Bool {
  return lhs._intPos < rhs
}

internal class DictionaryMirror<Key : Hashable, Value> : _MirrorType {
  typealias MirroredType = NativeDictionary<Key, Value>
  internal let _mirror : MirroredType
  internal var _pos : DictionaryMirrorPosition<Key, Value>
  
  internal init(_ m : MirroredType) {
    _mirror = m
    _pos = DictionaryMirrorPosition(m)
  }
  
  internal var value: Any { return (_mirror as Any) }
  
  internal var valueType: Any.Type { return (_mirror as Any).dynamicType }
  
  internal var objectIdentifier: ObjectIdentifier? { return nil }
  
  internal var count: Int { return _mirror.count }
  
  internal subscript(i: Int) -> (String, _MirrorType) {
    _precondition(i >= 0 && i < count, "_MirrorType access out of bounds")
    
    if _pos > i {
      _pos._intPos = 0
    }
    
    while _pos < i && !(_pos == i) {
      _pos.successor()
    }
    return ("[\(_pos._intPos)]", _reflect(_mirror[_pos.DictionaryPos]))
  }
  
  internal var summary: String {
    if count == 1 {
      return "1 key/value pair"
    }
    return "\(count) key/value pairs"
  }
  
  internal var quickLookObject: PlaygroundQuickLook? { return nil }
  
  internal var disposition: _MirrorDisposition { return .KeyContainer }
}

extension NativeDictionary : _Reflectable {
  /// Returns a mirror that reflects `self`.
  @warn_unused_result
  public func _getMirror() -> _MirrorType {
    return DictionaryMirror(self)
  }
}

/// Initializes `a NativeDictionary` from unique members.
///
/// Using a builder can be faster than inserting members into an empty
/// `NativeDictionary`.
public struct _DictionaryBuilder<Key : Hashable, Value> {
  
  internal var _result: NativeDictionary<Key, Value>
  internal var _nativeStorage: _NativeDictionaryStorage<Key, Value>
  internal let _requestedCount: Int
  internal var _actualCount: Int
  
  public init(count: Int) {
    let requiredCapacity =
      _NativeDictionaryStorage<Key, Value>.getMinCapacity(
        count, _hashContainerDefaultMaxLoadFactorInverse)
    _result = NativeDictionary<Key, Value>(minimumCapacity: requiredCapacity)
    _nativeStorage = _result._variantStorage.native
    _requestedCount = count
    _actualCount = 0
  }
  
  public mutating func add(key newKey: Key, value: Value) {
    _nativeStorage.unsafeAddNew(key: newKey, value: value)
    _actualCount += 1
  }
  
  @warn_unused_result
  public mutating func take() -> NativeDictionary<Key, Value> {
    _precondition(_actualCount >= 0,
                  "cannot take the result twice")
    _precondition(_actualCount == _requestedCount,
                  "the number of members added does not match the promised count")
    
    // Finish building the `NativeDictionary`.
    _nativeStorage.count = _requestedCount
    
    // Prevent taking the result twice.
    _actualCount = -1
    return _result
  }
}

extension NativeDictionary {
  /// If `!self.isEmpty`, return the first key-value pair in the sequence of
  /// elements, otherwise return `nil`.
  ///
  /// - Complexity: Amortized O(1)
  public mutating func popFirst() -> Element? {
    guard !isEmpty else { return nil }
    return removeAtIndex(startIndex)
  }
}
