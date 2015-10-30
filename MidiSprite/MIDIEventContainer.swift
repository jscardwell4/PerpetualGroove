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

struct MIDIEventContainer: SequenceType {

  struct Index { let time: CABarBeatTime; let position: Int }

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
  func generate() -> IndexingGenerator<[MIDIEvent]> { return events.generate() }

  /** validate */
  mutating func validate() {
    guard let maxTime = _events.keys.maxElement() else { return }
    endOfTrack = maxTime
  }

  var trackName: String {
    get {
      switch trackNameEvent.data {
        case .SequenceTrackName(let name): return name
        default: return ""
      }
    }
    set {
      trackNameEvent = MetaEvent(.SequenceTrackName(name: newValue))
    }
  }

  private(set) var trackNameEvent: MetaEvent = MetaEvent(.SequenceTrackName(name: ""))

  private(set) var endOfTrackEvent: MetaEvent = MetaEvent(.EndOfTrack)

  var endOfTrack: CABarBeatTime {
    get { return endOfTrackEvent.time }
    set { endOfTrackEvent.time = newValue }
  }

  private var _events: [CABarBeatTime:EventBag] = [:]

  var events: [MIDIEvent] {
    var result: [MIDIEvent] = [trackNameEvent as MIDIEvent]
    for time in _events.keys.sort() { result.appendContentsOf(_events[time]!) }
    result.append(endOfTrackEvent as MIDIEvent)
    return result
  }

  var instrumentName: String? {
    get {
      guard let event = instrumentEvent, case .Text(let text) = event.data else { return nil }
      return text
    }
    set {
      guard instrumentName != newValue else { return }
      if let text = newValue { instrumentEvent = MetaEvent(.Text(text: text)) } else { instrumentEvent = nil }
    }
  }

  private var instrumentEventIndex: Index? {
    for (time, bag) in _events {
      guard let position = bag.indexOf({
        if let event = $0 as? MetaEvent, case .Text = event.data { return true }
        else { return false }
      }) else { continue }
      return Index(time: time, position: position)
    }
    return nil
  }

  private(set) var instrumentEvent: MetaEvent? {
    get {
      guard let index = instrumentEventIndex else { return nil }
      return _events[index.time]?[index.position] as? MetaEvent
    }
    set {
      switch (newValue as? MIDIEvent, instrumentEventIndex) {
        case let (event?, index?):
          _events[index.time]?[index.position] = event
        case let (event?, nil):
          var bag = _events[event.time] ?? EventBag(event.time)
          bag.append(event)
          _events[event.time] = bag
        case let (nil, index?):
          _events[index.time]?.events.removeAtIndex(index.position)
        default:
          break
      }
    }
  }

  private var programEventIndex: Index? {
    for (time, bag) in _events {
      guard let position = bag.indexOf({
        if let event = $0 as? ChannelEvent where event.status.type == .ProgramChange {
          return true
        } else { return false }
      })
        else { continue }
      return Index(time: time, position: position)
    }
    return nil
  }

  var program: (channel: Byte, program: Byte)? {
    get { guard let event = programEvent else { return nil }; return (event.status.channel, event.data1) }
    set {
      switch (program, newValue) {
        case let ((c1, p1)?, (c2, p2)?) where c1 == c2 && p1 == p2: return
        default: break
      }
      if let program = newValue { programEvent = ChannelEvent(.ProgramChange, program.channel, program.program) }
      else { programEvent = nil }
    }
  }

  private(set) var programEvent: ChannelEvent? {
    get {
      guard let index = programEventIndex else { return nil }
      return _events[index.time]?[index.position] as? ChannelEvent
    }
    set {
      switch (newValue as? MIDIEvent, programEventIndex) {
        case let (event?, index?):
          _events[index.time]?[index.position] = event
        case let (event?, nil):
          var bag = _events[event.time] ?? EventBag(event.time)
          bag.append(event)
          _events[event.time] = bag
        case let (nil, index?):
          _events[index.time]?.events.removeAtIndex(index.position)
        default:
          break
      }
    }
  }

  /**
  filterEvent:

  - parameter event: MIDIEvent

  - returns: Bool
  */
  private mutating func filterEvent(event: MIDIEvent) -> Bool {
    if let event = event as? MetaEvent, case .SequenceTrackName = event.data {
      trackNameEvent = event
      return true
    } else if let event = event as? MetaEvent, case .EndOfTrack = event.data {
      endOfTrackEvent = event
      return true
    } else {
      return false
    }
  }

  /**
  append:

  - parameter event: MIDIEvent
  */
  mutating func append(event: MIDIEvent) {
    guard !filterEvent(event) else { return }
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
    for event in events { if let event = event as? MetaEvent { result.append(event) } }
    return result
  }

  var channelEvents: [ChannelEvent] {
    var result: [ChannelEvent] = []
    for event in events { if let event = event as? ChannelEvent { result.append(event) } }
    return result
  }
  
  var nodeEvents: [MIDINodeEvent] {
    var result: [MIDINodeEvent] = []
    for event in events { if let event = event as? MIDINodeEvent { result .append(event) } }
    return result
  }

  var timeEvents: [MetaEvent] {
    var result: [MetaEvent] = []
    for event in events {
      switch (event as? MetaEvent)?.data {
      case .TimeSignature?, .Tempo?: result.append(event as! MetaEvent)
      default:                       break
      }
    }
    return result
  }

  var isEmpty: Bool { return _events.isEmpty }

  subscript(time: CABarBeatTime) -> [MIDIEvent]? { return _events[time]?.events }
}

private extension MIDIEventContainer {

  struct EventBag: Comparable, CollectionType, MutableCollectionType {
    let time: CABarBeatTime
    var events: [MIDIEvent] = []

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
    subscript(position: Int) -> MIDIEvent { get { return events[position] } set { events[position] = newValue } }

    /**
    Get or set the events in the specified range

    - parameter bounds: Range<Int>

    - returns: ArraySlice<MIDIEvent>
    */
    subscript(bounds: Range<Int>) -> ArraySlice<MIDIEvent> { get { return events[bounds] } set { events[bounds] = newValue } }
  }

}

private func ==(lhs: MIDIEventContainer.EventBag, rhs: MIDIEventContainer.EventBag) -> Bool { return lhs.time == rhs.time }

private func <(lhs: MIDIEventContainer.EventBag, rhs: MIDIEventContainer.EventBag) -> Bool { return lhs.time < rhs.time }

extension MIDIEventContainer: CustomStringConvertible {
  var description: String { return "\n".join(events.map({$0.description})) }
}

extension MIDIEventContainer: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

