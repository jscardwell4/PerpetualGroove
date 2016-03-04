//
//  WeakArray.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

private final class WeakArrayStorage<Element: AnyObject>:
  ManagedBuffer<(count: Int, capacity: Int), Weak<Element>>
{
  class func create(capacity: Int) -> WeakArrayStorage {
    return super.create(capacity) {
      (count: 0, capacity: $0.allocatedElementCount)
      } as! WeakArrayStorage
  }

  var elements: UnsafeMutablePointer<Weak<Element>> {
    return withUnsafeMutablePointerToElements {$0}
  }

  var count: Int {
    get { return withUnsafeMutablePointerToValue { $0.memory.count } }
    set { withUnsafeMutablePointerToValue { $0.memory.count = newValue } }
  }

  var capacity: Int { return value.capacity }

  func purge() -> Int {
    return withUnsafeMutablePointers {
      value, elements in
      var purgeCount = 0
      var i = 0
      while i < value.memory.count {
        guard elements[i].reference == nil else { i += 1; continue }
        purgeCount += 1
        guard i.successor() < value.memory.count else { (elements + i).destroy(); break }
        (elements + i).moveAssignFrom(elements + i.successor(), count: value.memory.count - i)
      }
      value.memory.count -= purgeCount
      return purgeCount
    }
  }

  func clone(purge: Bool = true) -> WeakArrayStorage<Element> {
    if purge { self.purge() }
    return withUnsafeMutablePointers {
      oldValue, oldElements in
      WeakArrayStorage<Element>.create(oldValue.memory.capacity) {
        $0.withUnsafeMutablePointerToElements {
          $0.initializeFrom(oldElements, count: oldValue.memory.count)
        }
        return oldValue.memory
        } as! WeakArrayStorage<Element>
    }
  }

  func resize(newSize: Int, purge: Bool = true) -> WeakArrayStorage<Element> {
    if purge { self.purge() }
    return withUnsafeMutablePointers {
      oldValue, oldElements in
      WeakArrayStorage<Element>.create(newSize) {
        $0.withUnsafeMutablePointerToElements {
          $0.moveInitializeFrom(oldElements, count: oldValue.memory.count)
        }
        return (count: oldValue.memory.count, capacity: newSize)
        } as! WeakArrayStorage<Element>
    }
  }
}

extension WeakArrayStorage: CustomStringConvertible {
  var description: String {
    return withUnsafeMutablePointers {
      value, elements in
      var result = "count = \(value.memory.count), capacity = \(value.memory.capacity)\n"
      result += "["
      var first = true
      for i in 0 ..< value.memory.count {
        if first { first = false }
        else { result += ", " }
        result += "\(elements[i])"
      }
      result += "]"
      return result
    }
  }
}



public struct UnfilteredWeakArrayBuffer<Element:AnyObject>: MutableCollectionType, RangeReplaceableCollectionType {
  private typealias Storage = WeakArrayStorage<Element>

  private var storage: Storage
  public typealias _Element = Element?

