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

struct AltMIDIEventContainer: Collection {

  fileprivate var events: SortedDictionary<BarBeatTime, Bag> = [:]

  private mutating func bag(forTime time: BarBeatTime) -> Bag {
    guard let bag = existingBag(forTime: time) else {
      let bag = Bag(); events[time] = bag; return bag
    }
    return bag
  }

  private func existingBag(forTime time: BarBeatTime) -> Bag? { return events[time] }

  var startIndex: Index { return Index(timeOffset: 0, eventOffset: 0) }
  var endIndex: Index {
    switch events.count - 1 {
      case -1: return startIndex
      case let n: return Index(timeOffset: n, eventOffset: events[n].value.endIndex)
    }

  }

  @inline(__always) func distance(from start: Index, to end: Index) -> Int {
    switch (start, end) {
    case let (start, end) where start == end:
      return 0
    case (var start, let end) where start < end:
      var result = 0
      while start.timeOffset < end.timeOffset {
        result += events[start.timeOffset].value.count &- start.eventOffset
        start.timeOffset += 1
        start.eventOffset = 0
      }
      result += end.eventOffset &- start.eventOffset
      return result
    case (let start, var end) /*where start > end*/:
      var result = 0
      while end.timeOffset < start.timeOffset {
        result += events[end.timeOffset].value.count &- end.eventOffset
        end.timeOffset += 1
        end.eventOffset = 0
      }
      result += start.eventOffset &- end.eventOffset
      return -result
    }
  }

  @inline(__always) func index(after i: Index) -> Index {
    if events[i.timeOffset].value.endIndex > i.eventOffset &+ 1 {
      return Index(timeOffset: i.timeOffset, eventOffset: i.eventOffset &+ 1)
    } else if events.endIndex.value > i.timeOffset &+ 1 {
      return Index(timeOffset: i.timeOffset &+ 1, eventOffset: 0)
    } else {
      return endIndex
    }
  }

  @inline(__always) func index(before i: Index) -> Index {
    if i.eventOffset > 0 {
      return Index(timeOffset: i.timeOffset, eventOffset: i.eventOffset &- 1)
    } else if i.timeOffset > 0 {
      return Index(timeOffset: i.timeOffset &- 1, eventOffset: events[i.timeOffset &- 1].value.endIndex &- 1)
    } else {
      fatalError("i is the startIndex, there is no before")
    }
  }

  @inline(__always) func index(_ i: Index, offsetBy n: Int) -> Index {
    switch (i, n) {
      case (_, 0):
        return i
      case var (i, n) where n < 0:
        while n < 0 {
          switch i.eventOffset {
            case 0:
              i.timeOffset -= 1
              i.eventOffset = events[i.timeOffset].value.endIndex &- 1
              n += 1
            case let remainingInBag:
              i.eventOffset += Swift.max(n, -remainingInBag)
              n += remainingInBag
            }
        }
        return i
      case var (i, n) /*where n > 0*/:
        while n > 0 {
          switch i.eventOffset {
            case events[i.timeOffset].value.endIndex &- 1:
              i.timeOffset += 1
              i.eventOffset = 0
              n -= 1
            case let remainingInBag:
              i.eventOffset += Swift.min(n, remainingInBag)
              n -= remainingInBag
          }
        }
        return i
    }
  }

  @inline(__always) func index(_ i: Index, offsetBy n: Int, limitedBy limit: Index) -> Index? {

    func limitCheck(_ index: Index) -> Bool { return n < 0 ? index >= limit : index <= limit }

    switch (i, n) {
      case (_, 0):
        return i
      case var (i, n) where n < 0:
        while n < 0 {
          switch i.eventOffset {
            case 0:
              i.timeOffset -= 1
              i.eventOffset = events[i.timeOffset].value.endIndex &- 1
              guard limitCheck(i) else { return nil }
              n += 1
            case let remainingInBag:
              i.eventOffset += Swift.max(n, -remainingInBag)
              guard limitCheck(i) else { return nil }
              n += remainingInBag
            }
        }
        return i
      case var (i, n) /*where n > 0*/:
        while n > 0 {
          switch i.eventOffset {
            case events[i.timeOffset].value.endIndex &- 1:
              i.timeOffset += 1
              i.eventOffset = 0
              guard limitCheck(i) else { return nil }
              n -= 1
            case let remainingInBag:
              i.eventOffset += Swift.min(n, remainingInBag)
              guard limitCheck(i) else { return nil }
              n -= remainingInBag
          }
        }
        return i
    }
  }

