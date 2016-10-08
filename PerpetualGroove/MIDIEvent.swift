//
//  MIDIEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

///  Protocol for types that produce data for a track event in a track chunk
protocol MIDIEvent: CustomStringConvertible {

  var time: BarBeatTime { get set }
  var delta: MIDIFile.VariableLengthQuantity? { get set }
  var bytes: [Byte] { get }

}

extension MIDIEvent {

  var hashValue: Int {
    let bytesHash = bytes.segment(8).map({UInt64($0)}).reduce(UInt64(0), { $0 ^ $1 }).hashValue
    let deltaHash = _mixInt(delta?.intValue ?? 0)
    let timeHash = time.totalBeats.hashValue
    return bytesHash ^ deltaHash ^ timeHash
  }

}

protocol MIDIEventDispatch: class, Loggable {

  func add(event: AnyMIDIEvent)
  func add<S:Swift.Sequence>(events: S) where S.Iterator.Element == AnyMIDIEvent

  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<AnyMIDIEvent>? 

  func filterEvents(_ isIncluded: (AnyMIDIEvent) -> Bool) -> [AnyMIDIEvent]

  func dispatchEvents(for time: BarBeatTime)
  func dispatch(event: AnyMIDIEvent)

  func registrationTimes<S:Swift.Sequence>(forAdding events: S) -> [BarBeatTime]
    where S.Iterator.Element == AnyMIDIEvent

  var eventContainer: MIDIEventContainer { get set }
  var metaEvents: AnyBidirectionalCollection<MetaEvent> { get }
  var channelEvents: AnyBidirectionalCollection<ChannelEvent> { get }
  var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> { get }
  var timeEvents: AnyBidirectionalCollection<MetaEvent> { get }

  var eventQueue: DispatchQueue { get }

}

extension MIDIEventDispatch {

  func add(event: AnyMIDIEvent) { add(events: [event]) }

  func add<S:Swift.Sequence>(events: S) where S.Iterator.Element == AnyMIDIEvent {
    eventContainer.append(contentsOf: events)
    Sequencer.time.register(callback: weakMethod(self, type(of: self).dispatchEvents),
                            times: registrationTimes(forAdding: events),
                            object: self)
  }

  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<AnyMIDIEvent>?  { return eventContainer[time] }

  func filterEvents(_ isIncluded: (AnyMIDIEvent) -> Bool) -> [AnyMIDIEvent] { return eventContainer.filter(isIncluded) }

  func dispatchEvents(for time: BarBeatTime) { events(for: time)?.forEach(dispatch) }

  var metaEvents: AnyBidirectionalCollection<MetaEvent>       { return eventContainer.metaEvents    }
  var channelEvents: AnyBidirectionalCollection<ChannelEvent> { return eventContainer.channelEvents }
  var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent>   { return eventContainer.nodeEvents    }
  var timeEvents: AnyBidirectionalCollection<MetaEvent>       { return eventContainer.timeEvents    }

}

enum AnyMIDIEvent: MIDIEvent, Hashable {
  case meta    (MetaEvent)
  case channel (ChannelEvent)
  case node    (MIDINodeEvent)

  var event: MIDIEvent {
    switch self {
      case .meta   (let event): return event
      case .channel(let event): return event
      case .node   (let event): return event
    }
  }

  var time: BarBeatTime {
    get { return event.time }
    set {
      switch self {
        case .meta   (var event): event.time = newValue; self = .meta(event)
        case .channel(var event): event.time = newValue; self = .channel(event)
        case .node   (var event): event.time = newValue; self = .node(event)
      }
    }
  }

  var delta: MIDIFile.VariableLengthQuantity? {
    get { return event.delta }
    set {
      switch self {
        case .meta   (var event): event.delta = newValue; self = .meta(event)
        case .channel(var event): event.delta = newValue; self = .channel(event)
        case .node   (var event): event.delta = newValue; self = .node(event)
      }
    }
  }

  var bytes: [Byte] { return event.bytes }

  var description: String { return event.description }

}

extension AnyMIDIEvent: Equatable {

  static func ==(lhs: AnyMIDIEvent, rhs: AnyMIDIEvent) -> Bool {
    switch (lhs, rhs) {
      case let (.meta(meta1),       .meta(meta2)) where meta1 == meta2:             return true
      case let (.channel(channel1), .channel(channel2)) where channel1 == channel2: return true
      case let (.node(node1),       .node(node2)) where node1 == node2:             return true
      default:                                                                      return false
    }
  }

}
