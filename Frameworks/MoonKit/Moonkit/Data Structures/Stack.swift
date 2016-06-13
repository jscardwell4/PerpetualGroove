//
//  Stack.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

public struct CompositeStack<T>: CollectionType, CustomStringConvertible, ArrayLiteralConvertible {

  private var storage: [T]

  public var count: Int { return storage.count }
  public var peek: T? { return storage.last }
  public var isEmpty: Bool { return storage.count == 0 }
  public var array: [T] { return storage }
  public func generate() -> Array<T>.Generator { return storage.generate() }

  public init() { storage = [T]() }
  public init<S:SequenceType where S.Generator.Element == T>(_ sequence: S) { storage = Array(sequence) }

  public var startIndex: Array<T>.Index { return storage.startIndex }
  public var endIndex: Array<T>.Index { return storage.endIndex }
  public subscript (i: Array<T>.Index) -> T { get { return storage[i] } set { storage[i] = newValue } }

  /**
  map<U>:

  - parameter transform: (T) -> U

  - returns: [U]
  */
  public func map<U>(transform: (T) -> U) -> [U] { return storage.map(transform) }

  /**
  pop

  - returns: T?
  */
  public mutating func pop() -> T? { var obj: T? = nil; if count > 0 { obj = storage.removeLast() }; return obj }

  /**
  push:

  - parameter obj: T
  - parameter count: Int = 1
  */
  public mutating func push(obj:T, count:Int = 1) { storage += [T](count: count, repeatedValue: obj) }

  /** empty */
  public mutating func empty() { storage.removeAll(keepCapacity: false) }

  /** reverse */
  public mutating func reverse() { storage = Array(storage.reverse()) }

  /**
  reversed

  - returns: CompositeStack<T>
  */
  public func reversed() -> CompositeStack<T> { return CompositeStack<T>(Array(storage.reverse())) }

  public var description: String { return storage.description }

  public init(arrayLiteral elements: T...) { self = CompositeStack<T>(elements) }
}

public struct Stack<Element> {
  private typealias Storage = StackStorage<Element>
  private typealias Buffer = StackBuffer<Element>

  public typealias _Element = Element
  public typealias Generator = StackGenerator<Element>
  public typealias SubSequence = Stack<Element>

  private var buffer: Buffer

  public var count: Int { return buffer.count }
  public var capacity: Int { return buffer.capacity }

  public var isEmpty: Bool { return count == 0 }

  private mutating func ensureUnique() {
    ensureUniqueWithCapacity(capacity)
  }

  public var reversed: Stack<Element> { var result = self; result.buffer.reverse(); return result }

  public mutating func reverse() { ensureUnique(); buffer.reverse() }

  private func cloneBuffer(minimumCapacity minimumCapacity: Int) -> Buffer {
    var clone = Buffer(minimumCapacity: minimumCapacity)
    clone.elements.initializeFrom(buffer.elements, count: buffer.count)
    clone.endIndex = buffer.endIndex
    return clone
  }

  private mutating func ensureUniqueWithCapacity(requiredCapacity: Int) {

    switch (isUnique: buffer.isUniquelyReferenced(), hasCapacity: buffer.capacity >= requiredCapacity) {

      case (isUnique: true, hasCapacity: true):
        return

      case (isUnique: true, hasCapacity: false):
        buffer = cloneBuffer(minimumCapacity: requiredCapacity * 2)

      case (isUnique: false, hasCapacity: true):
        buffer = cloneBuffer(minimumCapacity: capacity)

      case (isUnique: false, hasCapacity: false):
        buffer = cloneBuffer(minimumCapacity: requiredCapacity * 2)
    }

  }

  public init() {
    self = Stack<Element>(minimumCapacity: 0)
  }

  public init(minimumCapacity: Int) {
    buffer = Buffer(minimumCapacity: minimumCapacity)
  }

  public init<S:SequenceType where S.Generator.Element == Element>(_ sequence: S) {
    let elements = sequence as? Array<Element> ?? Array(sequence)
    var stack = Stack<Element>(minimumCapacity: elements.count)
    for element in sequence { stack.buffer.push(element) }
    self = stack
  }

  public mutating func pop() -> Element? {
    ensureUnique()
    return buffer.pop()
  }

  public var peek: Element? { return buffer.peek }

  public mutating func push(element: Element) {
    ensureUniqueWithCapacity(count + 1)
    buffer.push(element)
  }

}

extension Stack: ArrayLiteralConvertible {
  public init(arrayLiteral elements: Element...) {
    self = Stack<Element>(elements)
  }
}

extension Stack: SequenceType {

  public func generate() -> Generator { return Generator(stack: self) }

  public func dropFirst(n: Int) -> Stack<Element> {
    var result = self
    for _ in 0 ..< n { _ = result.buffer.pop() }
    return result
  }

