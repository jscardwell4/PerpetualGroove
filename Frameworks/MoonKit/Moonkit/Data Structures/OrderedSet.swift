//
//  OrderedSet.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/28/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

public struct OrderedSet<Element:Equatable> : MutableCollectionType {

  private var storage: [Element] {
    didSet {
      var s: [Element] = []
      for e in storage { if !s.contains(e) { s.append(e) } }
      storage = s
    }
  }

  public var startIndex: Int { return storage.startIndex }
  public var endIndex: Int { return storage.endIndex }

  /**
  subscript:

  - parameter index: Int

  - returns: Element
  */
  public subscript (index: Int) -> Element {
    get { return storage[index] }
    set { if !storage.contains(newValue) { storage[index] = newValue } }
  }

  /**
  generate

  - returns: IndexingGenerator<[Element]>
  */
  public func generate() -> IndexingGenerator<[Element]> { return storage.generate() }

  public typealias SubSlice = ArraySlice<Element>

  /**
  subscript:

  - parameter subRange: Range<Int>

  - returns: ArraySlice<Element>
  */
  public subscript (subRange: Range<Int>) -> ArraySlice<Element> { return storage[subRange] }

  /**
  init:

  - parameter buffer: _ArrayBuffer<Element>
  */
  public init(_ buffer: _ArrayBuffer<Element>) { storage = uniqued([Element](buffer)) }


  /** init */
  public init() { storage = [] }

  /**
  init:

  - parameter s: S
  */
  public init<S:SequenceType where S.Generator.Element == Element>(_ s: S) { storage = uniqued([Element](s)) }

  public var count: Int      { return storage.count    }
  public var capacity: Int   { return storage.capacity }
  public var isEmpty: Bool   { return storage.isEmpty  }
  public var first: Element?       { return storage.first    }
  public var last: Element?        { return storage.last     }
  public var array: [Element]      { return storage          }
  public var bridgedValue: NSOrderedSet? { return NSOrderedSet(array: storage._bridgeToObjectiveC() as [AnyObject]) }
  public var NSArrayValue: NSArray? {
    var elements: [NSObject] = []
    for element in storage {
      if let e = element as? NSObject {
        elements.append(e)
      }
    }
    return elements.count == storage.count ? NSArray(array: elements) : nil
  }

  public var NSSetValue: NSSet? {
    if let array = NSArrayValue { return NSSet(array: array as [AnyObject]) } else { return nil }
  }

  public var NSOrderedSetValue: NSOrderedSet? {
    if let array = NSArrayValue { return NSOrderedSet(array: array as [AnyObject]) } else { return nil }
  }

  /**
  reserveCapacity:

  - parameter minimumCapacity: Int
  */
  public mutating func reserveCapacity(minimumCapacity: Int) { storage.reserveCapacity(minimumCapacity) }

  /**
  append:

  - parameter newElement: Element
  */
  public mutating func append(newElement: Element) { if !storage.contains(newElement) { storage.append(newElement) } }

  /**
  extend:

  - parameter elements: S
  */
  public mutating func extend<S:SequenceType where S.Generator.Element == Element>(elements: S) {
    storage.extend(elements.filter { !self.storage.contains($0) })
  }

  /**
  removeLast

  - returns: Element
  */
  public mutating func removeLast() -> Element { return storage.removeLast() }

  /**
  insert:atIndex:

  - parameter newElement: Element
  - parameter i: Int
  */
  public mutating func insert(newElement: Element, atIndex i: Int) {
    if !storage.contains(newElement) { storage.insert(newElement, atIndex: i) }
  }

  /**
  removeAtIndex:

  - parameter index: Int

  - returns: Element
  */
  public mutating func removeAtIndex(index: Int) -> Element { return storage.removeAtIndex(index) }

  /**
  removeAll:

  - parameter keepCapacity: Bool = false
  */
  public mutating func removeAll(keepCapacity: Bool = false) { storage.removeAll(keepCapacity: keepCapacity) }

  /**
  join:

  - parameter elements: S

  - returns: [Element]
  */
  public func join<S:SequenceType where S.Generator.Element == Element>(elements: S) -> [Element] {
    let elementsArray = Array(elements)
    let currentArray = storage
    return uniqued(elementsArray + currentArray)
  }

