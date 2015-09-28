//
//  Tree.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/19/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//  modified source code from http://airspeedvelocity.net/2015/07/22/a-persistent-tree-using-indirect-enums-in-swift
//

import Foundation


public indirect enum Tree<Element: Comparable>: NilLiteralConvertible {

  case Empty
  case Node(red: Bool, left: Tree<Element>, value: Element, right: Tree<Element>)

  public var value: Element? { if case let .Node(_, _, value, _) = self { return value } else { return nil } }

  public var isEmpty: Bool { return self == .Empty }

  public var predecessor: Tree<Element>? { 
    if case let .Node(_, left, _, _) = self { return left } 
    else { return nil } 
  }
  
  public var successor: Tree<Element>? { 
    if case let .Node(_, _, _, right) = self { return right } 
    else { return nil } 
  }

  /** init */
  public init() { self = .Empty }
  public init(nilLiteral: ()) { self = .Empty }

  /**
  init:even:left:right:

  - parameter value: Element
  - parameter red: Bool = false
  - parameter left: Tree<Element> = .Empty
  - parameter right: Tree<Element> = .Empty
  */
  public init(_ value: Element, red: Bool = false, left: Tree<Element> = .Empty, right: Tree<Element> = .Empty) {
    self = .Node(red: red, left: left, value: value, right: right)
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
  Helper for balancing the tree

  - parameter tree: Tree<Element>

  - returns: Tree<Element>
  */
  private func balance(tree: Tree<Element>) -> Tree<Element> {
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
      return .Node(red: true,
                   left: .Node(red: false,
                               left: a,
                               value: x,
                               right: b),
                   value: y,
                   right: .Node(red: false,
                                left: c,
                                value: z,
                                right: d)
                   )
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
  replace:with:

  - parameter element1: Element
  - parameter element2: Element
  */
  public mutating func replace(element1: Element, with element2: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element1) else { return }
    elements[idx] = element2
    self = Tree(elements)
  }

  public mutating func replace<S1:SequenceType, S2:SequenceType
    where S1.Generator.Element == Element, S2.Generator.Element == Element>(elements1: S1, with elements2: S2)
  {
    self = Tree(Array(self).filter({elements1 ∌ $0}) + Array(elements2))
  }

  /**
  remove:

  - parameter element: Element
  */
  public mutating func remove(element: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element) else { return }
    elements.removeAtIndex(idx)
    self = Tree(elements)
  }

  /**
  remove:

  - parameter elements: S
  */
  public mutating func remove<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    self = Tree(Array(self).filter({elements ∌ $0}))
  }


  public var treeDescription: String {
    var result = ""
    func describeTree(tree: Tree<Element>, _ height: Int, _ kind: String ) {
        let indent = "  " * height
        let heightString = "[" + String(height).pad(" ", count: 2, type: .Prefix) + "\(kind)]"
      switch tree {
      case .Empty:
        let colorString = "black"
        result += "\(indent)\(heightString) <\(colorString)> nil\n"
      case let .Node(red, left, value, right):
        let colorString = red ? "red" : "black"
        let valueString = String(value)
        result += "\(indent)\(heightString) <\(colorString)> \(valueString)\n"
        describeTree(left, height + 1, "L")
        describeTree(right, height + 1, "R")
      }
    }

    describeTree(self, 0, " ")
    return result
  }

  /**
  insert:

  - parameter elements: S
  */
  public mutating func insert<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    elements.forEach({insert($0)})
  }

  /**
  insert:

  - parameter element: Element

  - returns: Tree
  */
  public mutating func insert(element: Element) {

    /**
    Helper to handle recursive balancing

    - parameter element: Element
    - parameter tree: Tree<Element>

    - returns: Tree<Element>
    */
    func insert(element: Element, into tree: Tree<Element>) -> Tree<Element> {
      switch tree {
        case .Empty:
          return Tree(element, red: true)
        case let .Node(red, left, value, right) where element < value:
          return balance(Tree(value, red: red, left: insert(element, into: left), right: right))
        case let .Node(red, left, value, right) where element > value:
          return balance(Tree(value, red: red, left: left, right: insert(element, into: right)))
        default:
          return tree
      }
    }

    guard case let .Node(_, left, value, right) = insert(element, into: self) else {
      fatalError("ins should never return an empty tree")
    }

    self = .Node(red: false, left: left, value: value, right: right)
  }

  /**
  find:

  - parameter element: Element

  - returns: Tree<Element>?
  */
  public func find(element: Element) -> Tree<Element>? {
    switch self {
      case .Empty: return nil
      case let .Node(_, left, value, _) where element < value:  return left.find(element)
      case let .Node(_, _, value, right) where element > value: return right.find(element)
      default:                                                  return self
    }
  }

  /** 
  find:_:
  
  - parameter isOrderedBefore: (Element) -> Bool
  - parameter isEqual: (Element) -> Bool
  
  - returns: Element?
  */
  public func find(@noescape isOrderedBefore: (Element) -> Bool, _ isEqual: (Element) -> Bool) -> Element? {
    switch self {
      case let .Node(_, _, value, _) where isEqual(value):             return value
      case let .Node(_, left, value, _) where !isOrderedBefore(value): return left.find(isOrderedBefore, isEqual)
      case let .Node(_, _, value, right) where isOrderedBefore(value): return right.find(isOrderedBefore, isEqual)
      case .Empty:                                                     fallthrough
      default:                                                         return nil
    }
  }

  /**
  dropAfter:

  - parameter element: Element
  */
  public mutating func dropAfter(element: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element) else { return }
    self = Tree(elements[elements.startIndex ... idx])
  }

  /**
  dropBefore:

  - parameter element: Element
  */
  public mutating func dropBefore(element: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element) else { return }
    self = Tree(elements[idx ..< elements.endIndex])
  }

  /**
  nearestPredecessorTo:

  - parameter element: Element

  - returns: Tree<Element>?
  */
