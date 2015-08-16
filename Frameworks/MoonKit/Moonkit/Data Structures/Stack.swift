//
//  Stack.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

public struct Stack<T>: CollectionType, CustomStringConvertible, ArrayLiteralConvertible {

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

  - returns: Stack<T>
  */
  public func reversed() -> Stack<T> { return Stack<T>(Array(storage.reverse())) }

  public var description: String { return storage.description }

  public init(arrayLiteral elements: T...) { self = Stack<T>(elements) }
}
