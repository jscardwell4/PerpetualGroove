//
//  MIDIEventDispatch.swift
//  Groove
//
//  Created by Jason Cardwell on 1/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

/// Protocol for types that maintain a collection of dispatchable MIDI events.
public protocol MIDIEventDispatch: class {

  func add(event: MIDIEvent)
  func add<S:Sequence>(events: S) where S.Element == MIDIEvent

  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>?

  func filterEvents(_ isIncluded: (MIDIEvent) -> Bool) -> [MIDIEvent]

  func dispatchEvents(for time: BarBeatTime)
  func dispatch(event: MIDIEvent)

  func registrationTimes<S>(forAdding events: S) -> [BarBeatTime]
    where S:Sequence, S.Element == MIDIEvent

  var eventContainer: MIDIEventContainer { get set }
  var metaEvents: AnyBidirectionalCollection<MetaEvent> { get }
  var channelEvents: AnyBidirectionalCollection<ChannelEvent> { get }
  var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> { get }
  var timeEvents: AnyBidirectionalCollection<MetaEvent> { get }
  var tempoEvents: AnyBidirectionalCollection<MetaEvent> { get }

  var eventQueue: DispatchQueue { get }

}

public extension MIDIEventDispatch {

  func add(event: MIDIEvent) { add(events: [event]) }

  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>?  {
    eventContainer[time]
  }

  func filterEvents(_ isIncluded: (MIDIEvent) -> Bool) -> [MIDIEvent] {
    eventContainer.filter(isIncluded)
  }

  func dispatchEvents(for time: BarBeatTime) { events(for: time)?.forEach(dispatch) }

  var metaEvents: AnyBidirectionalCollection<MetaEvent> {
    eventContainer.metaEvents
  }

  var channelEvents: AnyBidirectionalCollection<ChannelEvent> {
    eventContainer.channelEvents
  }

  var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> {
    eventContainer.nodeEvents
  }

  var timeEvents: AnyBidirectionalCollection<MetaEvent> {
    eventContainer.timeEvents
  }

  var tempoEvents: AnyBidirectionalCollection<MetaEvent> {
    eventContainer.tempoEvents
  }

}
