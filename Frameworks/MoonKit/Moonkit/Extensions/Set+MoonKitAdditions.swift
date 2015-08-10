//
//  Set+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/31/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

// contains
//public func ∈<T>(lhs: T, rhs: Set<T>) -> Bool { return rhs.contains(lhs) }
public func ∈<T>(lhs: T, rhs: Set<T>) -> Bool { return rhs.contains(lhs) }
public func ∋<T>(lhs: Set<T>, rhs: T) -> Bool { return lhs.contains(rhs) }
public func ∉<T>(lhs: T, rhs: Set<T>) -> Bool { return !(lhs ∈ rhs) }
public func ∌<T>(lhs: Set<T>, rhs: T) -> Bool { return !(lhs ∋ rhs) }

// subset/superset
public func ⊂<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Bool {
  return lhs.isStrictSubsetOf(rhs)
}
public func ⊃<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Bool {
  return lhs.isStrictSupersetOf(rhs)
}
public func ⊄<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Bool { return !(lhs ⊂ rhs) }
public func ⊅<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Bool { return !(lhs ⊃ rhs) }
public func ⊆<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Bool { return lhs.isSubsetOf(rhs) }
public func ⊇<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Bool { return lhs.isSupersetOf(rhs) }
public func ⊈<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Bool { return !(lhs ⊆ rhs) }
public func ⊉<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Bool { return !(lhs ⊇ rhs) }

// union
public func ∪<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Set<T> { return lhs.union(rhs) }
public func ∪=<S:SequenceType, T where S.Generator.Element == T>(inout lhs: Set<T>, rhs: S) { lhs.unionInPlace(rhs) }

// minus
public func ∖<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Set<T> { return lhs.subtract(rhs) }
public func ∖=<S:SequenceType, T where S.Generator.Element == T>(inout lhs: Set<T>, rhs: S) { lhs.subtractInPlace(rhs) }

// intersect
public func ∩<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Set<T> { return lhs.intersect(rhs) }
public func ∩=<S:SequenceType, T where S.Generator.Element == T>(inout lhs: Set<T>, rhs: S) { lhs.intersectInPlace(rhs) }

// xor
public func ∆<S:SequenceType, T where S.Generator.Element == T>(lhs: Set<T>, rhs: S) -> Set<T> { return lhs.exclusiveOr(rhs) }
public func ∆=<S:SequenceType, T where S.Generator.Element == T>(inout lhs: Set<T>, rhs: S) { lhs.exclusiveOrInPlace(rhs) }

public func filter<T>(source: Set<T>, includeElement: (T) -> Bool) -> Set<T> {
  return Set(Array(source).filter(includeElement))
}

extension Set: NestingContainer {
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
        result.extend(container.allObjects)
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
        result.extend(container.allObjects(type))
      } else if let v = value as? T {
        result.append(v)
      }
    }
    return result
  }
}

extension Set: KeySearchable {
  public var allValues: [Any] { return topLevelObjects }
}