//  public func nearestPredecessorTo(element: Element) -> Tree<Element>? {
//    if case .Empty = self { return nil }
//    guard let value = value where element != value else { return self }
//    return value < element ? successor?.nearestPredecessorTo(element) ?? self : predecessor?.nearestPredecessorTo(element)
//  }

  /**
  nearestSuccessorTo:

  - parameter element: Element

  - returns: Tree<Element>?
  */
//  public func nearestSuccessorTo(element: Element) -> Tree<Element>? {
//    if case .Empty = self { return nil }
//    guard let value = value where element != value else { return self }
//    return value > element ? predecessor?.nearestSuccessorTo(element) ?? self : successor?.nearestSuccessorTo(element)
//  }

  /**
  nearestPredecessor:

  - parameter isOrderedBefore: (Element) -> Bool

  - returns: Tree<Element>?
  */
//  public func nearestPredecessor(@noescape isOrderedBeforeOrEqual: (Element) -> Bool) -> Tree<Element>? {
//    switch self {
//      case .Empty:
//        return nil
//      case let .Node(_, _, v, right) where isOrderedBeforeOrEqual(v) && right.value != nil:
//        return right.nearestPredecessor(isOrderedBeforeOrEqual) ?? self
//      case let .Node(_, _, v, _) where isOrderedBeforeOrEqual(v):
//        return self
//      case let .Node(_, left, v, _) where !isOrderedBeforeOrEqual(v):
//        return left.nearestPredecessor(isOrderedBeforeOrEqual)
//      default: return nil
//    }
//  }


  /**
  nearestSuccessor:

  - parameter isOrderedBefore: (Element) -> Bool

  - returns: Tree<Element>?
  */
//  public func nearestSuccessor(@noescape isOrderedAfterOrEqual: (Element) -> Bool) -> Tree<Element>? {
//    switch self {
//      case .Empty:
//        return nil
//      case let .Node(_, left, v, _) where isOrderedAfterOrEqual(v) && left.value != nil:
//        return left.nearestSuccessor(isOrderedAfterOrEqual) ?? self
//      case let .Node(_, _, v, _) where isOrderedAfterOrEqual(v):
//        return self
//      case let .Node(_, _, v, right) where !isOrderedAfterOrEqual(v):
//        return right.nearestSuccessor(isOrderedAfterOrEqual)
//      default: return nil
//    }
//  }

}

//extension Tree where Element:ForwardIndexType {
//  /**
//  nearestTo:
//
//  - parameter element: Element
//
//  - returns: Tree<Element>?
//  */
//  public func nearestTo(element: Element) -> Tree<Element>? {
//    switch (nearestPredecessorTo(element), nearestSuccessorTo(element)) {
//      case let (pred?, succ?):
//        switch (pred, succ) {
//          case let (.Node(_, _, pv, _), .Node(_, _, ps, _)) where pv.distanceTo(element) < element.distanceTo(ps):
//            return pred
//          default:
//            return succ
//        }
//      case let (pred?, nil): return pred
//      case let (nil, succ?): return succ
//      default:               return nil
//    }
//  }
//}

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
    self.init()
    for element in source { insert(element) }
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

extension Tree: Equatable {}

public func ==<T:Comparable>(lhs: Tree<T>, rhs: Tree<T>) -> Bool {
  if case .Empty = lhs, case .Empty = rhs { return true }
  else if case .Empty = lhs { return false }
  else if case .Empty = rhs { return false }
  else {
    let lhsArray = Array(lhs)
    let rhsArray = Array(rhs)
    guard lhsArray.count == rhsArray.count else { return false }
    for (l, r) in zip(lhsArray, rhsArray) {
      if l < r || l > r { return false }
    }
    return true
  }
}
