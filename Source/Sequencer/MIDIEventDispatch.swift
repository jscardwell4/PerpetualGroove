//
//  MIDIEventDispatch.swift
//  Groove
//
//  Created by Jason Cardwell on 1/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit
import MIDI

/// Protocol for types that maintain a collection of dispatchable MIDI events.
protocol MIDIEventDispatch: class {

  func add(event: MIDIEvent)
  func add<S:Swift.Sequence>(events: S) where S.Iterator.Element == MIDIEvent

  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>?

  func filterEvents(_ isIncluded: (MIDIEvent) -> Bool) -> [MIDIEvent]

  func dispatchEvents(for time: BarBeatTime)
  func dispatch(event: MIDIEvent)

  func registrationTimes<Source>(forAdding events: Source) -> [BarBeatTime]
    where Source:Swift.Sequence, Source.Iterator.Element == MIDIEvent

  var eventContainer: MIDIEventContainer { get set }
  var metaEvents: AnyBidirectionalCollection<MetaEvent> { get }
  var channelEvents: AnyBidirectionalCollection<ChannelEvent> { get }
  var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> { get }
  var timeEvents: AnyBidirectionalCollection<MetaEvent> { get }
  var tempoEvents: AnyBidirectionalCollection<MetaEvent> { get }

  var eventQueue: DispatchQueue { get }

}

extension MIDIEventDispatch {

  func add(event: MIDIEvent) { add(events: [event]) }

  func add<S:Swift.Sequence>(events: S) where S.Iterator.Element == MIDIEvent {
    eventContainer.append(contentsOf: events)
    Time.current?.register(callback: weakCapture(of: self, block:type(of: self).dispatchEvents),
                          forTimes: registrationTimes(forAdding: events),
                          identifier: UUID())
  }

  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<MIDIEvent>?  {
    return eventContainer[time]
  }

  func filterEvents(_ isIncluded: (MIDIEvent) -> Bool) -> [MIDIEvent] {
    return eventContainer.filter(isIncluded)
  }

  func dispatchEvents(for time: BarBeatTime) { events(for: time)?.forEach(dispatch) }

  var metaEvents: AnyBidirectionalCollection<MetaEvent> {
    return eventContainer.metaEvents
  }

  var channelEvents: AnyBidirectionalCollection<ChannelEvent> {
    return eventContainer.channelEvents
  }

  var nodeEvents: AnyBidirectionalCollection<MIDINodeEvent> {
    fatalError("\(#fileID) \(#function) Not yet implemented")
//    return eventContainer.nodeEvents
  }

  var timeEvents: AnyBidirectionalCollection<MetaEvent> {
    return eventContainer.timeEvents
  }

  var tempoEvents: AnyBidirectionalCollection<MetaEvent> {
    return eventContainer.tempoEvents
  }

}