  public init() { storage = Storage.create(0) }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    let array = sequence.map {Weak<Element>($0)}
    storage = Storage.create(array.count)
    storage.elements.initializeFrom(array)
    storage.count = array.count
  }

  /// Get or set the index'th element.
  public subscript(index: Int) -> _Element {
    get {
      precondition(index < count, "Index '\(index)' ≥ count '\(count)'")
      return storage.elements[index].reference
    }
    nonmutating set {
      precondition(index < count, "Index '\(index)' ≥ count '\(count)'")
      // FIXME: Manually swap because it makes the ARC optimizer happy.  See
      // <rdar://problem/16831852> check retain/release order
      // firstElementAddress[i] = newValue
      var nv = newValue
      let tmp = nv
      nv = firstElementAddress[index].reference
      firstElementAddress[index] = Weak<Element>(tmp)
    }
  }

  /// Call `body(p)`, where `p` is an `UnsafeBufferPointer` over the
  /// underlying contiguous storage.  If no such storage exists, it is
  /// created on-demand.
  func withUnsafeBufferPointer<R>(
    @noescape body: (UnsafeBufferPointer<Weak<Element>>) throws -> R
    ) rethrows -> R
  {
    defer { _fixLifetime(self) }
    return try body(UnsafeBufferPointer(start: firstElementAddress, count: count))
  }

  /// Call `body(p)`, where `p` is an `UnsafeMutableBufferPointer`
  /// over the underlying contiguous storage.
  ///
  /// - Requires: Such contiguous storage exists or the buffer is empty.
  mutating func withUnsafeMutableBufferPointer<R>(
    @noescape body: (UnsafeMutableBufferPointer<Weak<Element>>) throws -> R
    ) rethrows -> R
  {
    defer { _fixLifetime(self) }
    return try body(UnsafeMutableBufferPointer(start: firstElementAddress, count: count))
  }

  /// The number of elements the buffer stores.
  public var count: Int { get { return storage.count } set { storage.count = newValue } }

  /// The number of elements the buffer can store without reallocation.
  public var capacity: Int { return storage.capacity }

  /// An object that keeps the elements stored in this buffer alive.
  var owner: AnyObject { return storage }

  /// If the elements are stored contiguously, a pointer to the first
  /// element. Otherwise, `nil`.
  var firstElementAddress: UnsafeMutablePointer<Weak<Element>> { return storage.elements }

  /// A value that identifies the storage used by the buffer.  Two
  /// buffers address the same elements when they have the same
  /// identity and count.
  var identity: UnsafePointer<Void> { return withUnsafeBufferPointer { UnsafePointer($0.baseAddress) } }
  
  public var startIndex: Int { return 0 }
  public var endIndex: Int { return count }

  /**
   ensureUniqueWithCapacity:

   - parameter capacity: Int
  */
  private mutating func ensureUniqueWithCapacity(capacity: Int) {
    guard !(isUniquelyReferenced(&storage) && storage.capacity >= capacity) else { return }
    guard storage.capacity < capacity else { storage = storage.clone(); return }
    let newStorage = Storage.create(capacity)
    newStorage.elements.moveInitializeFrom(storage.elements, count: storage.count)
    newStorage.count = storage.count
    storage = newStorage
  }

  /**
   append:

   - parameter element: Pointee
  */
  public mutating func append(element: Element) {
    let minimumCapacity = storage.capacity > storage.count
                            ? storage.capacity
                            : max(storage.capacity, 1) * 2
    ensureUniqueWithCapacity(minimumCapacity)
    (storage.elements + storage.count).initialize(Weak(element))
    storage.count += 1
  }

  public func generate() -> AnyGenerator<_Element> {
    var index = 0
    return AnyGenerator {
      [storage = storage] in
      guard index < storage.count else { return nil }
      let element = storage.elements[index].reference
      index += 1
      return element
    }
  }

  public func indexOf(element: Element) -> Int? {
    let elements = storage.elements
    for i in 0 ..< count {
      guard let e = elements[i].reference else { continue }
      guard e === element else { continue }
      return i
    }
    return nil
  }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == _Element>(subRange: Range<Int>, with newElements: C)
  {
    defer { _fixLifetime(self); _fixLifetime(storage) }
    let oldCount = storage.count
    let removeCount: Int = subRange.count
    let insertCount: Int = numericCast(newElements.count)
    let newCount = oldCount - removeCount + insertCount
    ensureUniqueWithCapacity(newCount)

    let elements = storage.elements
    for (index, offset) in subRange.enumerate() {
      let elementPointer = elements + offset
      if index < insertCount {
        let element = newElements[newElements.startIndex.advancedBy(numericCast(index))]
        let weakElement = Weak<Element>(element)
        elementPointer.initialize(weakElement)
      } else {
        elementPointer.destroy()
      }
    }

    // Return early if we don't need to shift old elements or insert remaining new elements
    guard removeCount != insertCount else { return }

    // Check if we need to shift old elements
    if subRange.endIndex < storage.count {

      // Shift forward when removing more elements than are being inserted
      if removeCount > insertCount {
        let moveCount = storage.count - subRange.endIndex
        let moveSource = elements + subRange.endIndex
        let destination = elements + subRange.startIndex.advancedBy(insertCount)
        destination.moveAssignFrom(moveSource, count: moveCount)
      }

      // Shift backward when inserting more elements than are being removed
      else if removeCount < insertCount {
        let moveCount = storage.count - subRange.endIndex
        let moveSource = elements + subRange.endIndex

        let oldElementsDestinationOffset = subRange.startIndex.advancedBy(insertCount)
        let oldElementsDestination = elements + oldElementsDestinationOffset

        oldElementsDestination.moveInitializeBackwardFrom(moveSource, count: moveCount)

        let uninsertedElementsDestinationOffset = subRange.endIndex
        let uinsertedElementsDestination = elements + uninsertedElementsDestinationOffset

        let uninsertedElements = newElements[newElements.startIndex.advancedBy(numericCast(removeCount))..<].map({
          Weak<Element>($0 as? Element)
        })

        uinsertedElementsDestination.initializeFrom(uninsertedElements)

      }
    }
    storage.count = newCount
  }
}

