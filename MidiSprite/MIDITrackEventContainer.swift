//
//  MIDITrackEventContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct MIDITrackEventContainer: CollectionType, MutableIndexable {

  typealias Element = MIDITrackEvent
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
  var endIndex: Int { return _events.endIndex + (trackNameEvent == nil ? 0 : 1) + (endOfTrackEvent == nil ? 0 : 1) }

  var isEmpty: Bool { return _events.isEmpty && trackNameEvent == nil && endOfTrackEvent == nil }

  /**
  subscript:

  - parameter idx: Int

  - returns: MIDITrackEvent
  */
  subscript(idx: Int) -> MIDITrackEvent {
    get {
      switch (trackNameEvent, endOfTrackEvent) {
        case (nil, _) where idx < _events.count:                               return _events[idx]
        case (nil, let event?) where idx == _events.count:                     return event
        case let (event?, _) where idx == 0:                                   return event
        case (.Some, _) where (startIndex + 1 ..< _events.endIndex + 1) ∋ idx: return _events[idx - 1]
        case (.Some, let event?) where idx == _events.endIndex + 1:            return event
        default:                                                               fatalError("out of bounds: '\(idx)'")
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

  var trackNameEvent: MetaEvent?
  var endOfTrackEvent: MetaEvent?

  private(set) var _events: [MIDITrackEvent] = []

  var events: [MIDITrackEvent] {
    var events = self._events
    if let trackNameEvent = trackNameEvent { events.insert(trackNameEvent, atIndex: 0) }
    if let endOfTrackEvent = endOfTrackEvent { events.append(endOfTrackEvent) }
    return events
  }

  /**
  filterEvent:

  - parameter event: MIDITrackEvent

  - returns: Bool
  */
  private mutating func filterEvent(event: MIDITrackEvent) -> Bool {
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

  - parameter event: MIDITrackEvent
  - parameter i: Int
  */
  mutating func insert(event: MIDITrackEvent, atIndex i: Int) {
    if !filterEvent(event) { _events.insert(event, atIndex: i) }
  }

  /**
  append:

  - parameter event: MIDITrackEvent
  */
  mutating func append(event: MIDITrackEvent) { if !filterEvent(event) { _events.append(event) } }

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

  var count: Int { return _events.count + (trackNameEvent == nil ? 0 : 1) + (endOfTrackEvent == nil ? 0 : 1) }
}