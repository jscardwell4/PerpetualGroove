//
//  OrderedDictionarySlice.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public struct OrderedDictionarySlice<Key:Hashable, Value>: CollectionType, _DestructorSafeContainer {

  typealias Buffer = OrderedDictionarySliceBuffer<Key, Value>

  var buffer: Buffer

  public typealias Index = Int
  public typealias Element = (Key, Value)
  public typealias _Element = Element

  public typealias Generator = IndexingGenerator<OrderedDictionarySlice<Key, Value>> // OrderedDictionaryGenerator<Key, Value>
  public typealias SubSequence = OrderedDictionarySlice<Key, Value>

  public var startIndex: Int { return buffer.startIndex }
  public var endIndex: Int  { return buffer.endIndex }

  public subscript(position: Index) -> Element { return buffer[position] }

  public subscript(subRange: Range<Index>) -> SubSequence {
    precondition(indices.contains(subRange))
    return SubSequence(buffer: buffer[subRange])
  }

  init(buffer: Buffer) { self.buffer = buffer }

  public func generate() -> Generator { return Generator(self) } //buffer: buffer, bounds: bounds) }

  public var keys: LazyMapCollection<OrderedDictionarySlice<Key, Value>, Key> {
    return lazy.map { $0.0 }
  }

  public var values: LazyMapCollection<OrderedDictionarySlice<Key, Value>, Value> {
    return lazy.map { $0.1 }
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

