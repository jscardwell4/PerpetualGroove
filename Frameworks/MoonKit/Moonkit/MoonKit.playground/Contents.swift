import Foundation
import UIKit
import MoonKit

private enum Color { case Red, Black }

private indirect enum Node<Element: Comparable> {
  case None
  case Some(Color, Node<Element>, Element, Node<Element>)
}

public struct _Tree<Element: Comparable> {


  private var root: Node<Element> = .None

  /// Whether the node is a leaf node
  public var isEmpty: Bool { if case .None = root { return true } else { return false } }

  /** Create an empty tree */
  public init() {}

  /**
   Create a tree with the specified elements

   - parameter source: S
   */
  public init<S: SequenceType where S.Generator.Element == Element>(_ source: S) { for element in source { insert(element) } }

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
    //    switch find(element1) {
    //      case let .Some(color, left, value, right)?:
    //        func updateNode(node: Node<Element>) -> Node<Element> {
    //          switch node {
    //          case let .Some(_, .Some(_, .None, v, .None), _, _) where v == value:
    //            break
    //          }
    //        }
    //        break
    //      default: break
    //    }


    var elements = Array(self)
    guard let idx = elements.indexOf(element1) else { return }
    elements[idx] = element2
    self = _Tree(elements)
  }

  /**
   Replace some elements with some other elements

   - parameter elements1: S1
   - parameter elements2: S2
   */
  public mutating func replace<S1:SequenceType, S2:SequenceType
    where S1.Generator.Element == Element, S2.Generator.Element == Element>(elements1: S1, with elements2: S2)
  {
    self = _Tree(filter({elements1 ∌ $0}) + Array(elements2))
  }

  /**
   Remove an element from the tree

   - parameter element: Element
   */
  public mutating func remove(element: Element) {
    func removeElement(node: Node<Element>) -> Node<Element> {
      switch node {

      case .Some(_, .None, let value, .None) where value == element:
        return .None

      case let .Some(color, .Some(_, left, subValue, right), value, .None) where value == element:
        return .Some(color, left, subValue, right)

      case let .Some(color, .None, value, .Some(_, left, subValue, right)) where value == element:
        return .Some(color, left, subValue, right)

      case let .Some(color, left, value, right) where value < element:
        return .Some(color, left, value, removeElement(right))

      case let .Some(color, left, value, right) where value > element:
        return .Some(color, removeElement(left), value, right)

      case .None:
        fallthrough

      default:
        return node

      }
    }

    root = balance(removeElement(root))
//    // TODO: Remove without using an Array
//    var elements = Array(self)
//    guard let idx = elements.indexOf(element) else { return }
//    elements.removeAtIndex(idx)
//    self = _Tree(elements)
  }

  /**
   Remove some elements from the tree

   - parameter elements: S
   */
  public mutating func remove<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    self = _Tree(filter({elements ∌ $0}))
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

   - returns: _Tree
   */
  public mutating func insert(element: Element) {

    /**
     Helper to handle recursive balancing

     - parameter element: Element
     - parameter root: _Tree<Element>

     - returns: _Tree<Element>
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
   Return the node containing the specified element

   - parameter element: Element

   - returns: Node<Element>?
   */
  private func find(element: Element) -> Node<Element>? {
    func find(node: Node<Element>) -> Node<Element>? {
      switch node {
      case .None:                                                 return nil
      case let .Some(_, left, value,     _) where element < value: return find(left)
      case let .Some(_,    _, value, right) where element > value: return find(right)
      default:                                                     return node
      }
    }
    return find(root)
  }

  /**
   Find an element in the tree using the specified comparator closures

   - parameter isOrderedBefore: (Element) -> Bool
   - parameter isEqual: (Element) -> Bool

   - returns: Element?
   */
  public func find(isOrderedBefore: (Element) -> Bool, _ isEqual: (Element) -> Bool) -> Element? {
    func find(node: Node<Element>) -> Element? {
      switch node {
      case let .Some(_,    _, value,     _) where isEqual(value):          return value
      case let .Some(_, left, value,     _) where !isOrderedBefore(value): return find(left)
      case let .Some(_,    _, value, right) where isOrderedBefore(value):  return find(right)
      case .None:                                                         fallthrough
      default:                                                             return nil
      }
    }
    return find(root)
  }

  /**
   Remove all elements after the specified element

   - parameter element: Element
   */
  public mutating func dropAfter(element: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element) else { return }
    self = _Tree(elements[elements.startIndex ... idx])
  }

  /**
   Remove all elements before the specified element

   - parameter element: Element
   */
  public mutating func dropBefore(element: Element) {
    var elements = Array(self)
    guard let idx = elements.indexOf(element) else { return }
    self = _Tree(elements[idx ..< elements.endIndex])
  }

}

// MARK: - SequenceType
extension _Tree: SequenceType {

  /**
   Create a generator for an in-order traversal

   - returns: AnyGenerator<Element>
   */
  public func generate() -> AnyGenerator<Element> {
    // stack-based iterative inorder traversal to make it easy to use with anyGenerator
    var stack: [Node<Element>] = []
    var current: Node<Element> = root
    return anyGenerator { _ -> Element? in
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
extension _Tree: ArrayLiteralConvertible {

  /**
   Create a tree from an array literal

   - parameter elements: Element...
   */
  public init(arrayLiteral elements: Element...) { self.init(elements) }

}

// MARK: - CustomStringConvertible
extension _Tree: CustomStringConvertible {
  /// Array-like tree description
  public var description: String { return "[" + ", ".join(Array(self).map({String($0)})) + "]" }
}

// MARK: - CustomDebugStringConvertible
extension _Tree: CustomDebugStringConvertible {

  /// A more visually tree-like description
  public var debugDescription: String {
    var result = ""
    func describeNode(node: Node<Element>, _ height: Int, _ kind: String ) {
      let indent = "\t\t" * height
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
var tree: _Tree<Int> = [7, 49, 23, 8, 30, 22, 44, 28, 23, 9, 40, 15, 42, 42, 37, 3, 27, 29, 40, 12]
tree.debugDescription
tree.remove(27)
tree.debugDescription
tree.insert(27)
tree.debugDescription
tree.remove(3)
tree.debugDescription

