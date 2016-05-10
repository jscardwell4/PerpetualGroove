//
//  OrderedDictionarySlice.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public struct OrderedDictionarySlice<Key:Hashable, Value>: _OrderedDictionary, _DestructorSafeContainer {

  typealias Buffer = OrderedDictionarySliceBuffer<Key, Value>
  typealias Storage = OrderedDictionaryStorage<Key, Value>

  public typealias Index = Int
  public typealias Element = (Key, Value)
  public typealias _Element = Element
  public typealias SubSequence = OrderedDictionarySlice<Key, Value>

  var buffer: Buffer

  var capacity: Int { return buffer.capacity }

  public var startIndex: Int { return buffer.startIndex }
  public var endIndex: Int  { return buffer.endIndex }

  func cloneBuffer(newCapacity: Int) -> Buffer {
    fatalError("\(#function) not yet implemented")
  }

  func ensureUniqueWithCapacity(minimumCapacity: Int) -> (reallocated: Bool, capacityChanged: Bool) {
    fatalError("\(#function) not yet implemented")
  }

  public subscript(key: Key) -> Value? {
    get { return buffer.valueForKey(key) }
    set { fatalError("\(#function) not yet implemented") }
  }

  public subscript(position: Index) -> Element {
    get { return buffer[position] }
    set { fatalError("\(#function) not yet implemented") }
  }

  public subscript(subRange: Range<Index>) -> SubSequence {
    get {
      precondition(indices.contains(subRange))
      return SubSequence(buffer: buffer[subRange])
    }
    set {
      fatalError("\(#function) not yet implemented")
    }
  }

  init(buffer: Buffer) { self.buffer = buffer }

  public func insertValue(value: Value, forKey key: Key) {
    fatalError("\(#function) not yet implemented")
  }

  public func removeValueForKey(key: Key) -> Value? {
    fatalError("\(#function) not yet implemented")
  }

  public func updateValue(value: Value, forKey key: Key) -> Value? {
    fatalError("\(#function) not yet implemented")
  }

  public func indexForKey(key: Key) -> Index? {
    fatalError("\(#function) not yet implemented")
  }

  public func valueForKey(key: Key) -> Value? {
    fatalError("\(#function) not yet implemented")
  }

}

extension OrderedDictionarySlice: RangeReplaceableCollectionType {

  public init() {
    fatalError("\(#function) not yet implemented")
  }

  public mutating func replaceRange<
    C:CollectionType where C.Generator.Element == Element
    >(subRange: Range<Index>, with newElements: C)
  {
    fatalError("\(#function) not yet implemented")
  }

}


extension OrderedDictionarySlice: CustomStringConvertible {
  public var description: String {
    guard count > 0 else { return "[:]" }

    var result = "["
    var first = true
    for (key, value) in self {
      if first { first = false } else { result += ", " }
      debugPrint(key, terminator: "", toStream: &result)
      result += ": "
      debugPrint(value, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }
}

