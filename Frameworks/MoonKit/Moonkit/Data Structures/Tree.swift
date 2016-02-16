//
//  Tree.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/19/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//  modified source code from http://airspeedvelocity.net/2015/07/22/a-persistent-tree-using-indirect-enums-in-swift
//

import Foundation

private enum Color { case Red, Black }

private indirect enum Node<Element: Comparable> {
  case None
  case Some(Color, Node<Element>, Element, Node<Element>)

  private mutating func update(color: Color, left: Node<Element>, value: Element, right: Node<Element>) {
    self = .Some(color, left, value, right)
  }
}

private enum FindOptions { case Default, NearestNotGreaterThan, NearestNotLessThan }

public struct Tree<Element: Comparable> {


  private var root: Node<Element> = .None

  /// Whether the node is a leaf node
  public var isEmpty: Bool { if case .None = root { return true } else { return false } }

  /** Create an empty tree */
  public init() {}

  /**
   Create a tree with the specified elements

   - parameter source: S
   */
  public init<S: SequenceType where S.Generator.Element == Element>(_ source: S) {
    for element in source { insert(element) }
  }

  /**
  Whether the tree contains the specified element

  - parameter x: Element

  - returns: Bool
  */
  public func contains(element: Element) -> Bool {
    func subtreeContainsElement(subtree: Node<Element>) -> Bool {
      switch subtree {
        case .None: return false
        case let .Some(_, left, value, _)  where element < value:  return subtreeContainsElement(left)
        case let .Some(_, _, value, right) where element > value:  return subtreeContainsElement(right)
        case let .Some(_, _, value, _)     where element == value: fallthrough
        default:                                                   return true
      }
    }
    return subtreeContainsElement(root)
  }

  /**
  Helper for balancing the tree

  - parameter tree: Node<Element>

  - returns: Node<Element>
  */
  private func balance(node: Node<Element>) -> Node<Element> {
    /**
    Helper for composing tree from case-extracted values

    - parameter a: Node<Element>
    - parameter x: Element
    - parameter b: Node<Element>
    - parameter y: Element
    - parameter c: Node<Element>
    - parameter z: Element
    - parameter d: Node<Element>

    - returns: Node<Element>
    */
    func result(a: Node<Element>, _ x: Element,
              _ b: Node<Element>, _ y: Element,
              _ c: Node<Element>, _ z: Element, _ d: Node<Element>) -> Node<Element>
    {
      return .Some(.Red, .Some(.Black, a, x, b), y, .Some(.Black, c, z, d))
    }

    switch node {
      case let .Some(.Black, .Some(.Red, .Some(.Red, a, x, b), y, c), z, d): return result(a, x, b, y, c, z, d)
      case let .Some(.Black, .Some(.Red, a, x, .Some(.Red, b, y, c)), z, d): return result(a, x, b, y, c, z, d)
      case let .Some(.Black, a, x, .Some(.Red, .Some(.Red, b, y, c), z, d)): return result(a, x, b, y, c, z, d)
      case let .Some(.Black, a, x, .Some(.Red, b, y, .Some(.Red, c, z, d))): return result(a, x, b, y, c, z, d)
      default:                                                               return node
    }

  }

