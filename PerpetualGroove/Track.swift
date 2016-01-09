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
    self.events.appendEvents(events)
    Sequencer.time.registerCallback(weakMethod(self, Track.dispatchEventsForTime),
                           forTimes: registrationTimesForAddedEvents(events),
                          forObject: self)
  }

  /**
  eventsForTime:

  - parameter time: CABarBeatTime

  - returns: [MIDIEvent]?
  */
  func eventsForTime(time: CABarBeatTime) -> OrderedSet<MIDIEvent>? { return events.eventsForTime(time) }

  /**
  filterEvents:

  - parameter includeElement: (MIDIEvent) -> Bool

  - returns: [MIDIEvent]
  */
  func filterEvents(includeElement: (MIDIEvent) -> Bool) -> [MIDIEvent] {
    return events.filter(includeElement)
  }

  var events = MIDIEventContainer()

//  var events: MIDIEventContainer {
//    get { objc_sync_enter(self); defer { objc_sync_exit(self) }; return _events     }
//    set { objc_sync_enter(self); defer { objc_sync_exit(self) }; _events = newValue }
//  }

  var endOfTrack: CABarBeatTime {
    return events.maxTime
  }

  private var trackNameEvent: MIDIEvent = .Meta(MetaEvent(.SequenceTrackName(name: "")))
  private var endOfTrackEvent: MIDIEvent = .Meta(MetaEvent(.EndOfTrack))

  var metaEvents: [MetaEvent] { return events.metaEvents }
  var channelEvents: [ChannelEvent] { return events.channelEvents } 
  var nodeEvents: [MIDINodeEvent] { return events.nodeEvents } 
  var name: String {
    get {
      switch trackNameEvent {
        case .Meta(let event):
          switch event.data {
            case .SequenceTrackName(let name): return name
            default: return ""
          }
      default: return ""
      }
    }
    set {
      guard name != newValue else { return }
      logDebug("'\(name)' ➞ '\(newValue)'")
      trackNameEvent = .Meta(MetaEvent(.SequenceTrackName(name: newValue)))
      Notification.DidUpdate.post(object: self)
      Notification.DidChangeName.post(object: self)
    }
  }

  /** validateEvents */
  func validateEvents(inout container: MIDIEventContainer) {
    endOfTrackEvent.time = endOfTrack
  }

  var chunk: MIDIFileTrackChunk {
    validateEvents(&self.events)
    let events: [MIDIEvent] = headEvents + self.events + tailEvents
    return MIDIFileTrackChunk(events: events)
  }

  var headEvents: [MIDIEvent] {
    return [trackNameEvent]
  }

  var tailEvents: [MIDIEvent] {
    return [endOfTrackEvent]
  }

  private var _recording = false { didSet { logDebug("recording = \(_recording)") } }
  var recording: Bool {
    get { objc_sync_enter(self); defer { objc_sync_exit(self) }; return /*_recording &&*/ Sequencer.mode == .Default }
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
    guard let eot = events.first({($0.event as? MetaEvent)?.data == .EndOfTrack}) else { return [] }
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
      "events:\n\(events.description.indentedBy(1, useTabs: true))"
    )
  }

  var debugDescription: String { return String(reflecting: self) }
}

extension Track {
  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdate, DidChangeName
    typealias Key = String
  }
}