  /**
  reduce:combine:

  - parameter initial: U
  - parameter combine: (U, Element) -> U

  - returns: U
  */
  public func reduce<U>(initial: U, combine: (U, Element) -> U) -> U { return storage.reduce(initial, combine: combine) }

  /**
  sort:

  - parameter isOrderedBefore:  (Element, Element) -> Bool
  */
  public mutating func sort(isOrderedBefore:  (Element, Element) -> Bool) { storage.sortInPlace(isOrderedBefore) }

  /**
  sorted:

  - parameter isOrderedBefore: (Element, Element) -> Bool

  - returns: [Element]
  */
  public func sorted(isOrderedBefore: (Element, Element) -> Bool) -> OrderedSet<Element> { return OrderedSet(storage.sort(isOrderedBefore)) }

  /**
  map:

  - parameter transform: (Element) -> U

  - returns: [U]
  */
  public func map<U: Equatable>(transform: (Element) -> U) -> OrderedSet<U> { return OrderedSet<U>(storage.map(transform)) }

  /**
  reverse

  - returns: [Element]
  */
  public func reverse() -> OrderedSet<Element> { return OrderedSet(Array(storage.reverse())) }

  /**
  filter:

  - parameter includeElement: (Element) -> Bool

  - returns: [Element]
  */
  public func filter(includeElement: (Element) -> Bool) -> OrderedSet<Element> { return OrderedSet<Element>(storage.filter(includeElement)) }

  /**
  replaceRange:with:

  - parameter subRange: Range<Int>
  - parameter elements: C
  */
  public mutating func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Int>, with elements: C) {
    var s = storage
    s.replaceRange(subRange, with: elements)
    storage = s
  }

  /**
  splice:atIndex:

  - parameter elements: S
  - parameter i: Int
  */
  public mutating func splice<S : CollectionType where S.Generator.Element == Element>(elements: S, atIndex i: Int) {
    var s = storage
    s.splice(elements, atIndex: i)
    storage = s
  }

  /**
  removeRange:

  - parameter subRange: Range<Int>
  */
  public mutating func removeRange(subRange: Range<Int>) { storage.removeRange(subRange) }

  /**
  Returns true if the set is a subset of a finite sequence as a `Set`.

  - parameter sequence: S

  - returns: Bool
  */
  public func isSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return filter({sequence.contains($0)}).count == count
  }

  /**
  Returns true if the set is a subset of a finite sequence as a `Set` but not equal.

  - parameter sequence: S

  - returns: Bool
  */
  public func isStrictSubsetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return isSubsetOf(sequence) && count < Array(sequence).count
  }

  /**
  Returns true if the set is a superset of a finite sequence as a `Set`.

  - parameter sequence: S

  - returns: Bool
  */
  public func isSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return sequence.filter({self.contains($0)}).count == Array(sequence).count
  }

  /**
  Returns true if the set is a superset of a finite sequence as a `Set` but not equal.

  - parameter sequence: S

  - returns: Bool
  */
  public func isStrictSupersetOf<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool
  {
    return isSupersetOf(sequence) && count > Array(sequence).count
  }

  /**
  Returns true if no members in the set are in a finite sequence as a `Set`.

  - parameter sequence: S

  - returns: Bool
  */
  public func isDisjointWith<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> Bool {
    return intersect(sequence).count == 0
  }

  /**
  Return a new `OrderedSet` with items in both this set and a finite sequence.

  - parameter sequence: S

  - returns: OrderedSet<Element>
  */
  public func union<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self; result.unionInPlace(sequence); return result
  }

  /**
  Insert elements of a finite sequence into this `Set`.

  - parameter sequence: S
  */
  public mutating func unionInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) { extend(sequence) }

  /**
  Return a new set with elements in this set that do not occur in a finite sequence.

  - parameter sequence: S

  - returns: OrderedSet<Element>
  */
  public func subtract<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self; result.subtractInPlace(sequence); return result
  }

  /**
  Remove all members in the set that occur in a finite sequence.

  - parameter sequence: S
  */
  public mutating func subtractInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for idx in sequence.flatMap({self.storage.indexOf($0)}) { storage.removeAtIndex(idx) }
  }

  /**
  Return a new set with elements common to this set and a finite sequence.

  - parameter sequence: S

  - returns: OrderedSet<Element>
  */
  public func intersect<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self; result.intersectInPlace(sequence); return result
  }

  /**
  Remove any members of this set that aren't also in a finite sequence.

  - parameter sequence: S
  */
  public mutating func intersectInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    for (i, element) in enumerate() where element ∉ sequence { removeAtIndex(i) }
  }

  /**
  Return a new set with elements that are either in the set or a finite sequence but do not occur in both.

  - parameter sequence: S

  - returns: OrderedSet<Element>
  */
  public func exclusiveOr<S:SequenceType where S.Generator.Element == Element>(sequence: S) -> OrderedSet<Element> {
    var result = self; result.exclusiveOrInPlace(sequence); return result
  }

  /**
  For each element of a finite sequence, remove it from the set if it is a common element, otherwise add it to the set. Repeated 
  elements of the sequence will be ignored.

  - parameter sequence: S
  */
  public mutating func exclusiveOrInPlace<S:SequenceType where S.Generator.Element == Element>(sequence: S) {
    intersectInPlace(subtract(sequence).union(OrderedSet(sequence).subtract(self)))
  }



}

