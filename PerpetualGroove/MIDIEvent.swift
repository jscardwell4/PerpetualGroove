//
//  MIDIEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/**  Protocol for types that produce data for a track event in a track chunk */
protocol MIDIEventType: CustomStringConvertible, CustomDebugStringConvertible {
  var time: BarBeatTime { get set }
  var delta: VariableLengthQuantity? { get set }
  var bytes: [Byte] { get }
}

extension MIDIEventType {
  var hashValue: Int {
    let bytesHash = bytes.segment(8).map({UInt64($0)}).reduce(UInt64(0), { $0 ^ $1 }).hashValue
    let deltaHash = _mixInt(delta?.intValue ?? 0)
    let timeHash = time.totalBeats.hashValue
    return bytesHash ^ deltaHash ^ timeHash
  }
}

extension MIDIEventType {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

protocol MIDIEventDispatch: class, Loggable {
  func addEvent(_ event: MIDIEvent)
  func addEvents<S:Swift.Sequence>(_ events: S) where S.Iterator.Element == MIDIEvent
  func eventsForTime(_ time: BarBeatTime) -> OrderedSet<MIDIEvent>?
  func filterEvents(_ includeElement: (MIDIEvent) -> Bool) -> [MIDIEvent]
  func dispatchEventsForTime(_ time: BarBeatTime)
  func dispatchEvent(_ event: MIDIEvent)
  func registrationTimesForAddedEvents<S:Swift.Sequence>(_ events: S) -> [BarBeatTime] where S.Iterator.Element == MIDIEvent
  var events: MIDIEventContainer { get set }
  var metaEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MetaEvent> { get }
  var channelEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, ChannelEvent> { get }
  var nodeEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MIDINodeEvent> { get }
  var timeEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MetaEvent> { get }
  var eventQueue: DispatchQueue { get }
}

extension MIDIEventDispatch {
  func addEvent(_ event: MIDIEvent) { addEvents([event]) }
  func addEvents<S:Swift.Sequence>(_ events: S) where S.Iterator.Element == MIDIEvent {
    self.events.appendEvents(events)
    Sequencer.time.registerCallback(weakMethod(self, type(of: self).dispatchEventsForTime),
      forTimes: registrationTimesForAddedEvents(events),
      forObject: self)
  }
  func eventsForTime(_ time: BarBeatTime) -> OrderedSet<MIDIEvent>? { return events[time] }
  func filterEvents(_ includeElement: (MIDIEvent) -> Bool) -> [MIDIEvent] { return events.filter(includeElement) }
  func dispatchEventsForTime(_ time: BarBeatTime) { eventsForTime(time)?.forEach(dispatchEvent) }
  var metaEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MetaEvent> { return events.metaEvents }
  var channelEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, ChannelEvent> { return events.channelEvents }
  var nodeEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MIDINodeEvent> { return events.nodeEvents }
  var timeEvents: LazyMapCollection<LazyFilterCollection<MIDIEventContainer>, MetaEvent> { return events.timeEvents }
}

enum MIDIEvent: MIDIEventType, Hashable {
  case meta (MetaEvent)
  case channel (ChannelEvent)
  case node (MIDINodeEvent)

  var event: MIDIEventType {
    switch self {
      case .meta(let event): return event
      case .channel(let event): return event
      case .node(let event): return event
    }
  }

  var time: BarBeatTime {
    get {
      return event.time
    }
    set {
      switch self {
        case .meta(var event):    event.time = newValue; self = .meta(event)
        case .channel(var event): event.time = newValue; self = .channel(event)
        case .node(var event):    event.time = newValue; self = .node(event)
      }
    }
  }

  var delta: VariableLengthQuantity? {
    get {
      return event.delta
    }
    set {
      switch self {
        case .meta(var event):    event.delta = newValue; self = .meta(event)
        case .channel(var event): event.delta = newValue; self = .channel(event)
        case .node(var event):    event.delta = newValue; self = .node(event)
      }
    }
  }

  var bytes: [Byte] { return event.bytes }

  var description: String { return event.description }

  var debugDescription: String { return event.debugDescription }
}

extension MIDIEvent: Equatable {}

func ==(lhs: MIDIEvent, rhs: MIDIEvent) -> Bool {
  switch (lhs, rhs) {
    case let (.meta(meta1), .meta(meta2)) where meta1 == meta2:                   return true
    case let (.channel(channel1), .channel(channel2)) where channel1 == channel2: return true
    case let (.node(node1), .node(node2)) where node1 == node2:                   return true
    default:                                                                      return false
  }
}
