//: Playground - noun: a place where people can play

import Foundation
import UIKit


enum Color { case Red, Black }

indirect enum _Tree<Element: Comparable> {
    case Empty
    case Node(Color, _Tree<Element>, Element, _Tree<Element>)
    
    init() { self = .Empty }
    
    init(_ x: Element, color: Color = .Black, 
        left: _Tree<Element> = .Empty, right: _Tree<Element> = .Empty)
    {
        self = .Node(color, left, x, right)
    }
}


extension _Tree {
    func contains(x: Element) -> Bool {
        switch self {
        case .Empty: return false
        case let .Node(_, left, y, right):
            if x < y { return left.contains(x) }
            if y < x { return right.contains(x) }
            return true
        }
    }
}


private func balance<T>(tree: _Tree<T>) -> _Tree<T> {
    switch tree {
    case let .Node(.Black, .Node(.Red, .Node(.Red, a, x, b), y, c), z, d):
        return .Node(.Red, .Node(.Black, a, x, b), y, .Node(.Black, c, z, d))
    case let .Node(.Black, .Node(.Red, a, x, .Node(.Red, b, y, c)), z, d):
        return .Node(.Red, .Node(.Black, a, x, b), y, .Node(.Black, c, z, d))
    case let .Node(.Black, a, x, .Node(.Red, .Node(.Red, b, y, c), z, d)):
        return .Node(.Red, .Node(.Black, a, x, b), y, .Node(.Black, c, z, d))
    case let .Node(.Black, a, x, .Node(.Red, b, y, .Node(.Red, c, z, d))):
        return .Node(.Red, .Node(.Black, a, x, b), y, .Node(.Black, c, z, d))
    default:
        return tree
    }
}


private func ins<T>(into: _Tree<T>, _ x: T) -> _Tree<T> {
    switch into {
    case .Empty: return _Tree(x, color: .Red)
    case let .Node(c, l, y, r):
        if x < y { return balance(_Tree(y, color: c, left: ins(l, x), right: r)) }
        if y < x { return balance(_Tree(y, color: c, left: l, right: ins(r, x))) }
        return into
    }
}


extension _Tree {
    func insert(x: Element) -> _Tree {
        switch ins(self, x) {
        case let .Node(_, l, y, r):
            return .Node(.Black, l, y, r)
        default:
            fatalError("ins should never return an empty tree")
        }
    }
}


extension _Tree: SequenceType {
    func generate() -> AnyGenerator<Element> {
        // stack-based iterative inorder traversal to
        // make it easy to use with anyGenerator
        var stack: [_Tree] = []
        var current: _Tree = self
        return anyGenerator { _ -> Element? in
            while true {
                switch current {
                case let .Node(_, l, _, _):
                    stack.append(current)
                    current = l
                case .Empty where !stack.isEmpty:
                    switch stack.removeLast() {
                    case let .Node(_, _, x, r):
                        current = r
                        return x
                    default:
                        break
                    }
                case .Empty:
                    return nil
                }
            }
        }
    }
}


extension _Tree: ArrayLiteralConvertible {
    init<S: SequenceType where S.Generator.Element == Element>(_ source: S) {
        self = source.reduce(_Tree()) { $0.insert($1) }
    }
    
    init(arrayLiteral elements: Element...) {
        self = _Tree(elements)
    }
}

import MoonKit

extension _Tree {

  /// A more visually tree-like description
  var treeDescription: String {
    var result = ""
    func describeTree(tree: _Tree<Element>, _ height: Int, _ kind: String ) {
      let indent = "  " * height
      let heightString = "[" + String(height).pad(" ", count: 2, type: .Prefix) + "\(kind)]"
      switch tree {
      case .Empty:
        let colorString = "black"
        result += "\(indent)\(heightString) <\(colorString)> nil\n"
      case let .Node(color, left, value, right):
        let colorString = "\(color)"
        let valueString = String(value)
        result += "\(indent)\(heightString) <\(colorString)> \(valueString)\n"
        describeTree(left, height + 1, "L")
        describeTree(right, height + 1, "R")
      }
    }

    describeTree(self, 0, " ")
    return result
  }
}

import Darwin

extension Array {
    func shuffle() -> [Element] {
        var list = self
        for i in 0..<(list.count - 1) {
            let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
          guard i != j else { continue }
            swap(&list[i], &list[j])
        }
        return list
    }
}


let engines = [
    "Daisy", "Salty", "Harold", "Cranky", 
    "Thomas", "Henry", "James", "Toby", 
    "Belle", "Diesel", "Stepney", "Gordon", 
    "Captain", "Percy", "Arry", "Bert", 
    "Spencer", 
]
let permutations = [engines, engines.sort(), engines.sort(>), engines.shuffle(), engines.shuffle(), engines.shuffle()]
// test various inserting engines in various different permutations
let h1 = hostTime
for permutation in permutations {
  let t = _Tree(permutation)
  var t2 = t.insert("Thomas")
  assert(!t.contains("Fred"))
  assert(t.contains("James"))
  assert(t.elementsEqual(t2))
  assert(!engines.contains { !t.contains($0) })
  assert(t.elementsEqual(engines.sort()))
  //  print(t.joinWithSeparator(", "))
  //    print(t.treeDescription)
}
let h2 = hostTime

//print("")


// test various inserting engines in various different permutations
for permutation in permutations {
  let t = Tree<String>(permutation)
  var t2 = t
  t2.insert("Thomas")
  assert(!t.contains("Fred"))
  assert(t.contains("James"))
  assert(t.elementsEqual(t2))
  assert(!engines.contains { !t.contains($0) })
  assert(t.elementsEqual(engines.sort()))
  //  print(t.joinWithSeparator(", "))
  //  print(t.debugDescription)
  //  assert(t.minElement() == "Arry")
  //  assert(t.maxElement() == "Toby")
}
let h3 = hostTime

h2 - h1
h3 - h2