extension UnfilteredWeakArrayBuffer: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) { self.init(elements) }
}

extension UnfilteredWeakArrayBuffer: CustomStringConvertible, CustomDebugStringConvertible {
  private var elementsDescription: String {
    defer { _fixLifetime(self) }
    var result = "["
    var first = true
    for i in 0 ..< count {
      if first { first = false }
      else { result += ", " }
      result += "\(self[i])"
    }
    result += "]"
    return result
  }
  public var description: String { return elementsDescription }
  public var debugDescription: String { return storage.description }
}

public struct FilteredWeakArrayBuffer<Element:AnyObject>: MutableCollectionType, RangeReplaceableCollectionType {
  private typealias Storage = WeakArrayStorage<Element>
  public typealias _Element = Element

  private var storage: Storage
  private var needsPurge = false

  public init() { storage = Storage.create(0) }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    let array = sequence.map {Weak<Element>($0)}
    storage = Storage.create(array.count)
    storage.elements.initializeFrom(array)
    storage.count = array.count
  }

  /// Get or set the index'th element.
  public subscript(index: Int) -> _Element {
    get {
      let index = index - storage.purge()
      precondition(index < _count, "Index '\(index)' ≥ count '\(_count)'")
      guard let result = storage.elements[index].reference else {
        fatalError("unexpected nil weak reference")
      }
      return result
    }
    nonmutating set {
      precondition(index < count, "Index '\(index)' ≥ count '\(count)'")
      // FIXME: Manually swap because it makes the ARC optimizer happy.  See
      // <rdar://problem/16831852> check retain/release order
      // firstElementAddress[i] = newValue
      var nv = Optional(newValue)
      let tmp = nv
      nv = firstElementAddress[index].reference
      firstElementAddress[index] = Weak<Element>(tmp)
    }
  }

  /// Call `body(p)`, where `p` is an `UnsafeBufferPointer` over the
  /// underlying contiguous storage.  If no such storage exists, it is
  /// created on-demand.
  func withUnsafeBufferPointer<R>(
    @noescape body: (UnsafeBufferPointer<Weak<Element>>) throws -> R
    ) rethrows -> R
  {
    defer { _fixLifetime(self) }
    return try body(UnsafeBufferPointer(start: firstElementAddress, count: count))
  }

  /// Call `body(p)`, where `p` is an `UnsafeMutableBufferPointer`
  /// over the underlying contiguous storage.
  ///
  /// - Requires: Such contiguous storage exists or the buffer is empty.
  mutating func withUnsafeMutableBufferPointer<R>(
    @noescape body: (UnsafeMutableBufferPointer<Weak<Element>>) throws -> R
    ) rethrows -> R
  {
    defer { _fixLifetime(self) }
    return try body(UnsafeMutableBufferPointer(start: firstElementAddress, count: count))
  }

  private var _count: Int { get { return storage.count } set { storage.count = newValue } }

  /// The number of elements the buffer stores.
  public var count: Int { get { storage.purge(); return _count } set { _count = newValue } }

  /// The number of elements the buffer can store without reallocation.
  public var capacity: Int { return storage.capacity }

  /// An object that keeps the elements stored in this buffer alive.
  var owner: AnyObject { return storage }

  /// If the elements are stored contiguously, a pointer to the first
  /// element. Otherwise, `nil`.
  var firstElementAddress: UnsafeMutablePointer<Weak<Element>> { return storage.elements }

  /// A value that identifies the storage used by the buffer.  Two
  /// buffers address the same elements when they have the same
  /// identity and count.
  var identity: UnsafePointer<Void> { return withUnsafeBufferPointer { UnsafePointer($0.baseAddress) } }
  
  public var startIndex: Int { return 0 }
  public var endIndex: Int { return count }

  /**
   ensureUniqueWithCapacity:

   - parameter capacity: Int
  */
  private mutating func ensureUniqueWithCapacity(capacity: Int) {
    storage.purge()
    guard !(isUniquelyReferenced(&storage) && storage.capacity >= capacity) else { return }
    guard storage.capacity < capacity else { storage = storage.clone(); return }
    let newStorage = Storage.create(capacity)
    newStorage.elements.moveInitializeFrom(storage.elements, count: storage.count)
    newStorage.count = storage.count
    storage = newStorage
  }

  /**
   append:

   - parameter element: Pointee
  */
  public mutating func append(element: Element) {
    let minimumCapacity = storage.capacity > storage.count
                            ? storage.capacity
                            : max(storage.capacity, 1) * 2
    ensureUniqueWithCapacity(minimumCapacity)
    (storage.elements + storage.count).initialize(Weak(element))
    storage.count += 1
  }

  public func generate() -> AnyGenerator<_Element> {
    storage.purge()
    var index = 0
    return AnyGenerator {
      [storage = storage] in
      guard index < storage.count else { return nil }
      guard let element = storage.elements[index].reference else {
        fatalError("expected weak reference not to be nil")
      }
      index += 1
      return element
    }
  }

  public func indexOf(element: Element) -> Int? {
    let elements = storage.elements
    for i in 0 ..< count {
      guard let e = elements[i].reference else { fatalError("expected weak reference not to be nil") }
      guard e === element else { continue }
      return i
    }
    return nil
  }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == _Element>(subRange: Range<Int>, with newElements: C)
  {
    defer { _fixLifetime(self); _fixLifetime(storage) }
    let purgeCount = storage.purge()
    assert(subRange.endIndex <= _count, "purging \(purgeCount) invalidated subRange '\(subRange)'")
    let oldCount = storage.count
    let removeCount: Int = subRange.count
    let insertCount: Int = numericCast(newElements.count)
    let newCount = oldCount - removeCount + insertCount
    ensureUniqueWithCapacity(newCount)

    let elements = storage.elements
    for (index, offset) in subRange.enumerate() {
      let elementPointer = elements + offset
      if index < insertCount {
        let element = newElements[newElements.startIndex.advancedBy(numericCast(index))]
        let weakElement = Weak<Element>(element)
        elementPointer.initialize(weakElement)
      } else {
        elementPointer.destroy()
      }
    }

    // Return early if we don't need to shift old elements or insert remaining new elements
    guard removeCount != insertCount else { return }

    // Check if we need to shift old elements
    if subRange.endIndex < storage.count {

      // Shift forward when removing more elements than are being inserted
      if removeCount > insertCount {
        let moveCount = storage.count - subRange.endIndex
        let moveSource = elements + subRange.endIndex
        let destination = elements + subRange.startIndex.advancedBy(insertCount)
        destination.moveAssignFrom(moveSource, count: moveCount)
      }

      // Shift backward when inserting more elements than are being removed
      else if removeCount < insertCount {
        let moveCount = storage.count - subRange.endIndex
        let moveSource = elements + subRange.endIndex

        let oldElementsDestinationOffset = subRange.startIndex.advancedBy(insertCount)
        let oldElementsDestination = elements + oldElementsDestinationOffset

        oldElementsDestination.moveInitializeBackwardFrom(moveSource, count: moveCount)

        let uninsertedElementsDestinationOffset = subRange.endIndex
        let uinsertedElementsDestination = elements + uninsertedElementsDestinationOffset

        let uninsertedElements = newElements[newElements.startIndex.advancedBy(numericCast(removeCount))..<].map({
          Weak<Element>($0 as? Element)
        })

        uinsertedElementsDestination.initializeFrom(uninsertedElements)

      }
    }
    storage.count = newCount
  }
}

