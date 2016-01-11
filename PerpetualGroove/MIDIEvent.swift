//
//  MIDIEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

/**  Protocol for types that produce data for a track event in a track chunk */
protocol MIDIEventType: CustomStringConvertible, CustomDebugStringConvertible {
  var time: CABarBeatTime { get set }
  var delta: VariableLengthQuantity? { get set }
  var bytes: [Byte] { get }
}

extension MIDIEventType {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

protocol MIDIEventDispatch: class, Loggable {
  func addEvent(event: MIDIEvent)
  func addEvents<S:SequenceType where S.Generator.Element == MIDIEvent>(events: S)
  func eventsForTime(time: CABarBeatTime) -> OrderedSet<MIDIEvent>?
  func filterEvents(includeElement: (MIDIEvent) -> Bool) -> [MIDIEvent]
  func dispatchEventsForTime(time: CABarBeatTime)
  func dispatchEvent(event: MIDIEvent)
  func registrationTimesForAddedEvents<S:SequenceType where S.Generator.Element == MIDIEvent>(events: S) -> [CABarBeatTime]
  var events: MIDIEventContainer { get set }
  var metaEvents: [MetaEvent] { get }
  var channelEvents: [ChannelEvent] { get }
  var nodeEvents: [MIDINodeEvent] { get }
  var eventQueue: NSOperationQueue { get }
}

extension MIDIEventDispatch {
  func addEvent(event: MIDIEvent) { addEvents([event]) }
  func addEvents<S:SequenceType where S.Generator.Element == MIDIEvent>(events: S) {
    self.events.appendEvents(events)
    Sequencer.time.registerCallback(weakMethod(self, self.dynamicType.dispatchEventsForTime),
      forTimes: registrationTimesForAddedEvents(events),
      forObject: self)
  }
  func eventsForTime(time: CABarBeatTime) -> OrderedSet<MIDIEvent>? { return events.eventsForTime(time) }
  func filterEvents(includeElement: (MIDIEvent) -> Bool) -> [MIDIEvent] { return events.filter(includeElement) }
  func dispatchEventsForTime(time: CABarBeatTime) { eventsForTime(time)?.forEach(dispatchEvent) }
  var metaEvents: [MetaEvent] { return events.metaEvents }
  var channelEvents: [ChannelEvent] { return events.channelEvents }
  var nodeEvents: [MIDINodeEvent] { return events.nodeEvents }
}

enum MIDIEvent: MIDIEventType {
  case Meta (MetaEvent)
  case Channel (ChannelEvent)
  case Node (MIDINodeEvent)

  var event: MIDIEventType {
    switch self {
      case .Meta(let event): return event
      case .Channel(let event): return event
      case .Node(let event): return event
    }
  }

  var time: CABarBeatTime {
    get {
      return event.time
    }
    set {
      switch self {
        case .Meta(var event):    event.time = newValue; self = .Meta(event)
        case .Channel(var event): event.time = newValue; self = .Channel(event)
        case .Node(var event):    event.time = newValue; self = .Node(event)
      }
    }
  }

  var delta: VariableLengthQuantity? {
    get {
      return event.delta
    }
    set {
      switch self {
        case .Meta(var event):    event.delta = newValue; self = .Meta(event)
        case .Channel(var event): event.delta = newValue; self = .Channel(event)
        case .Node(var event):    event.delta = newValue; self = .Node(event)
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
    case let (.Meta(meta1), .Meta(meta2)) where meta1 == meta2:                   return true
    case let (.Channel(channel1), .Channel(channel2)) where channel1 == channel2: return true
    case let (.Node(node1), .Node(node2)) where node1 == node2:                   return true
    default:                                                                      return false
  }
}
