//
//  EventDispatch.swift
//  Groove
//
//  Created by Jason Cardwell on 1/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

// MARK: - EventDispatch

/// Protocol for types that maintain a collection of dispatchable MIDI events.
public protocol EventDispatch: class
{
  func add(event: Event)
  func add<S: Sequence>(events: S) where S.Element == Event
  
  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<Event>?
  
  func filterEvents(_ isIncluded: (Event) -> Bool) -> [Event]
  
  func dispatchEvents(for time: BarBeatTime)
  func dispatch(event: Event)
  
  func registrationTimes<S>(forAdding events: S) -> [BarBeatTime]
  where S: Sequence, S.Element == Event
  
  var eventContainer: EventContainer { get set }
  var metaEvents: AnyBidirectionalCollection<MetaEvent> { get }
  var channelEvents: AnyBidirectionalCollection<ChannelEvent> { get }
  var nodeEvents: AnyBidirectionalCollection<NodeEvent> { get }
  var timeEvents: AnyBidirectionalCollection<MetaEvent> { get }
  var tempoEvents: AnyBidirectionalCollection<MetaEvent> { get }
  
  var eventQueue: DispatchQueue { get }
}

public extension EventDispatch
{
  func add(event: Event) { add(events: [event]) }
  
  func events(for time: BarBeatTime) -> AnyRandomAccessCollection<Event>?
  {
    eventContainer[time]
  }
  
  func filterEvents(_ isIncluded: (Event) -> Bool) -> [Event]
  {
    eventContainer.filter(isIncluded)
  }
  
  func dispatchEvents(for time: BarBeatTime) { events(for: time)?.forEach(dispatch) }
  
  var metaEvents: AnyBidirectionalCollection<MetaEvent>
  {
    eventContainer.metaEvents
  }
  
  var channelEvents: AnyBidirectionalCollection<ChannelEvent>
  {
    eventContainer.channelEvents
  }
  
  var nodeEvents: AnyBidirectionalCollection<NodeEvent>
  {
    eventContainer.nodeEvents
  }
  
  var timeEvents: AnyBidirectionalCollection<MetaEvent>
  {
    eventContainer.timeEvents
  }
  
  var tempoEvents: AnyBidirectionalCollection<MetaEvent>
  {
    eventContainer.tempoEvents
  }
}