extension FilteredWeakArrayBuffer: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) { self.init(elements) }
}

extension FilteredWeakArrayBuffer: CustomStringConvertible, CustomDebugStringConvertible {
  private var elementsDescription: String {
    defer { _fixLifetime(self) }
    var result = "["
    var first = true
    for i in 0 ..< count {
      if first { first = false }
      else { result += ", " }
      result += "\(self[i])"
    }
    result += "]"
    return result
  }
  public var description: String { return elementsDescription }
  public var debugDescription: String { return storage.description }
}


public struct WeakArray<Element:AnyObject>: MutableCollectionType, RangeReplaceableCollectionType {
  private var storage: WeakArrayStorage<Element>
//  public typealias Generator = IndexingGenerator<WeakArray<Element>>
  public typealias _Element = Element?
//  private var elements: [Element] { return storage.elements }

  public var startIndex: Int { return 0 }
  public var endIndex: Int { return storage.count }

  public subscript(position: Int) -> Element? {
    get {
      precondition(position < count, "Index '\(position)' ≥ count '\(count)'")
      let weakElement = storage.elements[position]
      return weakElement.reference
    }
    set {
      precondition(position < count, "Index '\(position)' ≥ count '\(count)'")
      storage.elements[position] = Weak(newValue)
    }
  }