// MARK: - ArrayLiteralConvertible
extension OrderedSet : ArrayLiteralConvertible {

  /**
  init:

  - parameter elements: Element...
  */
  public init(arrayLiteral elements: Element...) { storage = elements }

}

extension OrderedSet : CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String { return storage.description }
  public var debugDescription: String { return storage.debugDescription }
}

// MARK: - _ObjectiveBridgeable
extension OrderedSet: _ObjectiveCBridgeable {
  static public func _isBridgedToObjectiveC() -> Bool {
    return true
  }
  public typealias _ObjectiveCType = NSOrderedSet
  static public func _getObjectiveCType() -> Any.Type { return _ObjectiveCType.self }
  public func _bridgeToObjectiveC() -> _ObjectiveCType {
    var objects: [AnyObject] = []
    for object in storage {
      if object is AnyObject {
        objects.append(object as! AnyObject)
      }
    }
    if objects.count == self.count {
      return NSOrderedSet(array: objects)
    } else {
      return NSOrderedSet()
    }
  }

  static public func _forceBridgeFromObjectiveC(source: NSOrderedSet, inout result: OrderedSet?) {
    var s = OrderedSet()
    for o in source {
      if let object = typeCast(o, Element.self) { s.append(object) }
    }
    if s.count == source.count {
      result = s
    }
  }
  static public func _conditionallyBridgeFromObjectiveC(source: NSOrderedSet, inout result: OrderedSet?) -> Bool {
    var s = OrderedSet()
    for o in source {
      if let object = typeCast(o, Element.self) { s.append(object) }
    }
    if s.count == source.count {
      result = s
      return true
    }
    return false
  }
}

// MARK: - Equatable
extension OrderedSet : Equatable {}

/**
subscript:rhs:

- parameter lhs: OrderedSet<T>
- parameter rhs: OrderedSet<T>

- returns: Bool
*/
public func ==<T>(lhs: OrderedSet<T>, rhs: OrderedSet<T>) -> Bool { return lhs.storage == rhs.storage }

// MARK: - Operators

/**
subscript:rhs:

- parameter lhs: OrderedSet<T>
- parameter rhs: S

- returns: OrderedSet<T>
*/
public func +<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> OrderedSet<T> {
  return lhs.union(rhs)
}

/**
subscript:rhs:

- parameter lhs: OrderedSet<T>
- parameter rhs: S
*/
public func +=<T:Equatable, S:SequenceType where S.Generator.Element == T>(inout lhs: OrderedSet<T>, rhs: S) {
  lhs.unionInPlace(rhs)
}

/**
Union set operator

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: OrderedSet<T>
*/
public func ∪<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> OrderedSet<T> {
  return lhs.union(rhs)
}

/**
Union set operator which stores result in lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
*/
public func ∪=<T:Equatable, S:SequenceType where S.Generator.Element == T>(inout lhs: OrderedSet<T>, rhs: S) {
  lhs.unionInPlace(rhs)
}

/**
Minus set operator

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: OrderedSet<T>
*/
public func ∖<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> OrderedSet<T> {
  return lhs.subtract(rhs)
}

/**
Minus set operator which stores result in lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
*/
public func ∖=<T:Equatable, S:SequenceType where S.Generator.Element == T>(inout lhs: OrderedSet<T>, rhs: S) {
  lhs.subtractInPlace(rhs)
}

