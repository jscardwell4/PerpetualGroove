//
//  OldMIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct OldMIDIEventContainer: Collection, Indexable, MutableIndexable {

  fileprivate(set) var startIndex: Index = .endIndex

  var endIndex: Index { return .endIndex }

  var isEmpty: Bool {
    return events.isEmpty || events.values.flatMap({$0.events.isEmpty ? $0 : nil}).count > 0
  }

  subscript(index: Index) -> MIDIEvent {
    get {
      guard let event = events[index.time]?[index.position] else { fatalError("invalid index \(index)") }
      return event
    }
    set {
      events[index.time]?[index.position] = newValue
    }
  }

  subscript(bounds: Range<Index>) -> OldMIDIEventContainer {
    return OldMIDIEventContainer(events: bounds.map({self[$0]}))
  }

  subscript(bounds: Range<BarBeatTime>) -> OldMIDIEventContainer {
    var result: [MIDIEvent] = []
    for (time, bag) in events where bounds.contains(time) {
      result.append(contentsOf: bag.events)
    }

    return OldMIDIEventContainer(events: result)
  }

  var count: Int { return events.reduce(0) { $0 + $1.1.count } }

  fileprivate(set) var eventTimes: [BarBeatTime] = []

  fileprivate var _indices: Range<Index> = .endIndex ..< .endIndex

  fileprivate mutating func rebuildIndices() {
    var currentIndex: Index = .endIndex
    var indices: [Index] = [currentIndex]
    for time in eventTimes.reversed() {
      let bagIndices = Array(events[time]!.indices).reversed()
      for bagIndex in bagIndices {
        let index: Index = .valueIndex(time, bagIndex, currentIndex)
        indices.append(index)
        currentIndex = index
      }
    }
    startIndex = currentIndex
  }

  /** init */
  init() {}

  /**
  initWithEvents:

  - parameter events: MIDIEvent
  */
  init(events: [MIDIEvent]) { self.init(); for event in events { append(event) } }

  /**
  generate

  - returns: Generator
  */
  func makeIterator() -> AnyIterator<MIDIEvent> {
    var index = startIndex
    let container = self
    return AnyIterator {
      switch index {
      case .endIndex: return nil
      case .valueIndex(_, _, let successor):
        let event = container[index]
        index = successor
        return event
      }
    }
  }

  var minTime: BarBeatTime { return events.keys.min() ?? .start1              }
  var maxTime: BarBeatTime { return events.keys.max() ?? Sequencer.time.barBeatTime }

  fileprivate var events: [BarBeatTime:EventBag] = [:] {
    didSet { eventTimes = events.keys.sorted(); rebuildIndices() }
  }

  /**
  append:

  - parameter event: MIDIEvent
  */
  mutating func append(_ event: MIDIEvent) {
//    switch event {
//      case .Meta(let metaEvent):
//        if case .SequenceTrackName = metaEvent.data { return }
//        else if case .EndOfTrack = metaEvent.data { return }
//      default: break
//    }

    var bag = events[event.time] ?? EventBag(event.time)
    bag.append(event)
    events[event.time] = bag
  }

  /**
   Implemented because default map wasn't working correctly.

   - parameter transform: (MIDIEvent) throws -> T
  */
  func map<T>(_ transform: @escaping (MIDIEvent) throws -> T) rethrows -> [T] {
    var result: [T] = []
    for event in self {
      result.append(try transform(event))
    }
    return result
  }

  /**
  appendEvents:

  - parameter events: S
  */
  mutating func appendEvents<S: Swift.Sequence>(_ events: S) where S.Iterator.Element == MIDIEvent {
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
        default:                      break
      }
    }
    return result
  }

  /**
   eventsForTime:

   - parameter time: BarBeatTime

    - returns: [MIDIEvent]?
  */
  func eventsForTime(_ time: BarBeatTime) -> OrderedSet<MIDIEvent>? { return events[time]?.events }

  /**
   removeEventsMatching:

   - parameter predicate: (MIDIEvent) -> Bool
  */
  mutating func removeEventsMatching(_ predicate: (MIDIEvent) -> Bool) {
    var result: [BarBeatTime:EventBag] = [:]
    for (time, bag) in events {
      var resultBag = EventBag(time)
      for event in bag where !predicate(event) { resultBag.append(event) }
      if resultBag.count > 0 { result[time] = resultBag }
    }
    events = result
  }
}

private extension OldMIDIEventContainer {

  struct EventBag: Comparable, Collection, MutableCollection {
    let time: BarBeatTime
    var events: OrderedSet<MIDIEvent> = []

    var startIndex: Int { return events.startIndex }
    var endIndex: Int { return events.endIndex }

    /**
    Create a new bag for the specified time.

    - parameter time: BarBeatTime
    */
    init(_ time: BarBeatTime) { self.time = time }

    /**
    Create a generator over the bag's events

    - returns: IndexingGenerator<[MIDIEvent]>
    */
    func makeIterator() -> AnyIterator<MIDIEvent> { return AnyIterator(events.makeIterator()) }

    /**
    Append a new event to the bag

    - parameter event: MIDIEvent
    */
    mutating func append(_ event: MIDIEvent) { events.append(event) }

    /**
    Get or set the event at the specified position

    - parameter position: Int

    - returns: MIDIEvent
    */
    subscript(position: Int) -> MIDIEvent {
      get { return events[position] }
      set { events[position] = newValue }
    }

    /**
    Get or set the events in the specified range

    - parameter bounds: Range<Int>

    - returns: ArraySlice<MIDIEvent>
    */
    subscript(bounds: Range<Int>) -> OrderedSetSlice<MIDIEvent> {
      get { return events[bounds] }
      set { events[bounds] = newValue }
    }
  }

}

extension OldMIDIEventContainer: ExpressibleByArrayLiteral {
  init(arrayLiteral elements: MIDIEvent...) {
    self.init(events: elements)
  }
}

extension OldMIDIEventContainer {
  enum Index: Comparable {
    indirect case valueIndex (BarBeatTime, Int, Index)
    case endIndex

    func successor() -> Index {
      switch self {
        case .valueIndex(_, _, let index): return index
        case .endIndex: return .endIndex
      }
    }

    var time: BarBeatTime {
      switch self {
        case .valueIndex(let time, _, _): return time
        case .endIndex: return .null
      }
    }

    var position: Int {
      switch self {
        case .valueIndex(_, let position, _): return position
        case .endIndex: return -1
      }
    }

  }

}

func ==(lhs: OldMIDIEventContainer.Index, rhs: OldMIDIEventContainer.Index) -> Bool {
  return lhs.time == rhs.time && lhs.position == rhs.position
}

private func ==(lhs: OldMIDIEventContainer.EventBag, rhs: OldMIDIEventContainer.EventBag) -> Bool {
  return lhs.time == rhs.time
}

private func <(lhs: OldMIDIEventContainer.EventBag, rhs: OldMIDIEventContainer.EventBag) -> Bool {
  return lhs.time < rhs.time
}

extension OldMIDIEventContainer: CustomStringConvertible {
  var description: String { return "\n".join(map({$0.description})) }
}

extension OldMIDIEventContainer: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

