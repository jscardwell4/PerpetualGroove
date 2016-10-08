//
//  OldMIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct OldMIDIEventContainer: Collection {

  fileprivate(set) var startIndex: Index = .endIndex

  var endIndex: Index { return .endIndex }

  var isEmpty: Bool {
    return events.isEmpty || events.values.flatMap({$0.events.isEmpty ? $0 : nil}).count > 0
  }

  subscript(index: Index) -> AnyMIDIEvent {
    get {
      guard let event = events[index.time]?[index.position] else { fatalError("invalid index \(index)") }
      return event
    }
    set {
      events[index.time]?[index.position] = newValue
    }
  }

  subscript(time: BarBeatTime) -> OrderedSet<AnyMIDIEvent>? {
    return events[time]?.events
  }

  subscript(bounds: Range<Index>) -> OldMIDIEventContainer {
    var events: [AnyMIDIEvent] = []
    var index = bounds.lowerBound
    while index != bounds.upperBound {
      events.append(self[index])
      index = index.successor()
    }
    return OldMIDIEventContainer(events: events)
  }

  subscript(bounds: Range<BarBeatTime>) -> OldMIDIEventContainer {
    var result: [AnyMIDIEvent] = []
    for (time, bag) in events where bounds.contains(time) {
      result.append(contentsOf: bag.events)
    }

    return OldMIDIEventContainer(events: result)
  }

  var count: Int { return events.reduce(0) { $0 + $1.1.count } }

  fileprivate(set) var eventTimes: [BarBeatTime] = []

//  fileprivate var _indices: Range<Index> = .endIndex ..< .endIndex

  fileprivate mutating func rebuildIndices() {
    var currentIndex: Index = .endIndex
    var indices: [Index] = [currentIndex]
    for time in eventTimes.reversed() {
      let bagIndices = Array(events[time]!.indices).reversed()
      for bagIndex in bagIndices {
        let index: Index = .valueIndex(time, bagIndex, nil, currentIndex)
        indices.append(index)
        currentIndex = index
      }
    }
    startIndex = currentIndex
  }

  typealias Indices = CountableRange<Index>
  var indices: CountableRange<Index> { return startIndex ..< endIndex }

  init() {}

  init(events: [AnyMIDIEvent]) { self.init(); for event in events { append(event) } }

  typealias Iterator = AnyIterator<AnyMIDIEvent>
  func makeIterator() -> AnyIterator<AnyMIDIEvent> {
    var index = startIndex
    let container = self
    return AnyIterator {
      switch index {
      case .endIndex: return nil
      case .valueIndex(_, _, _, let successor):
        let event = container[index]
        index = successor
        return event
      }
    }
  }

  var minTime: BarBeatTime { return events.keys.min() ?? BarBeatTime.zero }
  var maxTime: BarBeatTime { return events.keys.max() ?? Sequencer.time.barBeatTime }

  fileprivate var events: [BarBeatTime:EventBag] = [:] {
    didSet { eventTimes = events.keys.sorted(); rebuildIndices() }
  }

  mutating func append(_ event: AnyMIDIEvent) {
    var bag = events[event.time] ?? EventBag(event.time)
    bag.append(event)
    events[event.time] = bag
  }

  /**
   Implemented because default map wasn't working correctly.

   - parameter transform: (AnyMIDIEvent) throws -> T
  */
  func map<T>(_ transform: @escaping (AnyMIDIEvent) throws -> T) rethrows -> [T] {
    var result: [T] = []
    for event in self {
      result.append(try transform(event))
    }
    return result
  }

  mutating func appendEvents<S: Swift.Sequence>(_ events: S) where S.Iterator.Element == AnyMIDIEvent {
    for event in events { append(event) }
  }

  var metaEvents: [MetaEvent] {
    var result: [MetaEvent] = []
    for event in self { if case .meta(let event) = event { result.append(event) } }
    return result
  }

  var channelEvents: [ChannelEvent] {
    var result: [ChannelEvent] = []
    for event in self { if case .channel(let event) = event { result.append(event) } }
    return result
  }
  
  var nodeEvents: [MIDINodeEvent] {
    var result: [MIDINodeEvent] = []
    for event in self { if case .node(let event) = event { result .append(event) } }
    return result
  }

  var timeEvents: [MetaEvent] {
    var result: [MetaEvent] = []
    for event in metaEvents {
      switch event.data {
        case .timeSignature, .tempo: result.append(event)
        default: break
      }
    }
    return result
  }

  func eventsForTime(_ time: BarBeatTime) -> OrderedSet<AnyMIDIEvent>? { return events[time]?.events }

  mutating func removeEventsMatching(_ predicate: (AnyMIDIEvent) -> Bool) {
    var result: [BarBeatTime:EventBag] = [:]
    for (time, bag) in events {
      var resultBag = EventBag(time)
      for event in bag where !predicate(event) { resultBag.append(event) }
      if resultBag.count > 0 { result[time] = resultBag }
    }
    events = result
  }

  func index(after i: OldMIDIEventContainer.Index) -> OldMIDIEventContainer.Index {
    return i.successor()
  }
}

