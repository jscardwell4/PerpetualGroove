//
//  OldMIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct OldMIDIEventContainer: CollectionType, Indexable, MutableIndexable {

  private(set) var startIndex: Index = .EndIndex

  var endIndex: Index { return .EndIndex }

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
      result.appendContentsOf(bag.events)
    }

    return OldMIDIEventContainer(events: result)
  }

  var count: Int { return events.reduce(0) { $0 + $1.1.count } }

  private(set) var eventTimes: [BarBeatTime] = []

  private var _indices: Range<Index> = .EndIndex ..< .EndIndex

  private mutating func rebuildIndices() {
    var currentIndex: Index = .EndIndex
    var indices: [Index] = [currentIndex]
    for time in eventTimes.reverse() {
      let bagIndices = Array(events[time]!.indices).reverse()
      for bagIndex in bagIndices {
        let index: Index = .ValueIndex(time, bagIndex, currentIndex)
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
  func generate() -> AnyGenerator<MIDIEvent> {
    var index = startIndex
    let container = self
    return AnyGenerator {
      switch index {
      case .EndIndex: return nil
      case .ValueIndex(_, _, let successor):
        let event = container[index]
        index = successor
        return event
      }
    }
  }

  var minTime: BarBeatTime { return events.keys.minElement() ?? .start1              }
  var maxTime: BarBeatTime { return events.keys.maxElement() ?? Sequencer.time.barBeatTime }

  private var events: [BarBeatTime:EventBag] = [:] {
    didSet { eventTimes = events.keys.sort(); rebuildIndices() }
  }

  /**
  append:

  - parameter event: MIDIEvent
  */
  mutating func append(event: MIDIEvent) {
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
  func map<T>(@noescape transform: (MIDIEvent) throws -> T) rethrows -> [T] {
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
  mutating func appendEvents<S: SequenceType where S.Generator.Element == MIDIEvent>(events: S) {
    for event in events { append(event) }
  }

  var metaEvents: [MetaEvent] {
    var result: [MetaEvent] = []
    for event in self { if case .Meta(let event) = event { result.append(event) } }
    return result
  }

  var channelEvents: [ChannelEvent] {
    var result: [ChannelEvent] = []
    for event in self { if case .Channel(let event) = event { result.append(event) } }
    return result
  }
  
  var nodeEvents: [MIDINodeEvent] {
    var result: [MIDINodeEvent] = []
    for event in self { if case .Node(let event) = event { result .append(event) } }
    return result
  }

  var timeEvents: [MetaEvent] {
    var result: [MetaEvent] = []
    for event in metaEvents {
      switch event.data {
        case .TimeSignature, .Tempo: result.append(event)
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
  func eventsForTime(time: BarBeatTime) -> OrderedSet<MIDIEvent>? { return events[time]?.events }

  /**
   removeEventsMatching:

   - parameter predicate: (MIDIEvent) -> Bool
  */
  mutating func removeEventsMatching(predicate: (MIDIEvent) -> Bool) {
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

  struct EventBag: Comparable, CollectionType, MutableCollectionType {
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
    func generate() -> AnyGenerator<MIDIEvent> { return AnyGenerator(events.generate()) }

    /**
    Append a new event to the bag

    - parameter event: MIDIEvent
    */
    mutating func append(event: MIDIEvent) { events.append(event) }

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

extension OldMIDIEventContainer: ArrayLiteralConvertible {
  init(arrayLiteral elements: MIDIEvent...) {
    self.init(events: elements)
  }
}

extension OldMIDIEventContainer {
  enum Index: ForwardIndexType {
    indirect case ValueIndex (BarBeatTime, Int, Index)
    case EndIndex

    func successor() -> Index {
      switch self {
        case .ValueIndex(_, _, let index): return index
        case .EndIndex: return .EndIndex
      }
    }

    var time: BarBeatTime {
      switch self {
        case .ValueIndex(let time, _, _): return time
        case .EndIndex: return .null
      }
    }

    var position: Int {
      switch self {
        case .ValueIndex(_, let position, _): return position
        case .EndIndex: return -1
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
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