/**
Intersection set operator

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: OrderedSet<T>
*/
public func ∩<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> OrderedSet<T> {
  return lhs.intersect(rhs)
}


/**
Intersection set operator which stores result in lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
*/
public func ∩=<T:Equatable, S:SequenceType where S.Generator.Element == T>(inout lhs: OrderedSet<T>, rhs: S) {
  lhs.intersectInPlace(rhs)
}

/**
Returns true if lhs is a subset of rhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: Bool
*/
public func ⊆<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool {
  return lhs.isSubsetOf(rhs) == true
}

/**
Returns true if lhs is not a subset of rhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: Bool
*/
public func ⊈<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool {
  return lhs.isSubsetOf(rhs) == false
}

/**
Returns true if rhs is a subset of lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: Bool
*/
public func ⊇<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool {
  return lhs.isSupersetOf(rhs) == true
}

/**
Returns true if rhs is not a subset of lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: Bool
*/
public func ⊉<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool {
  return lhs.isSupersetOf(rhs) == false
}

/**
Returns true if lhs is a subset of rhs but not equal

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: Bool
*/
public func ⊂<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool {
  return lhs.isStrictSubsetOf(rhs) == true
}

/**
Returns true if lhs is not a subset of rhs; or if it is equal to rhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: Bool
*/
public func ⊄<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool {
  return lhs.isStrictSubsetOf(rhs) == false
}

/**
Returns true if rhs is a subset of lhs but not equal

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: Bool
*/
public func ⊃<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool {
  return lhs.isStrictSupersetOf(rhs) == true
}

/**
Returns true if rhs is not a subset of lhs; or if it is equal to lhs

- parameter lhs: OrderedSet<T>
- parameter rhs: S
- returns: Bool
*/
public func ⊅<T:Equatable, S:SequenceType where S.Generator.Element == T>(lhs: OrderedSet<T>, rhs: S) -> Bool {
  return lhs.isStrictSupersetOf(rhs) == false
}

/**
Returns true if rhs contains lhs

- parameter lhs: T
- parameter rhs: OrderedSet<T>
- returns: Bool
*/
public func ∈<T:Equatable>(lhs: T, rhs: OrderedSet<T>) -> Bool { return rhs.contains(lhs) == true }

/**
Returns true if lhs is not nil and rhs contains lhs

- parameter lhs: T?
- parameter rhs: OrderedSet<T>
- returns: Bool
*/
public func ∈<T:Equatable>(lhs: T?, rhs: OrderedSet<T>) -> Bool { return lhs != nil && rhs.contains(lhs!) == true }

/**
Returns true if lhs contains rhs

- parameter lhs: OrderedSet<T>
- parameter rhs: T
- returns: Bool
*/
public func ∋<T:Equatable>(lhs: OrderedSet<T>, rhs: T) -> Bool { return lhs.contains(rhs) == true }

/**
Returns true if rhs does not contain lhs

- parameter lhs: T
- parameter rhs: OrderedSet<T>
- returns: Bool
*/
public func ∉<T:Equatable>(lhs: T, rhs: OrderedSet<T>) -> Bool { return rhs.contains(lhs) == false }

/**
Returns true if lhs does not contain rhs

- parameter lhs: OrderedSet<T>
- parameter rhs: T
- returns: Bool
*/
public func ∌<T:Equatable>(lhs: OrderedSet<T>, rhs: T) -> Bool { return lhs.contains(rhs) == false }

// MARK: - NestingContainer
extension OrderedSet: NestingContainer {
  public var topLevelObjects: [Any] {
    var result: [Any] = []
    for value in self {
      result.append(value as Any)
    }
    return result
  }
  public func topLevelObjects<Element>(type: Element.Type) -> [Element] {
    var result: [Element] = []
    for value in self {
      if let v = value as? Element {
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
  public func allObjects<Element>(type: Element.Type) -> [Element] {
    var result: [Element] = []
    for value in self {
      if let container = value as? NestingContainer {
        result.extend(container.allObjects(type))
      } else if let v = value as? Element {
        result.append(v)
      }
    }
    return result
  }
}

// MARK: - KeySearchable
extension OrderedSet: KeySearchable {
  public var allValues: [Any] { return topLevelObjects }
}
