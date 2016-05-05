//
//  OrderedDictionarySlice.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public struct OrderedDictionarySlice<Key:Hashable, Value>: CollectionType {

  typealias Buffer = OrderedDictionaryBuffer<Key, Value>

  let buffer: Buffer
  let bounds: Range<Int>

  public typealias Index = Int
  public typealias Element = (Key, Value)
  public typealias _Element = Element

  public typealias Generator = OrderedDictionaryGenerator<Key, Value>
  public typealias SubSequence = OrderedDictionarySlice<Key, Value>

  public var startIndex: Int { return bounds.startIndex }
  public var endIndex: Int  { return bounds.endIndex }

  public subscript(position: Index) -> Element { return buffer.elementAtPosition(position) }

  public subscript(bounds: Range<Index>) -> SubSequence {
    precondition(self.bounds.contains(bounds))
    return SubSequence(buffer: buffer, bounds: bounds)
  }

  init(buffer: Buffer, bounds: Range<Int>) {
    precondition(bounds.startIndex >= 0, "Invalid start for bounds: \(bounds.startIndex)")
    precondition(bounds.endIndex <= buffer.count, "Invalid end for bounds: \(bounds.endIndex)")
    self.buffer = buffer
    self.bounds = bounds
  }

  public func generate() -> Generator { return Generator(buffer: buffer, bounds: bounds) }
  
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