  @inline(__always) func formIndex(after i: inout Index) {
    if events[i.timeOffset].value.endIndex > i.eventOffset &+ 1 {
      i.eventOffset += 1
    } else if events.endIndex.value > i.timeOffset &+ 1 {
      i.timeOffset += 1; i.eventOffset = 0
    } else {
      i = endIndex
    }
  }

  @inline(__always) func formIndex(before i: inout Index) {
    if i.eventOffset > 0 {
      i.eventOffset -= 1
    } else if i.timeOffset > 0 {
      i.timeOffset -= 1; i.eventOffset = events[i.timeOffset &- 1].value.endIndex &- 1
    } else {
      fatalError("i is the startIndex, there is no before")
    }
  }

  @inline(__always) func formIndex(_ i: inout Index, offsetBy n: Int) {
    switch n {
      case 0:
        break
      case var n where n < 0:
        while n < 0 {
          switch i.eventOffset {
            case 0:
              i.timeOffset -= 1
              i.eventOffset = events[i.timeOffset].value.endIndex &- 1
              n += 1
            case let remainingInBag:
              i.eventOffset += Swift.max(n, -remainingInBag)
              n += remainingInBag
            }
        }
      case var n /*where n > 0*/:
        while n > 0 {
          switch i.eventOffset {
            case events[i.timeOffset].value.endIndex &- 1:
              i.timeOffset += 1
              i.eventOffset = 0
              n -= 1
            case let remainingInBag:
              i.eventOffset += Swift.min(n, remainingInBag)
              n -= remainingInBag
          }
        }
    }
  }

  @inline(__always) func formIndex(_ i: inout Index, offsetBy n: Int, limitedBy limit: Index) -> Bool {
    func limitCheck(_ index: Index) -> Bool { return n < 0 ? index >= limit : index <= limit }

    switch n {
      case 0:
        return true
      case var n where n < 0:
        while n < 0 {
          switch i.eventOffset {
            case 0:
              i.timeOffset -= 1
              i.eventOffset = events[i.timeOffset].value.endIndex &- 1
              guard limitCheck(i) else { return false }
              n += 1
            case let remainingInBag:
              i.eventOffset += Swift.max(n, -remainingInBag)
              guard limitCheck(i) else { return false }
              n += remainingInBag
            }
        }
        return true
      case var n /*where n > 0*/:
        while n > 0 {
          switch i.eventOffset {
            case events[i.timeOffset].value.endIndex &- 1:
              i.timeOffset += 1
              i.eventOffset = 0
              guard limitCheck(i) else { return false }
              n -= 1
            case let remainingInBag:
              i.eventOffset += Swift.min(n, remainingInBag)
              guard limitCheck(i) else { return false }
              n -= remainingInBag
          }
        }
        return true
    }
  }


  subscript(index: Index) -> MIDIEvent {
    get { return events[index.timeOffset].value[index.eventOffset] }
    set { events[index.timeOffset].value[index.eventOffset] = newValue }
  }

