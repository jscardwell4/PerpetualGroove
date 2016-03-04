//
//  WeakArray.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

internal final class WeakArrayStorageOwner<Element:AnyObject>: NonObjectiveCBase {
  typealias Buffer = WeakArrayBuffer<Element>
  var buffer: Buffer
  init(minimumCapacity: Int) { buffer = Buffer(minimumCapacity: minimumCapacity) }
  init(buffer: Buffer) { self.buffer = buffer }
}

internal final class WeakArrayStorage<Element: AnyObject>:
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



struct WeakArrayBuffer<Element:AnyObject>: MutableCollectionType, RangeReplaceableCollectionType {
  typealias Storage = WeakArrayStorage<Element>

  var storage: Storage
  typealias _Element = Element?

  init() { self.init(minimumCapacity: 0) }
  init(minimumCapacity: Int) { storage = Storage.create(minimumCapacity) }
  init(storage: Storage) { self.storage = storage }

  init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    let array = sequence.map {Weak<Element>($0)}
    storage = Storage.create(array.count)
    storage.elements.initializeFrom(array)
    storage.count = array.count
  }

  /// Get or set the index'th element.
  subscript(index: Int) -> _Element {
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

  func withUnsafeBufferPointer<R>(
    @noescape body: (UnsafeBufferPointer<Weak<Element>>) throws -> R
    ) rethrows -> R
  {
    defer { _fixLifetime(self) }
    return try body(UnsafeBufferPointer(start: firstElementAddress, count: count))
  }

  mutating func withUnsafeMutableBufferPointer<R>(
    @noescape body: (UnsafeMutableBufferPointer<Weak<Element>>) throws -> R
    ) rethrows -> R
  {
    defer { _fixLifetime(self) }
    return try body(UnsafeMutableBufferPointer(start: firstElementAddress, count: count))
  }

  var count: Int { get { return storage.count } set { storage.count = newValue } }

  var capacity: Int { return storage.capacity }

  var firstElementAddress: UnsafeMutablePointer<Weak<Element>> { return storage.elements }

  var startIndex: Int { return 0 }
  var endIndex: Int { return count }

  mutating func append(element: Element) {
    assert(capacity > count, "not enough capacity to add an element")
    (storage.elements + storage.count).initialize(Weak(element))
    storage.count += 1
  }

  func generate() -> AnyGenerator<_Element> {
    var index = 0
    return AnyGenerator {
      [storage = storage] in
      guard index < storage.count else { return nil }
      let element = storage.elements[index].reference
      index += 1
      return element
    }
  }

  func indexOf(element: Element) -> Int? {
    let elements = storage.elements
    for i in 0 ..< count {
      guard let e = elements[i].reference else { continue }
      guard e === element else { continue }
      return i
    }
    return nil
  }

  mutating func replaceRange<C:CollectionType
    where C.Generator.Element == _Element>(subRange: Range<Int>, with newElements: C)
  {
    defer { _fixLifetime(self); _fixLifetime(storage) }
    let oldCount = storage.count
    let removeCount: Int = subRange.count
    let insertCount: Int = numericCast(newElements.count)
    let newCount = oldCount - removeCount + insertCount
    assert(capacity >= newCount, "not enough capacity for new count: \(newCount)")

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
        destination.moveInitializeFrom(moveSource, count: moveCount)
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

        let uninsertedElementsStart = newElements.startIndex.advancedBy(numericCast(removeCount))
        let uninsertedElements = newElements[uninsertedElementsStart..<].map {
          Weak<Element>($0 as? Element)
        }

        uinsertedElementsDestination.initializeFrom(uninsertedElements)

      }
    }
    storage.count = newCount
  }
}

extension WeakArrayBuffer: CustomStringConvertible, CustomDebugStringConvertible {
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
  var description: String { return elementsDescription }
  var debugDescription: String { return storage.description }
}

public struct WeakArray<Element:AnyObject>: MutableCollectionType, RangeReplaceableCollectionType {
  internal typealias Storage = WeakArrayStorage<Element>
  internal typealias Buffer = WeakArrayBuffer<Element>
  internal typealias Owner = WeakArrayStorageOwner<Element>

  internal var owner: Owner
  internal var buffer: Buffer { get { return owner.buffer } set { owner.buffer = newValue } }

  //  public typealias Generator = IndexingGenerator<WeakArray<Element>>
  public typealias _Element = Element?
//  private var elements: [Element] { return storage.elements }


  public var startIndex: Int { return buffer.startIndex }
  public var endIndex: Int { return buffer.endIndex }

  public subscript(position: Int) -> Element? {
    get {
      precondition(position < count, "Index '\(position)' ≥ count '\(count)'")
      return buffer[position]
    }
    set {
      precondition(position < count, "Index '\(position)' ≥ count '\(count)'")
      ensureUniqueWithCapacity(capacity)
      buffer[position] = newValue
    }
  }

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  private mutating func ensureUniqueWithCapacity(capacity: Int) {
    guard !(isUniquelyReferenced(&owner) && self.capacity >= capacity) else { return }
    guard self.capacity < capacity else {
      owner = Owner(buffer: Buffer(storage: buffer.storage.clone()))
      return
    }
    let newStorage = Storage.create(capacity)
    newStorage.elements.moveInitializeFrom(buffer.storage.elements, count: buffer.storage.count)
    newStorage.count = buffer.storage.count
    owner = Owner(buffer: Buffer(storage: newStorage))
  }

  public mutating func append(element: Element) {
    ensureUniqueWithCapacity(count + 1)
    buffer.append(element)
  }

  public init() { owner = Owner(minimumCapacity: 0) }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    owner = Owner(buffer: Buffer(sequence))
  }

  public func generate() -> AnyGenerator<Element?> {
    return AnyGenerator(buffer.generate())
  }

  public func indexOf(element: Element) -> Int? {
    return buffer.indexOf(element)
  }

  public mutating func replaceRange<C:CollectionType
    where C.Generator.Element == Element?>(subRange: Range<Int>, with newElements: C)
  {
    ensureUniqueWithCapacity(capacity - subRange.count + numericCast(newElements.count))
    buffer.replaceRange(subRange, with: newElements)
  }
}

extension WeakArray: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) { self.init(elements) }
}

extension WeakArray: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { return buffer.description }
  public var debugDescription: String { return buffer.debugDescription }
}

//public struct WeakArrayStrongView<Element:AnyObject> {
//
//}
//
//extension WeakArray {
//  public typealias StrongView = WeakArrayStrongView<Element>
//}
