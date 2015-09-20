//
//  Tree.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/19/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//  modified source code from http://airspeedvelocity.net/2015/07/22/a-persistent-tree-using-indirect-enums-in-swift
//

import Foundation


public indirect enum Tree<Element: Comparable> {
  case Empty
  case Node(Bool,Tree<Element>,Element,Tree<Element>)

  /** init */
  public init() { self = .Empty }

  /**
  init:even:left:right:

  - parameter value: Element
  - parameter even: Bool = false
  - parameter left: Tree<Element> = .Empty
  - parameter right: Tree<Element> = .Empty
  */
  public init(_ value: Element, even: Bool = false, left: Tree<Element> = .Empty, right: Tree<Element> = .Empty) {
    self = .Node(even, left, value, right)
  }

  /**
  contains:

  - parameter x: Element

  - returns: Bool
  */
  public func contains(element: Element) -> Bool {
    switch self {
      case .Empty: return false
      case let .Node(_, left, value, _) where element < value:  return left.contains(element)
      case let .Node(_, _, value, right) where element > value: return right.contains(element)
      case let .Node(_, _, value, _) where element == value:    fallthrough
      default:                                                  return true
    }
  }

  /**
  insert:

  - parameter element: Element

  - returns: Tree
  */
  public func insert(element: Element) -> Tree {

    /**
    Helper for balancing the tree

    - parameter tree: Tree<Element>

    - returns: Tree<Element>
    */
    func balance(tree: Tree<Element>) -> Tree<Element> {
      /**
      Helper for composing tree from case-extracted values

      - parameter a: Tree<Element>
      - parameter x: Element
      - parameter b: Tree<Element>
      - parameter y: Element
      - parameter c: Tree<Element>
      - parameter z: Element
      - parameter d: Tree<Element>

      - returns: Tree<Element>
      */
      func result(a: Tree<Element>, _ x: Element,
                _ b: Tree<Element>, _ y: Element,
                _ c: Tree<Element>, _ z: Element, _ d: Tree<Element>) -> Tree<Element>
      {
        return .Node(true, .Node(false,a,x,b),y,.Node(false,c,z,d))
      }
      switch tree {
        case let .Node(false, .Node(true, .Node(true, a, x, b), y, c), z, d): return result(a, x, b, y, c, z, d)
        case let .Node(false, .Node(true, a, x, .Node(true, b, y, c)), z, d): return result(a, x, b, y, c, z, d)
        case let .Node(false, a, x, .Node(true, .Node(true, b, y, c), z, d)): return result(a, x, b, y, c, z, d)
        case let .Node(false, a, x, .Node(true, b, y, .Node(true, c, z, d))): return result(a, x, b, y, c, z, d)
        default:                                                              return tree
      }
    }

    /**
    Helper to handle recursive balancing

    - parameter element: Element
    - parameter tree: Tree<Element>

    - returns: Tree<Element>
    */
    func insert(element: Element, into tree: Tree<Element>) -> Tree<Element> {
      switch tree {
      case .Empty:
        return Tree(element, even: true)
      case let .Node(even, left, value, right) where element < value:
        return balance(Tree(value, even: even, left: insert(element, into: left), right: right))
      case let .Node(even, left, value, right) where element > value:
        return balance(Tree(value, even: even, left: left, right: insert(element, into: right)))
      default:
        return tree
      }
    }

    guard case let .Node(_, left, value, right) = insert(element, into: self) else { fatalError("ins should never return an empty tree") }
    return .Node(false, left, value, right)
  }

}


extension Tree: SequenceType {

  /**
  generate

  - returns: AnyGenerator<Element>
  */
  public func generate() -> AnyGenerator<Element> {
    // stack-based iterative inorder traversal to
    // make it easy to use with anyGenerator
    var stack: [Tree] = []
    var current: Tree = self
    return anyGenerator { _ -> Element? in
      while true {
        switch current {
        case let .Node(_,l,_,_): stack.append(current); current = l
        case .Empty where !stack.isEmpty:
          guard case let .Node(_, _, x, r) = stack.removeLast() else { break }
          current = r
          return x
        case .Empty: return nil
        }
      }
    }
  }

}

extension Tree: ArrayLiteralConvertible {

  /**
  init:

  - parameter source: S
  */
  public init<S: SequenceType where S.Generator.Element == Element>(_ source: S) {
    self = source.reduce(Tree()) { $0.insert($1) }
  }

  /**
  init:

  - parameter elements: Element...
  */
  public init(arrayLiteral elements: Element...) { self = Tree(elements) }

}

extension Tree: CustomStringConvertible {
  public var description: String { return "[" + ", ".join(Array(self).map({String($0)})) + "]" }
}
