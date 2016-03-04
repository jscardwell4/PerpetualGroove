//
//  WeakArray.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

private final class WeakArrayBuffer<Element: AnyObject>:
  ManagedBuffer<(count: Int, capacity: Int), Weak<Element>>
{
  class func create(capacity: Int) -> WeakArrayBuffer {
    let r = super.create(capacity) { (count: 0, capacity: $0.allocatedElementCount) }
    return r as! WeakArrayBuffer
  }

  var elements: UnsafeMutablePointer<Weak<Element>> {
    defer { _fixLifetime(self) }
    return withUnsafeMutablePointerToElements {$0}
  }

//  var weakElements: UnsafeBufferPointer<Weak<Element>> {
//    return withUnsafeMutablePointerToElements {
//      [count = count] in UnsafeBufferPointer(start: $0, count: count)
//    }
//  }

//  var elements: [Element] { return weakElements.flatMap { $0.reference } }

  var count: Int {
    get { defer { _fixLifetime(self) }; return value.count }
    set { defer { _fixLifetime(self) }; value.count = newValue }
  }

  var capacity: Int { return value.capacity }

//  private func purgeAtIndex(index: Int) {
//    precondition(index < capacity)
//    precondition(self[index].reference == nil, "non-nil reference")
//    withUnsafeMutablePointerToElements {
//      [count = count] pointer in
//        (pointer + index).moveInitializeFrom(pointer + index + 1 , count: count - index - 1)
//    }
//    count -= 1
//  }

  func purgeNilReferences() -> Int {
    defer { _fixLifetime(self) }
    let elements = self.elements
    var purgeCount = 0
    var i = 0
    while i < count {
      guard elements[i].reference == nil else { i += 1; continue }
      purgeCount += 1
      guard i.successor() < count else { (elements + i).destroy(); break }

      (elements + i).moveAssignFrom(elements + i.successor(), count: count - i)
    }

    count -= purgeCount

    return purgeCount

//    let gaps = weakElements.enumerate().filter({$1.reference == nil}).map({$0.0})
//    guard gaps.count > 0 else { return 0}
//    var offset = 0
//    for gap in gaps { purgeAtIndex(gap - offset); offset += 1 }
//    return offset
  }

//  subscript(index: Int) -> Weak<Element> {
//    precondition(index < count, "Index out of bounds: \(index)")
//    return withUnsafeMutablePointerToElements { $0[index] }
//  }

  func clone() -> WeakArrayBuffer<Element> {
    purgeNilReferences()
    return withUnsafeMutablePointerToElements {
      oldElems -> WeakArrayBuffer<Element> in
      return WeakArrayBuffer<Element>.create(self.allocatedElementCount) {
        newBuf in
        newBuf.withUnsafeMutablePointerToElements {
          newElems -> Void in
          newElems.initializeFrom(oldElems, count: self.count)
        }
        return self.value
        } as! WeakArrayBuffer<Element>
    }
  }

  func resize(newSize: Int, purge: Bool = true) -> WeakArrayBuffer<Element> {
    if purge { purgeNilReferences() }
    return withUnsafeMutablePointerToElements {
      [count = count] oldElements -> WeakArrayBuffer<Element> in
      return WeakArrayBuffer<Element>.create(newSize) {
        newBuffer in
        newBuffer.withUnsafeMutablePointerToElements {
          newElements in
          newElements.moveInitializeFrom(oldElements, count: count)
        }
        return (count: count, capacity: newSize)
        } as! WeakArrayBuffer<Element>
    }
  }

//  deinit {
//    defer { _fixLifetime(self) }
//    guard !_isPOD(Element) else { return }
//    let elements = self.elements
//    withUnsafeMutablePointerToElements { [count = count] in for i in 0 ..< count { ($0 + i).destroy() } }
//  }

//  func append(element: Element) {
//    purgeNilReferences()
//    precondition(count + 1 <= capacity)
//    withUnsafeMutablePointerToElements { [count = count] in ($0 + count).initialize(Weak(element)) }
//    count += 1
//  }

  var description: String {
    defer { _fixLifetime(self) }
    var result = "count = \(count), capacity = \(capacity)\n"
    result += "["

    var first = true
    let elements = self.elements
    for i in 0 ..< count {
      if first { first = false }
      else { result += ", " }
      result += "\(elements[i])"
    }
      result += "]"
    return result
  }
}

public struct WeakArray<Element:AnyObject>: MutableCollectionType, RangeReplaceableCollectionType {
  private var storage: WeakArrayBuffer<Element>
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
    let newStorage = WeakArrayBuffer<Element>.create(capacity)
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

  public init() { storage = WeakArrayBuffer<Element>.create(0) }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    let array = sequence.map {Weak<Element>($0)}
    storage = WeakArrayBuffer<Element>.create(array.count)
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

