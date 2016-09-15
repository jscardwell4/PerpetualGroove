//
//  Track.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

class Track: CustomStringConvertible, Named, MIDIEventDispatch {

  unowned let sequence: Sequence

  /// Queue used generating `MIDIFile` track events
  let eventQueue: DispatchQueue

  var events = MIDIEventContainer()

  var endOfTrack: BarBeatTime {
    return events.maxTime ?? Sequencer.time.barBeatTime
  }

  fileprivate var trackNameEvent: MIDIEvent = .meta(MetaEvent(.sequenceTrackName(name: "")))
  fileprivate var endOfTrackEvent: MIDIEvent = .meta(MetaEvent(.endOfTrack))

  var name: String {
    get {
      switch trackNameEvent {
        case .meta(let event):
          switch event.data {
            case .sequenceTrackName(let name): return name
            default: return ""
          }
      default: return ""
      }
    }
    set {
      guard name != newValue else { return }
      logDebug("'\(name)' ➞ '\(newValue)'")
      trackNameEvent = .meta(MetaEvent(.sequenceTrackName(name: newValue)))
      Notification.DidUpdate.post(object: self)
      Notification.DidChangeName.post(object: self)
    }
  }

  var displayName: String { return name }

  /** validateEvents */
  func validateEvents(_ container: inout MIDIEventContainer) {
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

//  private var _recording = false { didSet { logDebug("recording = \(_recording)") } }
//  var recording: Bool {
//    get { objc_sync_enter(self); defer { objc_sync_exit(self) }; return _recording && Sequencer.mode == .Default }
//    set { objc_sync_enter(self); defer { objc_sync_exit(self) }; _recording = newValue }
//  }

  /** init */
  init(sequence: Sequence) {
    self.sequence = sequence
    eventQueue = serialQueueWithLabel("Track\(sequence.tracks.count)")
  }

  /**
  registrationTimesForAddedEvents:

  - parameter events: [MIDIEvent]

  - returns: [BarBeatTime]
  */
  func registrationTimesForAddedEvents<S:Swift.Sequence>(_ events: S) -> [BarBeatTime] where S.Iterator.Element == MIDIEvent {
    guard let eot = events.filter({($0.event as? MetaEvent)?.data == .endOfTrack}).first else { return [] }
    return [eot.time]
  }

  /**
  Overridden by subclasses to handle actual event generation

  - parameter event: MIDIEvent
  */
  func dispatchEvent(_ event: MIDIEvent) { }

  var description: String {
    return "\n".join(
      "name: \(name)",
      "events:\n\(events.description.indentedBy(1, useTabs: true))"
    )
  }
}

// MARK: - Notifications
extension Track: NotificationDispatchType {

  enum Notification: String, NotificationType, NotificationNameType {
    enum Key: String, KeyType { case OldValue, NewValue }
    case DidUpdate, DidChangeName
    case ForceMuteStatusDidChange, MuteStatusDidChange, SoloStatusDidChange
  }

}