private extension OldMIDIEventContainer {

  struct EventBag: Comparable, MutableCollection {
    let time: BarBeatTime
    var events: OrderedSet<AnyMIDIEvent> = []

    var startIndex: Int { return events.startIndex }
    var endIndex: Int { return events.endIndex }

    var indices: OrderedSet<AnyMIDIEvent>.Indices { return events.indices }

    /**
    Create a new bag for the specified time.

    - parameter time: BarBeatTime
    */
    init(_ time: BarBeatTime) { self.time = time }

    /**
    Create a generator over the bag's events

    - returns: IndexingGenerator<[AnyMIDIEvent]>
    */
    func makeIterator() -> AnyIterator<AnyMIDIEvent> { return AnyIterator(events.makeIterator()) }

    /**
    Append a new event to the bag

    - parameter event: AnyMIDIEvent
    */
    mutating func append(_ event: AnyMIDIEvent) { events.append(event) }

    /**
    Get or set the event at the specified position

    - parameter index: Int

    - returns: AnyMIDIEvent
    */
    subscript(index: Int) -> AnyMIDIEvent {
      get { return events[index] }
      set { events[index] = newValue }
    }

    /**
    Get or set the events in the specified range

    - parameter bounds: Range<Int>

    - returns: ArraySlice<AnyMIDIEvent>
    */
    subscript(bounds: Range<Int>) -> OrderedSetSlice<AnyMIDIEvent> {
      get { return events[bounds] }
      set { events[bounds] = newValue }
    }

    static func ==(lhs: EventBag, rhs: EventBag) -> Bool {
      return lhs.time == rhs.time && lhs.events.elementsEqual(rhs.events)
    }

    static func <(lhs: EventBag, rhs: EventBag) -> Bool {
      return lhs.time < rhs.time
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

extension OldMIDIEventContainer: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: AnyMIDIEvent...) {
    self.init(events: elements)
  }
}

extension OldMIDIEventContainer {
  enum Index: Strideable {

    indirect case valueIndex (BarBeatTime, Int, Index?, Index)
    case endIndex

    func successor() -> Index {
      switch self {
        case .valueIndex(_, _, _, let index): return index
        case .endIndex: return .endIndex
      }
    }

    func predecessor() -> Index? {
      if case .valueIndex(_, _, let index?, _) = self { return index }
      else { return nil }
    }

    var time: BarBeatTime {
      switch self {
        case .valueIndex(let time, _, _, _): return time
        case .endIndex: return .null
      }
    }

    var position: Int {
      switch self {
        case .valueIndex(_, let position, _, _): return position
        case .endIndex: return -1
      }
    }

    static func ==(lhs: Index, rhs: Index) -> Bool {
      return lhs.time == rhs.time && lhs.position == rhs.position
    }
    
    static func <(lhs: Index, rhs: Index) -> Bool {
      return lhs.time < rhs.time || lhs.time == rhs.time && lhs.position < rhs.position
    }

    func advanced(by n: Int) -> Index {
      var n = n
      var i = self

      if n < 0 {
        while n < 0, let iʹ = i.predecessor() { i = iʹ; n += 1 }
        return i
      } else {
        while i != .endIndex && n > 0 { i = i.successor(); n -= 1 }
        return i
      }
    }

    func distance(to other: Index) -> Int {
      var result = 0
      if self < other {
        var i = self
        while i != other { i = i.successor(); result += 1 }
      } else {
        var i = other
        while i != self { i = other.successor(); result -= 1 }
      }
      return result
    }

  }

}

extension OldMIDIEventContainer: CustomStringConvertible {
  var description: String { return "\n".join(map({$0.description})) }
}