  /**
  Replace an element in the tree

  - parameter element1: Element
  - parameter element2: Element
  */
  public mutating func replace(element1: Element, with element2: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element1) else { return }
    elements[idx] = element2
    self = Tree(elements)
  }

  /**
  Replace some elements with some other elements

  - parameter elements1: S1
  - parameter elements2: S2
  */
  public mutating func replace<S1:SequenceType, S2:SequenceType
    where S1.Generator.Element == Element, S2.Generator.Element == Element>(elements1: S1, with elements2: S2)
  {
    self = Tree(filter({elements1 ∌ $0}) + Array(elements2))
  }

  /**
  Remove an element from the tree

  - parameter element: Element
  */
  public mutating func remove(element: Element) {
    // TODO: Remove without using an Array
    var elements = Array(self)
    guard let idx = elements.indexOf(element) else { return }
    elements.removeAtIndex(idx)
    self = Tree(elements)
  }

  /**
  Remove some elements from the tree

  - parameter elements: S
  */
  public mutating func remove<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    self = Tree(filter({elements ∌ $0}))
  }

  /**
  Add some elements to the tree

  - parameter elements: S
  */
  public mutating func insert<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    elements.forEach({insert($0)})
  }

  /**
  Add an element to the tree

  - parameter element: Element

  - returns: Tree
  */
  public mutating func insert(element: Element) {

    /**
    Helper to handle recursive balancing

    - parameter element: Element
    - parameter root: Tree<Element>

    - returns: Tree<Element>
    */
    func insert(element: Element, into root: Node<Element>) -> Node<Element> {
      switch root {
        case .None:
          return .Some(.Red, .None, element, .None)
        case let .Some(color, left, value, right) where element < value:
          return balance(.Some(color, insert(element, into: left), value, right))
        case let .Some(color, left, value, right) where element > value:
          return balance(.Some(color, left, value, insert(element, into: right)))
        default:
          return root
      }
    }

    guard case let .Some(_, left, value, right) = insert(element, into: root) else {
      fatalError("insert should never return an empty tree")
    }

    root = .Some(.Black, left, value, right)
  }

  /** 
  Find an element in the tree using the specified comparator closures
  
  - parameter isOrderedBefore: (Element) -> Bool
  - parameter predicate: (Element) -> Bool
  
  - returns: Element?
  */
  public func find(isOrderedBefore: (Element) -> Bool, _ predicate: (Element) -> Bool) -> Element? {
    return find(root, isOrderedBefore: isOrderedBefore, predicate: predicate)
  }

  /**
   findNearestNotGreaterThan:

   - parameter value: Element

    - returns: Element?
  */
  public func findNearestNotGreaterThan(value: Element) -> Element? {
    return findNearestNotGreaterThan({$0 < value}, {$0 == value})
  }


  /**
   findNearestNotGreaterThan:predicate:

   - parameter isOrderedBefore: (Element) -> Bool
   - parameter predicate: (Element) -> Bool

    - returns: Element?
  */
  public func findNearestNotGreaterThan(isOrderedBefore: (Element) -> Bool,
                                  _ predicate: (Element) -> Bool) -> Element?
  {
    return find(root, options: .NearestNotGreaterThan, isOrderedBefore: isOrderedBefore, predicate: predicate)
  }

  /**
   findNearestNotLessThan:

   - parameter value: Element

    - returns: Element?
  */
  public func findNearestNotLessThan(value: Element) -> Element? {
    return findNearestNotLessThan({$0 < value}, {$0 == value})
  }

  /**
   findNearestNotLessThan:predicate:

   - parameter isOrderedBefore: (Element) -> Bool
   - parameter predicate: (Element) -> Bool

    - returns: Element?
  */
  public func findNearestNotLessThan(isOrderedBefore: (Element) -> Bool,
                                   _ predicate: (Element) -> Bool) -> Element?
  {
    return find(root, options: .NearestNotLessThan, isOrderedBefore: isOrderedBefore, predicate: predicate)
  }

  /**
   find:isOrderedBefore:predicate:

   - parameter node: Node<Element>
   - parameter isOrderedBefore: (Element) -> Bool
   - parameter predicate: (Element) -> Bool

    - returns: Element?
  */
  private func find(node: Node<Element>,
            options: FindOptions = .Default,
      possibleMatch: Element? = nil,
    isOrderedBefore: (Element) -> Bool,
          predicate: (Element) -> Bool) -> Element?
  {
    switch node {

      // The node's value satisfies the predicate
      case let .Some(_, _, value, _) where predicate(value):
        return value

      // The node's value is greater than desired without a left child and options specify nearest not less than
      case let .Some(_, .None, value, _) where !isOrderedBefore(value) && options == .NearestNotLessThan:
        return value

      // The node's value is greater than desired
      case let .Some(_, left, value, _) where !isOrderedBefore(value):
        return find(left,
            options: options,
      possibleMatch: options == .NearestNotLessThan ? value : possibleMatch,
    isOrderedBefore: isOrderedBefore,
          predicate: predicate)

      // The node's value is less than desired without a right child and options specify nearest not greater
      case let .Some(_, _, value, .None) where isOrderedBefore(value) && options == .NearestNotGreaterThan:
        return value

      // The node's value is less than desired
      case let .Some(_, _, value, right) where isOrderedBefore(value):
        return find(right,
            options: options,
      possibleMatch: options == .NearestNotGreaterThan ? value : possibleMatch,
    isOrderedBefore: isOrderedBefore,
          predicate: predicate)

      // Leaf
      default:
        return possibleMatch
    }
  }

  /**
  Remove all elements after the specified element

  - parameter element: Element
  */
  public mutating func dropAfter(element: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element) else { return }
    self = Tree(elements[elements.startIndex ... idx])
  }

  /**
  Remove all elements before the specified element

  - parameter element: Element
  */
  public mutating func dropBefore(element: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element) else { return }
    self = Tree(elements[idx ..< elements.endIndex])
  }

}

// MARK: - SequenceType
extension Tree: SequenceType {

  /**
  Create a generator for an in-order traversal

  - returns: AnyGenerator<Element>
  */
  public func generate() -> AnyGenerator<Element> {
    // stack-based iterative inorder traversal to make it easy to use with anyGenerator
    var stack: [Node<Element>] = []
    var current: Node<Element> = root
    return AnyGenerator { _ -> Element? in
      repeat {
        switch current {
          case .Some(_, let left, _, _): 
            stack.append(current); current = left
          case .None where !stack.isEmpty:
            guard case let .Some(_, _, value, right) = stack.removeLast() else { break }
            current = right
            return value
          case .None: 
            return nil
        }
      } while true
    }
  }

  /**
  The tree is already sorted so return it converted to an array

  - returns: [Element]
  */
  public func sort() -> [Element] { return Array(self) }

}

// MARK: - ArrayLiteralConvertible
extension Tree: ArrayLiteralConvertible {

  /**
  Create a tree from an array literal

  - parameter elements: Element...
  */
  public init(arrayLiteral elements: Element...) { self.init(elements) }

}

// MARK: - CustomStringConvertible
extension Tree: CustomStringConvertible {
  /// Array-like tree description
  public var description: String { return "[" + ", ".join(Array(self).map({String($0)})) + "]" }
}

// MARK: - CustomDebugStringConvertible
extension Tree: CustomDebugStringConvertible {

  /// A more visually tree-like description
  public var debugDescription: String {
    var result = ""
    func describeNode(node: Node<Element>, _ height: Int, _ kind: String ) {
        let indent = "  " * height
        let heightString = "[" + String(height).pad(" ", count: 2, type: .Prefix) + "\(kind)]"
      switch node {
        case .None:
          result += "\(indent)\(heightString) <\(Color.Black)> nil\n"
        case let .Some(color, left, value, right):
          result += "\(indent)\(heightString) <\(color)> \(value)\n"
          describeNode(left,  height + 1, "L")
          describeNode(right, height + 1, "R")
      }
    }

    describeNode(root, 0, " ")
    return result
  }
}
