//
//  EventManager.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/6/21.
//
import CoreMIDI
import Foundation
import MIDI
import MoonDev
import SoundFont
import SwiftUI

// MARK: - EventManaging

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public protocol EventManaging { var eventManager: EventManager { get } }

// MARK: - EventManager

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class EventManager: Identifiable
{

  @Environment(\.currentTransport) var currentTransport: Transport

  public let id: UUID

  let eventQueue: DispatchQueue

  var container = EventContainer()

  var additionFilter: ([Event]) -> [Event]

  var eventDispatch: (Event) -> Void

  var additionalTimes: ([Event]) -> [BarBeatTime]

  var registrationFilter: (inout [Event]) -> Void

  var nodeManager: NodeManager?

  init(additionFilter: @escaping ([Event]) -> [Event] = { $0 },
       eventDispatch: @escaping (Event) -> Void = { _ in },
       additionalTimes: @escaping ([Event]) -> [BarBeatTime] = { _ in [] },
       registrationFilter: @escaping (inout [Event]) -> Void = { _ in },
       nodeManager: NodeManager? = nil)
  {
    self.additionFilter = additionFilter
    self.eventDispatch = eventDispatch
    self.additionalTimes = additionalTimes
    self.registrationFilter = registrationFilter

    let uuid = UUID()
    id = uuid

    let label = "com.moondeerstudios.groove.event-manager.\(uuid.uuidString)"
    eventQueue = DispatchQueue(label: label)
  }

  public var endOfTrack: BarBeatTime { container.maxTime ?? BarBeatTime.zero }

  public func add(event: Event) { add(events: [event]) }

  /// Adds the MIDI events in `events` to the track. Instrument events and program change
  /// events are used to update the `instrumentEvent` and `programEvent` properties before
  /// passing the remaining events to `super` for the default implementation provided by
  /// the `EventDispatch` protocol.
  ///
  /// - Parameter events: The sequence containing the MIDI events to add to the track.
  public func add<S>(events: S) where S: Swift.Sequence, S.Element == Event
  {
    let events = additionFilter(Array(events))
    container.append(contentsOf: events)
    currentTransport.time.register(
      callback: weakCapture(of: self, block: type(of: self).dispatchEvents),
      forTimes: registrationTimes(forAdding: events),
      identifier: UUID()
    )
  }

  public func events(for t: BarBeatTime)
    -> AnyRandomAccessCollection<Event>? { container[t] }

  public func filterEvents(_ include: (Event) -> Bool) -> [Event]
  { container
    .filter(include)
  }

  /// Dispatches the specified event. The default implementation does nothing but
  /// invoke `eventDispatch(event:)`
  ///
  /// - Parameter event: The MIDI event to dispatch.
  public func dispatch(event: Event)
  {
    eventDispatch(event)
    if let nodeManager = nodeManager,
       case let .node(nodeEvent) = event
    {
      nodeManager.handle(event: nodeEvent)
    }
  }

  /// Retrieves and dispatches events for the specified time.
  /// - Parameter time: The bar beat time for which events shall be dispatched.
  public func dispatchEvents(for time: BarBeatTime)
  {
    events(for: time)?.forEach(dispatch)
  }

  /// Generates times with which to register clock callbacks according to the
  /// specified MIDI events. The default implementation returns the time that
  /// corresponds with the end of the track or an empty array if no such event
  /// may be found within `events`. Additional times may be added via `additionalTimes`.
  /// - Parameter events: The MIDI events for which to generate registration times.
  /// - Returns: The registration times appropriate for `events`.
  public func registrationTimes<S>(forAdding events: S) -> [BarBeatTime]
    where S: Swift.Sequence, S.Element == Event
  {
    var times: [BarBeatTime] = []

    var events = Array(events)

    registrationFilter(&events)

    // Get the end of track event contained by `events` or return an empty array.
    if let eot = events.first(where: {
      if case let .meta(event) = $0, event.data == .endOfTrack { return true }
      else { return false }
    })

    {
      times.append(eot.time)
    }

    times.append(contentsOf: additionalTimes(Array(events)))

    return times
  }

  public var events: [Event] { Array(container)}
  
  public var metaEvents: AnyBidirectionalCollection<MetaEvent> { container.metaEvents }

  public var channelEvents: AnyBidirectionalCollection<ChannelEvent>
  {
    container.channelEvents
  }

  public var nodeEvents: AnyBidirectionalCollection<NodeEvent> { container.nodeEvents }

  public var timeEvents: AnyBidirectionalCollection<MetaEvent> { container.timeEvents }

  public var tempoEvents: AnyBidirectionalCollection<MetaEvent> { container.tempoEvents }
}