  subscript(time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>? {
    guard let bag = existingBag(forTime: time) else { return nil }
    return AnyRandomAccessCollection<MIDIEvent>(bag.events)
  }

//  subscript(subRange: Range<Index>) -> SubSequence {
//    //TODO: Implement the  function
//    fatalError("\(#function) not yet implemented")
//  }

  init<Source:Swift.Sequence>(events: Source) where Source.Iterator.Element == MIDIEvent {
    append(contentsOf: events)
  }

  mutating func append(_ event: MIDIEvent) {
    bag(forTime: event.time).append(event)
  }

  mutating func append<Source:Swift.Sequence>(contentsOf source: Source) where Source.Iterator.Element == MIDIEvent {
    for event in source { append(event) }
  }

  var minTime: BarBeatTime? { return events.keys.first }

  var maxTime: BarBeatTime? { return events.keys.last }

  mutating func removeEvents(matching predicate: (MIDIEvent) -> Bool) {
    for (time, bag) in events {
      bag.removeEvents(matching: predicate)
      if bag.isEmpty { events[time] = nil }
    }
  }

  var metaEvents: AnyBidirectionalCollection<MetaEvent> {
    return AnyBidirectionalCollection(
      FlattenBidirectionalCollection(events.values).lazy
        .filter({if case .meta = $0 { return true } else { return false }})
        .map({$0.event as! MetaEvent})
    )
  }

  var channelEvents: AnyBidirectionalCollection<ChannelEvent> {
    return AnyBidirectionalCollection(
      FlattenBidirectionalCollection(events.values).lazy
        .filter({if case .channel = $0 { return true } else { return false }})
        .map({$0.event as! ChannelEvent})
    )
  }

  var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> {
    return AnyBidirectionalCollection(
      FlattenBidirectionalCollection(events.values).lazy
        .filter({if case .node = $0 { return true } else { return false }})
        .map({$0.event as! MIDINodeEvent})
    )
  }

  var timeEvents: AnyBidirectionalCollection<MetaEvent> {
    return AnyBidirectionalCollection(
      FlattenBidirectionalCollection(events.values).lazy
        .filter({
          if case .meta(let event) = $0 {
            switch event.data {
              case .timeSignature, .tempo: return true
              default: return false
            }
          } else { return false }
        })
        .map({$0.event as! MetaEvent})
    )
  }

}


extension AltMIDIEventContainer {

  struct Index: Comparable {

    fileprivate(set) var timeOffset: Int
    fileprivate(set) var eventOffset: Int

    static func ==(lhs: Index, rhs: Index) -> Bool {
      return lhs.timeOffset == rhs.timeOffset && lhs.eventOffset == rhs.eventOffset
    }

    static func <(lhs: Index, rhs: Index) -> Bool {
      return lhs.timeOffset < rhs.timeOffset || lhs.timeOffset == rhs.timeOffset && lhs.eventOffset < rhs.eventOffset
    }

  }

}

//extension AltMIDIEventContainer {
//
//  struct SubSequence {
//
//  }
//
//}

extension AltMIDIEventContainer {

  fileprivate class Bag: RandomAccessCollection {

    typealias Index = Int
    typealias Iterator = AnyIterator<MIDIEvent>
    typealias SubSequence = AnyRandomAccessCollection<MIDIEvent>

    typealias Indices = OrderedSet<MIDIEvent>.Indices

    private(set) var events: OrderedSet<MIDIEvent> = []

    subscript(index: Index) -> MIDIEvent {
      get { return events[index] }
      set { events[index] = newValue }
    }

    subscript(subRange: Range<Index>) -> SubSequence {
      return AnyRandomAccessCollection(events[subRange])
    }

    var startIndex: Int { return events.startIndex }
    var endIndex: Int { return events.endIndex }

    var indices: Indices { return events.indices }

    func makeIterator() -> AnyIterator<MIDIEvent> {
      return AnyIterator(events.makeIterator())
    }

    func append(_ event: MIDIEvent) {
      events.append(event)
    }

    func append<Source:Swift.Sequence>(contentsOf source: Source) where Source.Iterator.Element == MIDIEvent {
      events.append(contentsOf: source)
    }

    func removeEvents(matching predicate: (MIDIEvent) -> Bool) {
      for event in events where predicate(event) { events.remove(event) }
    }


    @inline(__always) func distance(from start: Int, to end: Int) -> Int { return end &- start }

    @inline(__always) func index(after i: Int) -> Int { return i &+ 1 }
    @inline(__always) func index(before i: Int) -> Int { return i &- 1 }
    @inline(__always) func index(_ i: Int, offsetBy n: Int) -> Int { return i &+ n }
    @inline(__always) func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
      switch (i &+ n, n < 0) {
      case (let iʹ, true) where iʹ >= limit, (let iʹ, false) where iʹ <= limit: return iʹ
      default: return nil
      }
    }
    @inline(__always) func formIndex(after i: inout Int) { i = i &+ 1 }
    @inline(__always) func formIndex(before i: inout Int) { i = i &- 1 }
    @inline(__always) func formIndex(_ i: inout Int, offsetBy n: Int) { i = i &+ n }
    @inline(__always) func formIndex(_ i: inout Int, offsetBy n: Int, limitedBy limit: Int) -> Bool {
      switch (i &+ n, n < 0) {
      case (let iʹ, true) where iʹ >= limit, (let iʹ, false) where iʹ <= limit: i = iʹ; return true
      default: return false
      }
    }

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


