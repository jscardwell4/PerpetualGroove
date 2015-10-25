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

struct MIDIEventContainer: CollectionType, MutableIndexable {

  typealias Element = MIDIEvent
  typealias SubSequence = ArraySlice<Element>
  typealias Generator = AnyGenerator<Element>

  /** init */
  init() {}

  /**
  initWithEvents:

  - parameter events: Element
  */
  init(events: [Element]) { self.init(); for event in events { append(event) } }

  /**
  generate

  - returns: Generator
  */
  func generate() -> Generator { return anyGenerator(_events.generate()) }

  let startIndex = 0
  var endIndex: Int { return _events.endIndex + 2 }

  var isEmpty: Bool { return false }

  /**
  subscript:

  - parameter idx: Int

  - returns: MIDIEvent
  */
  subscript(idx: Int) -> MIDIEvent {
    get {
      switch idx {
        case 0:                                         return trackNameEvent
        case (startIndex + 1 ..< _events.endIndex + 1): return _events[idx - 1]
        case _events.endIndex + 1:                      return endOfTrackEvent
        default:                                        fatalError("out of bounds: '\(idx)'")
      }
    }
    set {
      if !filterEvent(newValue) { _events[idx] = newValue }
    }
  }

  /**
  subscript:

  - parameter range: Range<Int>

  - returns: SubSequence
  */
  subscript(range: Range<Int>) -> SubSequence { return events[range] }

  /** validate */
  mutating func validate() { guard let event = _events.last else { return }; endOfTrack = event.time }

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

  private var instrumentEventIndex: Int? {
    return _events.indexOf {
      if let event = $0 as? MetaEvent, case .Text = event.data { return true }
      else { return false }
    }
  }

  private(set) var instrumentEvent: MetaEvent? {
    get {
      guard let idx = instrumentEventIndex else { return nil }
      return (_events[idx] as! MetaEvent)
    }
    set {
      switch (newValue as? MIDIEvent, instrumentEventIndex) {
        case let (event?, idx?): _events[idx] = event
        case let (event?, nil):  _events.insert(event, atIndex: 0)
        case let (nil, idx?):    _events.removeAtIndex(idx)
        default:                 break
      }
    }
  }

  private var programEventIndex: Int? {
    return _events.indexOf {
      if let event = $0 as? ChannelEvent where event.status.type == .ProgramChange { return true }
      else { return false }
    }
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
      guard let idx = programEventIndex else { return nil }
      return (_events[idx] as! ChannelEvent)
    }
    set {
      switch (newValue as? MIDIEvent, programEventIndex) {
        case let (event?, idx?): _events[idx] = event
        case let (event?, nil):  _events.insert(event, atIndex: (instrumentEventIndex?.advancedBy(1) ?? 0))
        case let (nil, idx?):    _events.removeAtIndex(idx)
        default:                 break
      }
    }
  }

  var endOfTrack: CABarBeatTime {
    get { return endOfTrackEvent.time }
    set { endOfTrackEvent.time = newValue }
  }

  private(set) var _events: [MIDIEvent] = []

  var events: [MIDIEvent] { return [trackNameEvent as MIDIEvent] + _events + [endOfTrackEvent as MIDIEvent] }

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
  Inserts the given event at relative index `i` (that is the index ignoring the 'track name' and 'end of track' 
  events), unless the event gets filtered out into `trackNameEvent` or `endOfTrackEvent`

  - parameter event: MIDIEvent
  - parameter i: Int
  */
  mutating func insert(event: MIDIEvent, atIndex i: Int) {
    if !filterEvent(event) { _events.insert(event, atIndex: i) }
  }

  /**
  append:

  - parameter event: MIDIEvent
  */
  mutating func append(event: MIDIEvent) { if !filterEvent(event) { _events.append(event) } }

  var metaEvents: [MetaEvent] {
    var result: [MetaEvent] = []
    for event in _events { if let event = event as? MetaEvent { result.append(event) } }
    return result
  }

  var channelEvents: [ChannelEvent] {
    var result: [ChannelEvent] = []
    for event in _events { if let event = event as? ChannelEvent { result.append(event) } }
    return result
  }
  
  var nodeEvents: [MIDINodeEvent] {
    var result: [MIDINodeEvent] = []
    for event in _events { if let event = event as? MIDINodeEvent { result .append(event) } }
    return result
  }

  var count: Int { return _events.count + 2 }
}

extension MIDIEventContainer: CustomStringConvertible {
  var description: String { return "\n".join(events.map({$0.description})) }
}

extension MIDIEventContainer: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

