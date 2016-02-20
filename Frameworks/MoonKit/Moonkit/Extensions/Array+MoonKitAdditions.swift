//
//  Array+MoonKitAdditions.swift
//  Remote
//
//  Created by Jason Cardwell on 12/20/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

extension Array {
  func compressedMap<U>(transform: (Element) -> U?) -> [U] {
      return MoonKit.compressedMap(self, transform)
  }
}

extension Array: JSONValueConvertible {
  public var jsonValue: JSONValue {
    var elements: [JSONValue] = []
    for element in flatMap({$0 as? JSONValueConvertible}) {
      elements.append(element.jsonValue)
    }
    return JSONValue.Array(elements)
  }
}

extension Array: NestingContainer {
  public var topLevelObjects: [Any] {
    var result: [Any] = []
    for value in self {
      result.append(value as Any)
    }
    return result
  }
  public func topLevelObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in self {
      if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
  public var allObjects: [Any] {
    var result: [Any] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.appendContentsOf(container.allObjects)
      } else {
        result.append(value as Any)
      }
    }
    return result
  }
  public func allObjects<T>(type: T.Type) -> [T] {
    var result: [T] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.appendContentsOf(container.allObjects(type))
      } else if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }

  public var formattedDescription: String {
    guard count > 0 else { return "[]" }
    let description = "\(self)"
    return "[\n\(description[description.startIndex.advancedBy(1) ..< description.endIndex.advancedBy(-1)].indentedBy(4))\n]"
  }
}

extension Array: KeySearchable {
  public var allValues: [Any] { return topLevelObjects }
}

// contains
public func ∈<Element:Equatable>(lhs: Element, rhs: [Element]) -> Bool {return rhs.contains(lhs) }
public func ∋<Element:Equatable>(lhs: [Element], rhs: Element) -> Bool {return lhs.contains(rhs) }
public func ∉<Element:Equatable>(lhs: Element, rhs: [Element]) -> Bool { return !(lhs ∈ rhs) }
public func ∌<Element:Equatable>(lhs: [Element], rhs: Element) -> Bool { return !(lhs ∋ rhs) }

// subset/superset
public func ⊂<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return Set(lhs) ⊂ Set(rhs)
}

public func ⊃<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return Set(lhs) ⊃ Set(rhs)
}

public func ⊆<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return Set(lhs) ⊆ Set(rhs)
}

public func ⊇<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return Set(lhs) ⊇ Set(rhs)
}

public func ⊄<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return !(lhs ⊂ rhs) 
}

public func ⊅<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return !(lhs ⊃ rhs) 
}

public func ⊈<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return !(lhs ⊆ rhs) 
}

public func ⊉<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return !(lhs ⊇ rhs) 
}


// union
public func ∪<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> [Element] 
{ 
  return Array(Set(lhs) ∪ Set(rhs))
}

public func ∪=<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(inout lhs: [Element], rhs: S)
 {
  lhs = lhs ∪ rhs
}

// minus
public func ∖<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> [Element] 
{ 
  return Array(Set(lhs) ∖ Set(rhs))
}

public func ∖=<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(inout lhs: [Element], rhs: S)
 {
  lhs = lhs ∖ rhs
}

// intersect
public func ∩<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> [Element] 
{ 
  return Array(Set(lhs) ∩ Set(rhs))
}

public func ∩=<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(inout lhs: [Element], rhs: S)
 {
  lhs = lhs ∩ rhs
}

// xor
public func ⊻<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> [Element] 
{ 
  return Array(Set(lhs) ⊻ Set(rhs))
}

public func ⊻=<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(inout lhs: [Element], rhs: S)
 {
  lhs = lhs ⊻ rhs
}

// disjoint
public func !⚭<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return Set(lhs) !⚭ Set(rhs)
}

public func ⚭<
  S:SequenceType, Element:Hashable where S.Generator.Element == Element
>(lhs: [Element], rhs: S) -> Bool 
{ 
  return Set(lhs) ⚭ Set(rhs)
}

