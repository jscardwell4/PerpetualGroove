//
//  Track.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

class Track: CustomStringConvertible, CustomDebugStringConvertible, Named {

  unowned let sequence: Sequence

  /// Queue used generating `MIDIFile` track events
  let eventQueue: NSOperationQueue = {
    let q = NSOperationQueue()
    q.maxConcurrentOperationCount = 1
    return q
  }()


  /**
  addEvent:

  - parameter event: MIDIEvent
  */
  func addEvent(event: MIDIEvent) { addEvents([event]) }

  /**
  addEvents:

  - parameter events: [MIDIEvent]
  */
  func addEvents(events: [MIDIEvent]) {
    eventContainer.appendEvents(events)
    Sequencer.time.registerCallback(weakMethod(self, Track.dispatchEventsForTime),
                           forTimes: registrationTimesForAddedEvents(events),
                          forObject: self)
  }

  /**
  eventsForTime:

  - parameter time: CABarBeatTime

  - returns: [MIDIEvent]?
  */
  func eventsForTime(time: CABarBeatTime) -> [MIDIEvent]? { return eventContainer[time] }

  /**
  filterEvents:

  - parameter includeElement: (MIDIEvent) -> Bool

  - returns: [MIDIEvent]
  */
  func filterEvents(includeElement: (MIDIEvent) -> Bool) -> [MIDIEvent] {
    return eventContainer.events.filter(includeElement)
  }

  private var _eventContainer = MIDIEventContainer()

  var eventContainer: MIDIEventContainer {
    get { objc_sync_enter(self); defer { objc_sync_exit(self) }; return _eventContainer     }
    set { objc_sync_enter(self); defer { objc_sync_exit(self) }; _eventContainer = newValue }
  }

  var endOfTrack: CABarBeatTime {
    return eventContainer.endOfTrackEvent.time ?? Sequencer.time.time
  }

  var instrumentName: String? {
    get { return eventContainer.instrumentName }
    set { eventContainer.instrumentName = newValue }
  }

  var program: (channel: Byte, program: Byte)? {
    get { return eventContainer.program }
    set { eventContainer.program = newValue }
  }

  var metaEvents: [MetaEvent] { return eventContainer.metaEvents } 
  var channelEvents: [ChannelEvent] { return eventContainer.channelEvents } 
  var nodeEvents: [MIDINodeEvent] { return eventContainer.nodeEvents } 
  var name: String {
    get { return eventContainer.trackName }
    set {
      logDebug("'\(name)' ➞ '\(newValue)'")
      eventContainer.trackName = newValue
      Notification.DidUpdateEvents.post(object: self)
    }
  }

  /** validateEvents */
  func validateEvents(inout container: MIDIEventContainer) {
    container.trackName = name
    container.validate()
  }

  var chunk: MIDIFileTrackChunk {
    validateEvents(&eventContainer)
    return MIDIFileTrackChunk(eventContainer: eventContainer)
  }

  private var _recording = false { didSet { logDebug("recording = \(_recording)") } }
  var recording: Bool {
    get { objc_sync_enter(self); defer { objc_sync_exit(self) }; return _recording     }
    set { objc_sync_enter(self); defer { objc_sync_exit(self) }; _recording = newValue }
  }

  /** init */
  init(sequence: Sequence) { self.sequence = sequence }

  /**
  registrationTimesForAddedEvents:

  - parameter events: [MIDIEvent]

  - returns: [CABarBeatTime]
  */
  func registrationTimesForAddedEvents(events: [MIDIEvent]) -> [CABarBeatTime] {
    guard let eot = events.first({($0 as? MetaEvent)?.data == .EndOfTrack}) else { return [] }
    return [eot.time]
  }

  /**
  Invokes `dispatchEvent:` for each event associated with the specified `time`

  - parameter time: CABarBeatTime
  */
  private func dispatchEventsForTime(time: CABarBeatTime) { eventsForTime(time)?.forEach(dispatchEvent) }

  /**
  Overridden by subclasses to handle actual event generation

  - parameter event: MIDIEvent
  */
  func dispatchEvent(event: MIDIEvent) { }

  var description: String {
    return "\n".join(
      "name: \(name)",
      "recording: \(recording)",
      "events:\n\(eventContainer.description.indentedBy(1, useTabs: true))"
    )
  }

  var debugDescription: String { return String(reflecting: self) }

  deinit { print("\(self.dynamicType):\(name)") }
}

extension Track {
  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdateEvents
    typealias Key = String
  }
}