  public func dropLast(n: Int) -> Stack<Element> {
    var result = self
    result.buffer.reverse()
    result.dropFirst(n)
    result.buffer.reverse()
    return result
  }

  public func prefix(maxLength: Int) -> Stack<Element> {
    var result = Stack<Element>(minimumCapacity: maxLength)
    for element in self {
      guard result.count < maxLength else { break }
      result.buffer.push(element)
    }
    result.buffer.reverse()
    return result
  }

  public func suffix(maxLength: Int) -> Stack<Element> {
    var result = Stack<Element>(minimumCapacity: maxLength)
    for i in 0 ..< min(count, maxLength) {
      result.push(buffer.elements[i])
    }
    return result
  }

  public func split(maxSplit: Int,
                    allowEmptySlices: Bool,
                    @noescape isSeparator: (Element) throws -> Bool) rethrows -> [Stack<Element>]
  {
    var result: [Stack<Element>] = []
    var currentStack = Stack<Element>()

    for element in self {
      if !(try isSeparator(element)) {
        currentStack.push(element)
      } else {
        currentStack.buffer.reverse()
        result.append(currentStack)
        currentStack = Stack<Element>()
      }
    }

    if currentStack.count > 0 {
      currentStack.buffer.reverse()
      result.append(currentStack)
    }

    return result
  }
}

extension Stack: CustomStringConvertible, CustomDebugStringConvertible {

  public var description: String {
    guard count > 0 else { return "[]" }
    var result = "["
    var first = true
    for element in self {
      if first { first = false } else { result += ", " }
      print(element, terminator: "", toStream: &result)
    }
    return result
  }

  public var debugDescription: String {
    guard count > 0 else { return "[]" }
    var result = "["
    var first = true
    for element in self {
      if first { first = false } else { result += ", " }
      debugPrint(element, terminator: "", toStream: &result)
    }
    return result
  }

}

public struct StackGenerator<Element>: GeneratorType {
  private let elements: UnsafeMutablePointer<Element>
  private var top: Int

  private init(stack: Stack<Element>) {
    elements = stack.buffer.elements
    top = stack.buffer.endIndex.predecessor()
  }

  public mutating func next() -> Element? {
    guard top > -1 else { return nil }
    let result = (elements + top).memory
    top = top &- 1
    return result
  }
}

private struct StackStorageHeader {
  let capacity: Int
  var count: Int
}

private final class StackStorage<Element>: ManagedBuffer<StackStorageHeader, UInt8> {
  typealias Header = StackStorageHeader
  typealias Storage = StackStorage<Element>

  class func bytesForElements(capacity: Int) -> Int {
    return strideof(Element) * capacity
  }

  var capacity: Int { return value.capacity }
  var count: Int { get { return value.count } set { value.count = newValue } }

  var elements: UnsafeMutablePointer<Element> { return withUnsafeMutablePointerToElements { UnsafeMutablePointer<Element>($0) } }

  class func create(minimumCapacity: Int) -> StackStorage {
    let requiredCapacity = bytesForElements(minimumCapacity)
    let storage = super.create(requiredCapacity) { _ in Header(capacity: minimumCapacity, count: 0) }
    return storage as! Storage
  }

  deinit {
    guard !_isPOD(Element) else { return }
    elements.destroy(count)
  }
}

private struct StackBuffer<Element> {
  typealias Storage = StackStorage<Element>
  typealias Buffer = StackBuffer<Element>

  var count: Int { return endIndex }
  var capacity: Int { return storage.capacity }
  var storage: Storage

  @inline(__always) mutating func isUniquelyReferenced() -> Bool { return Swift.isUniquelyReferenced(&storage) }

  let elements: UnsafeMutablePointer<Element>

  let startIndex = 0
  var endIndex = 0 {
    didSet { storage.count = endIndex }
  }

  var peek: Element? {
    guard endIndex > 0 else { return nil }
    return (elements +  endIndex.predecessor()).memory
  }

  mutating func push(element: Element) {
    (elements + endIndex).initialize(element)
    endIndex = endIndex &+ 1
  }

  mutating func pop() -> Element? {
    guard endIndex > 0 else { return nil }
    let result = (elements + endIndex.predecessor()).move()
    endIndex = endIndex &- 1
    return result
  }

  mutating func reverse() {
    guard endIndex > 1 else { return }
    let indices = 0 ..< endIndex
    for (leftIndex, rightIndex) in zip(indices, indices.reverse()) {
      guard leftIndex < rightIndex else { break }
      swap(&elements[leftIndex], &elements[rightIndex])
    }
  }

  init(minimumCapacity: Int) {
    storage = Storage.create(minimumCapacity)
    elements = storage.elements
  }

}

