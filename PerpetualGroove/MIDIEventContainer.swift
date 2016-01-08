//
//  MIDIEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

struct MIDIEventContainer: SequenceType, Indexable, MutableIndexable {

  var startIndex: Index {
    guard let time = _events.keys.sort().first where _events[time]?.events.count > 0 else { return endIndex }
    return Index(container: self, time: time, position: 0)
  }

  var endIndex: Index { return Index(time: .Nil, position: -1) }

  var isEmpty: Bool { return _events.isEmpty || _events.values.flatMap({$0.events.isEmpty ? $0 : nil}).count > 0 }

  subscript(index: Index) -> MIDIEvent {
    get {
      guard let event = _events[index.time]?[index.position] else { fatalError("invalid index \(index)") }
      return event
    }
    set {
      _events[index.time]?[index.position] = newValue
    }
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
  func generate() -> IndexingGenerator<MIDIEventContainer> { return IndexingGenerator(self) }

  var minTime: CABarBeatTime { return _events.keys.minElement() ?? .start              }
  var maxTime: CABarBeatTime { return _events.keys.maxElement() ?? Sequencer.time.time }

  private var _events: [CABarBeatTime:EventBag] = [:]

  var events: [MIDIEvent] {
    var result: [MIDIEvent] = []
    for time in _events.keys.sort() { result.appendContentsOf(_events[time]!) }
    return result
  }

  /**
  append:

  - parameter event: MIDIEvent
  */
  mutating func append(event: MIDIEvent) {
    switch event {
      case .Meta(let metaEvent):
        if case .SequenceTrackName = metaEvent.data { return }
        else if case .EndOfTrack = metaEvent.data { return }
      default: break
    }

    var bag = _events[event.time] ?? EventBag(event.time)
    bag.append(event)
    _events[event.time] = bag
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
    for event in events { if case .Meta(let event) = event { result.append(event) } }
    return result
  }

  var channelEvents: [ChannelEvent] {
    var result: [ChannelEvent] = []
    for event in events { if case .Channel(let event) = event { result.append(event) } }
    return result
  }
  
  var nodeEvents: [MIDINodeEvent] {
    var result: [MIDINodeEvent] = []
    for event in events { if case .Node(let event) = event { result .append(event) } }
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

   - parameter time: CABarBeatTime

    - returns: [MIDIEvent]?
  */
  func eventsForTime(time: CABarBeatTime) -> OrderedSet<MIDIEvent>? { return _events[time]?.events }

  /**
   removeEventsMatching:

   - parameter predicate: (MIDIEvent) -> Bool
  */
  mutating func removeEventsMatching(predicate: (MIDIEvent) -> Bool) {
    var result: [CABarBeatTime:EventBag] = [:]
    for (time, bag) in _events {
      var resultBag = EventBag(time)
      for event in bag where !predicate(event) { resultBag.append(event) }
      if resultBag.count > 0 { result[time] = resultBag }
    }
    _events = result
  }
}

private extension MIDIEventContainer {

  struct EventBag: Comparable, CollectionType, MutableCollectionType {
    let time: CABarBeatTime
    var events: OrderedSet<MIDIEvent> = []

    var startIndex: Int { return events.startIndex }
    var endIndex: Int { return events.endIndex }

    /**
    Create a new bag for the specified time.

    - parameter time: CABarBeatTime
    */
    init(_ time: CABarBeatTime) { self.time = time }

    /**
    Create a generator over the bag's events

    - returns: IndexingGenerator<[MIDIEvent]>
    */
    func generate() -> IndexingGenerator<[MIDIEvent]> { return events.generate() }

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
    subscript(bounds: Range<Int>) -> OrderedSet<MIDIEvent> {
      get { return events[bounds] }
      set { events[bounds] = newValue }
    }
  }

}

extension MIDIEventContainer {
  struct Index: ForwardIndexType {
    let time: CABarBeatTime
    let position: Int
    private let successorTime: CABarBeatTime
    private let successorPosition: Int
    func successor() -> Index { return Index(time: successorTime, position: successorPosition) }
    private init(time: CABarBeatTime, position: Int) {
      self.time = time
      self.position = position
      successorTime = .Nil
      successorPosition = -1
    }
    private init(container: MIDIEventContainer, time: CABarBeatTime, var position: Int) {
      guard let bag = container._events[time] where bag.events.count > position else {
        self.time = .Nil
        self.position = -1
        successorTime = .Nil
        successorPosition = -1
        return
      }
      self.time = time
      self.position = position
      if ++position < bag.events.count { successorTime = time; successorPosition = position }
      else {
        let sortedTimes = container._events.keys.sort()
        guard var idx = sortedTimes.indexOf(time) where ++idx < sortedTimes.count else {
          successorTime = .Nil; successorPosition = -1; return
        }
        guard container._events[sortedTimes[idx]]!.events.count > 0 else {
          successorTime = .Nil; successorPosition = -1; return
        }
        successorTime = time
        successorPosition = 0
      }
    }
  }
}

func ==(lhs: MIDIEventContainer.Index, rhs: MIDIEventContainer.Index) -> Bool {
  return lhs.time == rhs.time && lhs.position == rhs.position
}

private func ==(lhs: MIDIEventContainer.EventBag, rhs: MIDIEventContainer.EventBag) -> Bool {
  return lhs.time == rhs.time
}

private func <(lhs: MIDIEventContainer.EventBag, rhs: MIDIEventContainer.EventBag) -> Bool {
  return lhs.time < rhs.time
}

extension MIDIEventContainer: CustomStringConvertible {
  var description: String { return "\n".join(events.map({$0.description})) }
}

extension MIDIEventContainer: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