  public var count: Int { defer { _fixLifetime(storage) }; return storage.count }

  private mutating func ensureUniqueWithCapacity(capacity: Int) {
    guard !(isUniquelyReferenced(&storage) && storage.capacity >= capacity) else { return }
    guard storage.capacity < capacity else { storage = storage.clone(); return }
    let newStorage = WeakArrayStorage<Element>.create(capacity)
    newStorage.elements.moveInitializeFrom(storage.elements, count: storage.count)
    newStorage.count = storage.count
    storage = newStorage
  }

  public mutating func append(element: Element) {
    let minimumCapacity = storage.capacity > storage.count
                            ? storage.capacity
                            : max(storage.capacity, 1) * 2
    ensureUniqueWithCapacity(minimumCapacity)
    (storage.elements + storage.count).initialize(Weak(element))
    storage.count += 1
  }

  public init() { storage = WeakArrayStorage<Element>.create(0) }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    let array = sequence.map {Weak<Element>($0)}
    storage = WeakArrayStorage<Element>.create(array.count)
    storage.elements.initializeFrom(array)
    storage.count = array.count
  }

  public func generate() -> AnyGenerator<Element?> {
    var index = 0
    return AnyGenerator {
      [storage = storage] in
      guard index < storage.count else { return nil }
      let element = storage.elements[index].reference
      index += 1
      return element
    }
  }

  public func indexOf(element: Element) -> Int? {
    let elements = storage.elements
    for i in 0 ..< count {
      guard let e = elements[i].reference else { continue }
      guard e === element else { continue }
      return i
    }
    return nil
  }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element?>(subRange: Range<Int>, with newElements: C)
  {
    defer { _fixLifetime(self); _fixLifetime(storage) }
    let oldCount = storage.count
    let removeCount: Int = subRange.count
    let insertCount: Int = numericCast(newElements.count)
    let newCount = oldCount - removeCount + insertCount
    ensureUniqueWithCapacity(newCount)

    let elements = storage.elements
    for (index, offset) in subRange.enumerate() {
      let elementPointer = elements + offset
      if index < insertCount {
        let element = newElements[newElements.startIndex.advancedBy(numericCast(index))]
        let weakElement = Weak<Element>(element)
        elementPointer.initialize(weakElement)
      } else {
        elementPointer.destroy()
      }
    }

    // Return early if we don't need to shift old elements or insert remaining new elements
    guard removeCount != insertCount else { return }

    // Check if we need to shift old elements
    if subRange.endIndex < storage.count {

      // Shift forward when removing more elements than are being inserted
      if removeCount > insertCount {
        let moveCount = storage.count - subRange.endIndex
        let moveSource = elements + subRange.endIndex
        let destination = elements + subRange.startIndex.advancedBy(insertCount)
        destination.moveAssignFrom(moveSource, count: moveCount)
      }

      // Shift backward when inserting more elements than are being removed
      else if removeCount < insertCount {
        let moveCount = storage.count - subRange.endIndex
        let moveSource = elements + subRange.endIndex

        let oldElementsDestinationOffset = subRange.startIndex.advancedBy(insertCount)
        let oldElementsDestination = elements + oldElementsDestinationOffset

        oldElementsDestination.moveInitializeBackwardFrom(moveSource, count: moveCount)

        let uninsertedElementsDestinationOffset = subRange.endIndex
        let uinsertedElementsDestination = elements + uninsertedElementsDestinationOffset

        let uninsertedElements = newElements[newElements.startIndex.advancedBy(numericCast(removeCount))..<].map({
          Weak<Element>($0 as? Element)
        })

        uinsertedElementsDestination.initializeFrom(uninsertedElements)

      }
    }
    storage.count = newCount
  }
}

extension WeakArray: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) { self.init(elements) }
}

extension WeakArray: CustomStringConvertible, CustomDebugStringConvertible {
  private var elementsDescription: String {
    defer { _fixLifetime(self) }
      var result = "["
      var first = true
      for i in 0 ..< count {
        if first { first = false }
        else { result += ", " }
        result += "\(self[i])"
      }
      result += "]"
      return result
  }
  public var description: String { return elementsDescription }
  public var debugDescription: String { return storage.description }
}
//extension WeakArray: CustomPlaygroundQuickLookable {
//  public func customPlaygroundQuickLook() -> PlaygroundQuickLook { return .Text(elements.description) }
//}

