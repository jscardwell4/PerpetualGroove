//
//  MIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/28/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

typealias MIDIEventContainer = OldMIDIEventContainer

struct AltMIDIEventContainer {

  fileprivate var events: OrderedDictionary<BarBeatTime, OrderedSet<MIDIEvent>> = [:]

  subscript(index: Index) -> MIDIEvent {
    get {
      //TODO: Implement the  function
      fatalError("\(#function) not yet implemented")
    }
    set {
      //TODO: Implement the  function
      fatalError("\(#function) not yet implemented")
    }
  }

  subscript(time: BarBeatTime) -> LazyCollection<AnyCollection<MIDIEvent>> {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  subscript(subRange: Range<Index>) -> SubSequence {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  init<Source:Swift.Sequence>(events: Source) where Source.Iterator.Element == MIDIEvent {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  mutating func append(_ event: MIDIEvent) {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  mutating func append<Source:Swift.Sequence>(contentsOf source: Source) where Source.Iterator.Element == MIDIEvent {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  var minTime: BarBeatTime? {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  var maxTime: BarBeatTime? {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  mutating func removeEvents(matching predicate: (MIDIEvent) -> Bool) {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  var metaEvents: AnyCollection<MetaEvent> {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  var channelEvents: AnyCollection<ChannelEvent> {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  var nodeEvents: AnyCollection<MIDINodeEvent> {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

  var timeEvents: AnyCollection<MetaEvent> {
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented")
  }

}


extension AltMIDIEventContainer {

  struct Index: Comparable {

    static func ==(lhs: Index, rhs: Index) -> Bool {
      //TODO: Implement the  function
      fatalError("\(#function) not yet implemented")
    }

    static func <(lhs: Index, rhs: Index) -> Bool {
      //TODO: Implement the  function
      fatalError("\(#function) not yet implemented")
    }

  }

}

extension AltMIDIEventContainer {

  struct SubSequence {

  }

}


/*struct AltMIDIEventContainer: RandomAccessCollection {

  typealias Bag = OrderedSet<MIDIEvent>

  fileprivate typealias Buffer = OrderedDictionary<BarBeatTime, Bag>

  fileprivate var buffer: Buffer

  init() { buffer = Buffer() }

  init<S:Swift.Sequence>(events sequence: S) where S.Iterator.Element == MIDIEvent {
    var buffer: Buffer = [:]
    for event in sequence {
      var bag = buffer[event.time]
      if bag == nil { bag = Bag(); buffer[event.time] = bag }
      bag!.append(event)
    }
    self.buffer = buffer
  }

  var minTime: BarBeatTime? { return buffer.first?.key }
  var maxTime: BarBeatTime? { return buffer.last?.key }

  var count: Int { return buffer.reduce(0) {$0 + $1.value.count} }

  private func count(forBagAt bagOffset: Int) -> Int {
    return buffer[bagOffset].value.count
  }

  typealias _Element = MIDIEvent

  typealias Iterator = AnyIterator<MIDIEvent>
  func makeIterator() -> AnyIterator<MIDIEvent> {
    return AnyIterator(FlattenCollection(buffer.values).makeIterator())
  }

  var startIndex: Index { return Index(0, 0) }

  var endIndex: Index {
    guard buffer.count > 0 else { return startIndex }

    let bag = buffer.index(before: buffer.endIndex).value
    let position = buffer[bag].value.endIndex
    return Index(bag, position)
  }

  typealias Indices = Range<Index>
  var indices: Range<Index> { return startIndex ..< endIndex }

  mutating func append(_ event: MIDIEvent) {
    var bag = buffer[event.time]
    if bag == nil { bag = Bag(); buffer[event.time] = bag }
    bag!.append(event)
  }

  mutating func appendEvents<S: Swift.Sequence>(_ events: S) where S.Iterator.Element == MIDIEvent {
    events.forEach { append($0) }
  }

  mutating func removeEventsMatching(_ predicate: (MIDIEvent) -> Bool) {
    var result: Buffer = [:]
    var countDidChange = false
    for (time, bag) in buffer {
      var resultBag = Bag()
      for event in bag where !predicate(event) { resultBag.append(event) }
      if resultBag.count > 0 { result[time] = resultBag }
      if !countDidChange && resultBag.count < bag.count { countDidChange = true }
    }

    guard countDidChange else { return }
    buffer = result
  }

  subscript(time: BarBeatTime) -> OrderedSet<MIDIEvent>? { return buffer[time] }

  subscript(index: Index) -> MIDIEvent {
    get {
      return buffer[index.bagOffset].value[index.positionOffset]
    }
    set {
      var (time, bag) = buffer[index.bagOffset]
      bag[index.positionOffset] = newValue
      buffer[index.bagOffset] = (key: time, value: bag)
    }
  }

  subscript(subRange: Range<Index>) -> Array<MIDIEvent> {
    var result = Array(buffer[subRange.lowerBound.bagOffset].value[subRange.lowerBound.positionOffset..<count(forBagAt: subRange.lowerBound.bagOffset)])
    for bag in buffer[subRange.lowerBound.bagOffset + 1 ..< subRange.upperBound.bagOffset - 1].map({$0.value}) {
      result.append(contentsOf: bag)
    }
    result.append(contentsOf: buffer[subRange.upperBound.bagOffset].value[0..<subRange.upperBound.positionOffset])
    return result
  }

  var metaEvents: LazyMapCollection<LazyFilterCollection<AltMIDIEventContainer>, MetaEvent> {
    return lazy.filter({if case .meta = $0 { return true } else { return false }})
               .map({$0.event as! MetaEvent})
  }

  var channelEvents: LazyMapCollection<LazyFilterCollection<AltMIDIEventContainer>, ChannelEvent> {
    return lazy.filter({if case .channel = $0 { return true } else { return false }})
               .map({$0.event as! ChannelEvent})
  }

  var nodeEvents: LazyMapCollection<LazyFilterCollection<AltMIDIEventContainer>, MIDINodeEvent> {
    return lazy.filter({if case .node = $0 { return true } else { return false }})
               .map({$0.event as! MIDINodeEvent})
  }

  var timeEvents: LazyMapCollection<LazyFilterCollection<AltMIDIEventContainer>, MetaEvent> {
    return lazy.filter({
                        if case .meta(let event) = $0 {
                          switch event.data {
                            case .timeSignature, .tempo: return true
                            default: return false
                          }
                        } else { return false }})
               .map({$0.event as! MetaEvent})
  }

  func index(after i: Index) -> Index {
    precondition(i < endIndex && i >= startIndex, "`i` must be within `startIndex..<endIndex`")

    switch (i.bagOffset, i.positionOffset) {

    case let (bagOffset, positionOffset)
      where count(forBagAt: bagOffset) == positionOffset + 1 && buffer.count == bagOffset + 1:
      return endIndex

    case let (bagOffset, positionOffset)
      where count(forBagAt: bagOffset) == positionOffset + 1 && buffer.count > bagOffset + 1:
      return Index(bagOffset + 1, 0)

    case let (bagOffset, positionOffset)
      where count(forBagAt: bagOffset) > positionOffset + 1:
      return Index(bagOffset, positionOffset + 1)

    default:
      unreachable()

    }

  }

  func index(before i: Index) -> Index {
    precondition(i <= endIndex && i > startIndex, "`i` must be within `startIndex+1...endIndex`")

    switch (i.bagOffset, i.positionOffset) {

      case let (bagOffset, 0):
        return Index(bagOffset, count(forBagAt: bagOffset - 1) - 1)

      case let (bagOffset, positionOffset):
        return Index(bagOffset, positionOffset - 1)

    }

  }

  func distance(from start: Index, to end: Index) -> Int {

    switch (start.bagOffset, end.bagOffset) {

    case let (firstBag, lastBag) where firstBag == lastBag:
      return end.positionOffset - start.positionOffset

    case let (firstBag, lastBag) where lastBag == firstBag + 1:
      return buffer[firstBag].value.count - start.positionOffset + end.positionOffset

    case let (firstBag, lastBag) where firstBag < lastBag:
      let interveningEventCount = buffer[firstBag + 1 ..< lastBag - 1].reduce(0) { $0 + $1.value.count }
      return buffer[firstBag].value.count - start.positionOffset + interveningEventCount + end.positionOffset

    case let (firstBag, lastBag) where firstBag == lastBag + 1:
      return -(start.positionOffset + buffer[lastBag].value.count - end.positionOffset)

    case let (firstBag, lastBag) /*where firstBag > lastBag*/:
      let interveningEventCount = buffer[lastBag + 1 ..< firstBag - 1].reduce(0) { $0 + $1.value.count }
      return -(start.positionOffset + interveningEventCount + buffer[lastBag].value.count - end.positionOffset)
    }

  }

}
*/

/*extension AltMIDIEventContainer {
  struct Index: Comparable {
    let bagOffset: Int
    let positionOffset: Int

    init(_ bagOffset: Int, _ positionOffset: Int) { self.bagOffset = bagOffset; self.positionOffset = positionOffset }

    static func ==(lhs: Index, rhs: Index) -> Bool {
      return lhs.bagOffset == rhs.bagOffset && lhs.positionOffset == rhs.positionOffset
    }

    static func <(lhs: Index, rhs: Index) -> Bool {
      guard lhs.bagOffset == rhs.bagOffset else { return lhs.bagOffset < rhs.bagOffset }
      return lhs.positionOffset < rhs.positionOffset
    }

  }

}*/

/*extension AltMIDIEventContainer: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: MIDIEvent...) { self.init(events: elements) }
}*/

/*extension AltMIDIEventContainer: CustomStringConvertible {
  var description: String { return map({$0.description}).joined(separator: "\n") }
}*/


