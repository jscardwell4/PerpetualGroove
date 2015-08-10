//
//  Queue.swift
//  Remote
//
//  Created by Jason Cardwell on 5/05/15.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

private class QueueNode<T> {
  var next: QueueNode<T>?
  var value: T
  init(_ v: T) { value = v }
}

public struct Queue<T> {

  private var head: QueueNode<T>?
  private var tail: QueueNode<T>?


  /**
  dequeue

  - returns: T?
  */
  public mutating func dequeue() -> T? {
    let value = head?.value
    if head != nil {
      head = head?.next
      count--
      if count < 2 { tail = head }
    }
    return value
  }


  /**
  enqueue:

  - parameter value: T
  */
  public mutating func enqueue(value: T) {
    let node = QueueNode(value)
    if let t = tail {
      t.next = node
      tail = node
    } else {
      head = node
      tail = node
    }
    count++
  }

  /** empty */
  public mutating func empty() {
    head = nil
    tail = nil
    count = 0
  }

  public var isEmpty: Bool { return count == 0 }

  public private(set) var count: Int = 0

  public init() {}
  public init<S:SequenceType where S.Generator.Element == T>(_ elements: S) {
    self.init()
    for element in elements { enqueue(element) }
  }
}

extension Queue: ArrayLiteralConvertible {
  public init(arrayLiteral elements: T...) {
    self.init(elements)
  }
}

extension Queue: CustomStringConvertible {
  public var description: String {
    var elementDescriptions: [String] = []
    var n = head
    while let element = n?.value {
      elementDescriptions.append(String(element))
      n = n?.next
    }
    return "[" + ", ".join(elementDescriptions) + "]"
  }
}