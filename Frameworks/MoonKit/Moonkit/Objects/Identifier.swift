//
//  Identifier.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/16/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation


public struct Identifier: MutableSliceable, RangeReplaceableCollectionType {
  public private(set) var tags: [Tag] = [] { didSet { tags = filteredTags(tags) } }

  public mutating func reserveCapacity(n: Index.Distance) { tags.reserveCapacity(n) }

  public mutating func append(newElement: Generator.Element) { tags.append(newElement) }

  public mutating func extend<S : SequenceType where S.Generator.Element == Generator.Element>(newElements: S) {
    tags.extend(newElements)
  }

  public mutating func insert(newElement: Generator.Element, atIndex i: Index) {
    tags.insert(newElement, atIndex: i)
  }

  public mutating func splice<S : CollectionType where S.Generator.Element == Generator.Element>(newElements: S, atIndex i: Index) {
    tags.splice(newElements, atIndex: i)
  }

  public mutating func removeAtIndex(i: Index) -> Generator.Element { return tags.removeAtIndex(i) }

  public mutating func removeRange(subRange: Range<Index>) { tags.removeRange(subRange) }

  public mutating func removeAll(keepCapacity keepCapacity: Bool) { tags.removeAll(keepCapacity: keepCapacity) }

  public typealias Index = Array<Tag>.Index
  public typealias Generator = Array<Tag>.Generator

  public func generate() -> Generator {
    return tags.generate()
  }
  public var string: String { return tagSeparator.join(tags) }

  public typealias Tag = String
  public var tagSeparator = Identifier.defaultTagSeparator

  public static let defaultTagSeparator = "-"

  public var startIndex: Int { return 0 }
  public var endIndex: Int { return tags.count }

  public subscript(idx: Int) -> Tag {
    get { return tags[idx] }
    set { tags[idx] = filteredTag(newValue) }
  }
  public subscript(bounds: Range<Int>) -> ArraySlice<Tag> {
    get { return tags[bounds] }
    set { tags[bounds] = ArraySlice(filteredTags(newValue)) }
  }

  public mutating func replaceRange<C : CollectionType where C.Generator.Element == Tag>(subRange: Range<Int>,
                              with newElements: C)
  {
    tags.replaceRange(subRange, with: newElements)
  }

  /**
  filteredTag:

  - parameter tag: Tag

  - returns: Tag
  */
  private func filteredTag(tag: Tag) -> Tag { return tag.sub(~/"\\\(tagSeparator)", "\(tagSeparator)") }

  /**
  filteredTags:

  - parameter tags: C

  - returns: [Tag]
  */
  private func filteredTags<C:CollectionType where C.Generator.Element == Tag>(tags: C) -> [Tag] {
    return tags.map { self.filteredTag($0) }
  }

  private init(withTags t: [Tag]) {
    self.init()
    tags = filteredTags(t)
  }

  public init() {}

  /**
  initialize with the type name of an object

  - parameter object: Any
  */
  public init(_ object: Any) { self.init(withTags: [typeName(object)]) }

  /**
  initialize with the type name of an object and a list of strings

  - parameter object: Any
  - parameter tags: Tag ...
  */
  public init(_ object: Any, _ tags: Tag ...) { self.init(withTags: [typeName(object)] + tags) }

  /**
  initialize from a list of strings

  - parameter tags: Tag ...
  */
  public init(_ tags: Tag ...) { self.init(withTags: tags) }

  /**
  init:

  - parameter string: String
  */
  public init(_ string: String) {
    self.init(string, tagSeparator: Identifier.defaultTagSeparator)
  }

  /**
  initialize from a string using the specified separator

  - parameter string: String
  - parameter tagSeparator: String
  */
  public init(_ string: String, tagSeparator: String) {
    self.init(withTags: tagSeparator.split(string))
    self.tagSeparator = tagSeparator
  }

}

extension Identifier: ArrayLiteralConvertible {

  /**
  initialize from an array literal of strings

  - parameter elements: Tag
  */
  public init(arrayLiteral elements: Tag ...) { self.init(withTags: elements) }

}

extension Identifier: StringLiteralConvertible {

  /**
  initialize from a literal string

  - parameter value: String
  */
  public init(stringLiteral value: String) { self.init(withTags: Identifier.defaultTagSeparator.split(value)) }

  /**
  initialize from a literal string

  - parameter value: String
  */
  public init(extendedGraphemeClusterLiteral value: String) { self.init(withTags: Identifier.defaultTagSeparator.split(value)) }

  /**
  initialize from a literal string

  - parameter value: String
  */
  public init(unicodeScalarLiteral value: String) { self.init(withTags: Identifier.defaultTagSeparator.split(value)) }

}

extension Identifier: Comparable {}
public func ==(lhs: Identifier, rhs: Identifier) -> Bool { return lhs.string == rhs.string }
public func <(lhs: Identifier, rhs: Identifier) -> Bool { return lhs.string < rhs.string }

public func ∋(lhs: Identifier, rhs: Identifier.Tag) -> Bool { return lhs.tags ∋ rhs }
