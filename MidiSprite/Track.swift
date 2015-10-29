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

  private let eventContainerLock = NSObject()

  /**
  addEvent:

  - parameter event: MIDIEvent
  */
  func addEvent(event: MIDIEvent) {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    eventContainer.append(event)
  }

  /**
  addEvents:

  - parameter events: [MIDIEvent]
  */
  func addEvents(events: [MIDIEvent]) {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    eventContainer.appendEvents(events)
  }

  /**
  eventsForTime:

  - parameter time: CABarBeatTime

  - returns: [MIDIEvent]?
  */
  func eventsForTime(time: CABarBeatTime) -> [MIDIEvent]? {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    return eventContainer[time]
  }

  /**
  filterEvents:

  - parameter includeElement: (MIDIEvent) -> Bool

  - returns: [MIDIEvent]
  */
  func filterEvents(includeElement: (MIDIEvent) -> Bool) -> [MIDIEvent] {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    return eventContainer.events.filter(includeElement)
  }

  private var eventContainer = MIDIEventContainer()

  var endOfTrack: CABarBeatTime {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    return eventContainer.endOfTrackEvent.time ?? Sequencer.time.time
  }

  var instrumentName: String? {
    get {
      objc_sync_enter(eventContainerLock)
      defer { objc_sync_exit(eventContainerLock) }
      return eventContainer.instrumentName
    }
    set {
      objc_sync_enter(eventContainerLock)
      defer { objc_sync_exit(eventContainerLock) }
      eventContainer.instrumentName = newValue
    }
  }

  var program: (channel: Byte, program: Byte)? {
    get {
      objc_sync_enter(eventContainerLock)
      defer { objc_sync_exit(eventContainerLock) }
      return eventContainer.program
    }
    set {
      objc_sync_enter(eventContainerLock)
      defer { objc_sync_exit(eventContainerLock) }
      eventContainer.program = newValue
    }
  }

  var metaEvents: [MetaEvent] {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    return eventContainer.metaEvents
  }

  var channelEvents: [ChannelEvent] {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    return eventContainer.channelEvents
  }

  var nodeEvents: [MIDINodeEvent] {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    return eventContainer.nodeEvents
  }

  var name: String {
    get { return eventContainer.trackName }
    set {
      logDebug("'\(name)' ➞ '\(newValue)'")
      eventContainer.trackName = newValue
      Notification.DidUpdateEvents.post(object: self)
    }
  }

  /** validateEvents */
  func validateEvents(inout container: MIDIEventContainer) { container.validate() }

  var chunk: MIDIFileTrackChunk {
    objc_sync_enter(eventContainerLock)
    defer { objc_sync_exit(eventContainerLock) }
    validateEvents(&eventContainer)
    return MIDIFileTrackChunk(eventContainer: eventContainer)
  }

  var recording = false { didSet { logDebug("recording = \(recording)") } }

  /** init */
  init() {}

  var description: String {
    return "\n".join(
      "name: \(name)",
      "recording: \(recording)",
      "events:\n\(eventContainer.description.indentedBy(1, useTabs: true))"
    )
  }

  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension Track {
  enum Notification: String, NotificationType, NotificationNameType {
    case DidUpdateEvents
    typealias Key = String
  }
}

