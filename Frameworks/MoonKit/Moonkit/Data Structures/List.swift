//
//  List.swift
//  MoonKit
//  Source: https://gist.github.com/airspeedswift/list.swift
//  Created by Jason Cardwell on 8/16/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
private enum ListNode<Element> {
  case End
  indirect case Node(Element, tag: Int, next: ListNode<Element>)

  /// Computed property to fetch the tag. .End has an
  /// implicit tag of zero.
  var tag: Int {
    switch self {
    case .End: return 0
    case let .Node(_, tag: n, _):
      return n
    }
  }

  func cons(x: Element) -> ListNode<Element> {
    // each cons increments the tag by one
    return .Node(x, tag: tag+1, next: self)
  }
}

public struct ListIndex<Element> {
  private let node: ListNode<Element>
}

extension ListIndex: ForwardIndexType {
  public func successor() -> ListIndex<Element> {
    switch node {
    case .End:
      fatalError("cannot increment endIndex")
    case let .Node(_, _, next: next):
      return ListIndex(node: next)
    }
  }
}

public func == <T>(lhs: ListIndex<T>, rhs: ListIndex<T>) -> Bool {
  return lhs.node.tag == rhs.node.tag
}

public struct List<Element>: CollectionType {
  // Index's type could be inferred, but it helps make the
  // rest of the code clearer:
  public typealias Index = ListIndex<Element>

  public var startIndex: Index
  public var endIndex: Index

  public subscript(idx: Index) -> Element {
    switch idx.node {
    case .End: fatalError("Subscript out of range")
    case let .Node(x, _, _): return x
    }
  }

  func cons(x: Element) -> List<Element> {
    return List(startIndex: ListIndex(node: startIndex.node.cons(x)), endIndex: endIndex)
  }
}

extension List: ArrayLiteralConvertible {

  public init<S: SequenceType where S.Generator.Element == Element>(_ seq: S) {
    startIndex = ListIndex(node: seq.reverse().reduce(.End) {
      $0.cons($1)
      })
    endIndex = ListIndex(node: .End)
  }

  public init<C: CollectionType where C.Generator.Element == Element>(_ col: C) {
    startIndex = ListIndex(node: col.reverse().reduce(.End) {
      $0.cons($1)
      })
    endIndex = ListIndex(node: .End)
  }

  public init(arrayLiteral elements: Element...) {
    self = List(elements)
  }
}

extension List: CustomStringConvertible {
  public var description: String {
    var desc = "["
    desc += ", ".join(self.map { String($0) })
    desc += "]"
    return desc
  }
}

extension List {
  public var count: Int {
    return startIndex.node.tag - endIndex.node.tag
  }
}

public func == <T: Equatable>(lhs: List<T>, rhs: List<T>) -> Bool {
  return lhs.elementsEqual(rhs)
}

extension List {
  private init (subRange: Range<Index>) {
    startIndex = subRange.startIndex
    endIndex = subRange.endIndex
  }
  public subscript (subRange: Range<Index>) -> List<Element> {
    return List(subRange: subRange)
  }
}

extension List {
  public func reverse() -> List<Element> {
    let reversednodes: ListNode<Element>
    = self.reduce(.End) { $0.cons($1) }

    return List(startIndex: ListIndex(node: reversednodes),
      endIndex: ListIndex(node: .End))
  }
}
