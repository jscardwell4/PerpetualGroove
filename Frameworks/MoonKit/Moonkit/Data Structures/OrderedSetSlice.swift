//
//  OrderedSetSlice.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/5/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

//public struct OrderedSetSlice<Element:Hashable>: CollectionType {
//
//  typealias Buffer = OrderedSetBuffer<Element>
//
//  private(set) var buffer: Buffer
//  let bounds: Range<Int>
//
//  public typealias Index = Int
//  public typealias SubSequence = OrderedSetSlice<Element>
//
//  public var startIndex: Int { return bounds.startIndex }
//  public var endIndex: Int  { return bounds.endIndex }
//
//  public subscript(position: Index) -> Element { return buffer.elementAtPosition(position) }
//
//  public subscript(bounds: Range<Index>) -> SubSequence {
//    precondition(self.bounds.contains(bounds))
//    return SubSequence(buffer: buffer, bounds: bounds)
//  }
//
//  init(buffer: Buffer, bounds: Range<Int>) {
//    precondition(bounds.startIndex >= 0, "Invalid start for bounds: \(bounds.startIndex)")
//    precondition(bounds.endIndex <= buffer.count, "Invalid end for bounds: \(bounds.endIndex)")
//    self.buffer = buffer
//    self.bounds = bounds
//  }
//
//}
//
//extension OrderedSetSlice: CustomStringConvertible {
//  public var description: String {
//    var result = "["
//    var first = true
//    for item in self {
//      if first { first = false } else { result += ", " }
//      debugPrint(item, terminator: "", toStream: &result)
//    }
//    result += "]"
//    return result
//  }
//}

public struct OrderedSetSlice<Element:Hashable>: CollectionType {

  typealias Buffer = HashedStorageBuffer<OrderedSetStorage<Element>>

  private(set) var buffer: Buffer
  let bounds: Range<Int>

  public typealias Index = Int
  public typealias SubSequence = OrderedSetSlice<Element>

  public var startIndex: Int { return bounds.startIndex }
  public var endIndex: Int  { return bounds.endIndex }

  public subscript(position: Index) -> Element { return buffer.elementForPosition(position) }

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

}

extension OrderedSetSlice: CustomStringConvertible {
  public var description: String {
    var result = "["
    var first = true
    for item in self {
      if first { first = false } else { result += ", " }
      debugPrint(item, terminator: "", toStream: &result)
    }
    result += "]"
    return result
  }
}
