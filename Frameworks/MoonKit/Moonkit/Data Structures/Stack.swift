//
//  Stack.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

public struct Stack<T> {

  private var storage: [T]

  public var count: Int { return storage.count }
  public var peek: T? { return storage.last }
  public var isEmpty: Bool { return count == 0 }
  public var array: [T] { return storage }

  public init() { storage = [T]() }
  public init<S:SequenceType where S.Generator.Element == T>(_ sequence: S) { storage = Array(sequence) }

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

  - returns: Stack<T>
  */
  public func reversed() -> Stack<T> { return Stack<T>(Array(storage.reverse())) }

}

extension Stack: CustomStringConvertible {
  public var description: String { return storage.description }
}

extension Stack: SequenceType {
  public func generate() -> Array<T>.Generator { return storage.generate() }
}

extension Stack: CollectionType {
  public var startIndex: Array<T>.Index { return storage.startIndex }
  public var endIndex: Array<T>.Index { return storage.endIndex }
  public subscript (i: Array<T>.Index) -> T { get { return storage[i] } set { storage[i] = newValue } }
}

extension Stack: ArrayLiteralConvertible {
  public init(arrayLiteral elements: T...) {
    self = Stack<T>(elements)
  }
}
