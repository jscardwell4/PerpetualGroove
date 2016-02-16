//
//  Heap.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//
//  Converted source https://gist.github.com/airspeedswift/COWTree.swift to 
//  mimic https://gist.github.com/airspeedswift/list.swift

import Foundation

private enum HeapNode<Element: Comparable> {
  case Empty
  indirect case Node(value: Element, left: HeapNode<Element>, right: HeapNode<Element>)

  /**
  initWithValue:

  - parameter value: Element
  */
  init(value: Element) { self = .Node(value: value, left: .Empty, right: .Empty) }
}

public struct Heap<Element: Comparable> {

  private var root = HeapNode<Element>.Empty

  /** init */
  public init() {}

  /**
  init:

  - parameter seq: S
  */
  public init<S: SequenceType where S.Generator.Element == Element>(_ seq: S) { seq.forEach { insert($0) } }

  /**
  insert:

  - parameter value: Element
  */
  public mutating func insert(value: Element) { root = insert(root, value) }

  /**
  insert:value:

  - parameter node: HeapNode<Element>
  - parameter value: Element

  - returns: HeapNode<Element>
  */
  private mutating func insert(node: HeapNode<Element>, _ value: Element) -> HeapNode<Element> {
    switch node {
      case .Empty:                             return HeapNode(value: value)
      case let .Node(v, l, r) where value < v: return .Node(value: v, left: insert(l, value), right: r)
      case let .Node(v, l, r):                 return .Node(value: v, left: l, right: insert(r, value))
    }
  }

  /**
  contains:

  - parameter value: Element

  - returns: Bool
  */
  public func contains(value: Element) -> Bool { return contains(root, value) }

  /**
  contains:value:

  - parameter node: HeapNode<Element>
  - parameter value: Element

  - returns: Bool
  */
  private func contains(node: HeapNode<Element>, _ value: Element) -> Bool {
    switch node {
      case .Empty:                              return false
      case let .Node(v, _, _) where value == v: return true
      case let .Node(v, l, r):                  return contains(value < v ? l : r, value)
    }
  }
}

extension Heap: SequenceType {

  public typealias Generator = AnyGenerator<Element>

  /**
  generate

  - returns: Generator
  */
  public func generate() -> Generator {
    var stack: [HeapNode<Element>] = []
    var current = root
    return AnyGenerator {
      while true {
        if case let .Node(_, l, _) = current {
          stack.append(current)
          current = l
        } else if !stack.isEmpty, case let .Node(v, _, r) = stack.removeLast() {
          current = r
          return v
        } else {
          return nil
        }
      }
    }
  }
}

extension Heap: CustomStringConvertible {
  public var description: String { return "[" + ", ".join(lazy.map({String($0)})) + "]" }
}