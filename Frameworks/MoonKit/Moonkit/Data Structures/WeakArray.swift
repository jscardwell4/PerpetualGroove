//
//  WeakArray.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

private final class WeakArrayBuffer<Element: AnyObject> : ManagedBuffer<(count: Int, capacity: Int), Weak<Element>> {
  class func create(capacity: Int) -> WeakArrayBuffer {
    let r = super.create(capacity) { (count: 0, capacity: $0.allocatedElementCount) }
    return r as! WeakArrayBuffer
  }

  var weakElements: UnsafeBufferPointer<Weak<Element>> {
    return withUnsafeMutablePointerToElements { [count = count] in UnsafeBufferPointer(start: $0, count: count) }
  }

  var elements: [Element] { return weakElements.flatMap { $0.reference } }

  var count: Int { get { return value.count } set { value.count = newValue } }

  var capacity: Int { return value.capacity }

  private func purgeAtIndex(index: Int) {
    precondition(index < capacity)
    precondition(self[index].reference == nil, "non-nil reference")
    withUnsafeMutablePointerToElements {
      [count = count] pointer in
        (pointer + index).moveInitializeFrom(pointer + index + 1 , count: count - index - 1)
    }
    count -= 1
  }

  func purgeNilReferences() -> Int {
    let gaps = weakElements.enumerate().filter({$1.reference == nil}).map({$0.0})
    guard gaps.count > 0 else { return 0}
    var offset = 0
    for gap in gaps { purgeAtIndex(gap - offset); offset += 1 }
    return offset
  }

  subscript(index: Int) -> Weak<Element> {
    precondition(index < count, "Index out of bounds: \(index)")
    return withUnsafeMutablePointerToElements { $0[index] }
  }

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

  func resize(newSize: Int) -> WeakArrayBuffer<Element> {
    purgeNilReferences()
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

  deinit {
    withUnsafeMutablePointerToElements { [count = count] in for i in 0 ..< count { ($0 + i).destroy() } }
  }

  func append(element: Element) {
    purgeNilReferences()
    precondition(count + 1 <= capacity)
    withUnsafeMutablePointerToElements { [count = count] in ($0 + count).initialize(Weak(element)) }
    count += 1
  }
}

public struct WeakArray<Element:AnyObject> { //: MutableCollectionType {
  private var storage: WeakArrayBuffer<Element>
  private var elements: [Element] { return storage.elements }

  public var startIndex: Int { return elements.startIndex }
  public var endIndex: Int { return elements.endIndex }

  public subscript(position: Int) -> Element {
    get { return elements[position] }
    set {
      precondition(position < count, "Index out of bounds: \(position)")
      storage.withUnsafeMutablePointerToElements {
        UnsafeMutableBufferPointer(start: $0, count: self.count)[position] = Weak(newValue)
      }
    }
  }

  public var count: Int { return elements.count }

  public mutating func append(element: Element) {
    if storage.count == storage.capacity {
      storage = storage.resize(storage.count * 2)
    }
    storage.append(element)
  }

  public init() { storage = WeakArrayBuffer<Element>.create(8) }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    let array = sequence.map {Weak<Element>($0)}
    storage = WeakArrayBuffer<Element>.create(max(array.count * 2, 8))
    storage.withUnsafeMutablePointerToElements { $0.initializeFrom(array) }
    storage.count = array.count
  }

  public func generate() -> AnyGenerator<Element> {
    var index = startIndex
    var purgeNeeded = false
    let collection = self
    return AnyGenerator {
      guard index < collection.endIndex else {
        if purgeNeeded { collection.storage.purgeNilReferences() }
        return nil
      }
      var element: Element?
      while index < collection.endIndex && element == nil {
        element = collection.storage[index].reference
        index += 1
        if element == nil { purgeNeeded = true }
      }
      return element
    }
  }
}

extension WeakArray: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) { self.init(elements) }
}

extension WeakArray: CustomPlaygroundQuickLookable {
  public func customPlaygroundQuickLook() -> PlaygroundQuickLook { return .Text(elements.description) }
}

