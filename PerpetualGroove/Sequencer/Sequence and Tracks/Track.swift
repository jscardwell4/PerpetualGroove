//
//  Track.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

class Track: Named, MIDIEventDispatch, CustomStringConvertible {

  unowned let sequence: Sequence

  /// Queue used generating `MIDIFile` track events
  let eventQueue: DispatchQueue

  var eventContainer = MIDIEventContainer()

  var endOfTrack: BarBeatTime { return eventContainer.maxTime ?? BarBeatTime.zero }

  fileprivate var trackNameEvent: MIDIEvent = .meta(MIDIEvent.MetaEvent(data: .sequenceTrackName(name: "")))
  fileprivate var endOfTrackEvent: MIDIEvent = .meta(MIDIEvent.MetaEvent(data: .endOfTrack))

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
      Log.debug("'\(name)' ➞ '\(newValue)'")
      trackNameEvent = .meta(MIDIEvent.MetaEvent(data: .sequenceTrackName(name: newValue)))
      postNotification(name: .didUpdate, object: self, userInfo: nil)
      postNotification(name: .didChangeName, object: self, userInfo: nil)
    }
  }

  var displayName: String { return name }

  func validate(events container: inout MIDIEventContainer) { endOfTrackEvent.time = endOfTrack }

  var chunk: MIDIFile.TrackChunk {
    validate(events: &eventContainer)
    let events: [MIDIEvent] = headEvents + Array<MIDIEvent>(eventContainer) + tailEvents
    return MIDIFile.TrackChunk(events: events)
  }

  var headEvents: [MIDIEvent] { return [trackNameEvent] }

  var tailEvents: [MIDIEvent] { return [endOfTrackEvent] }

  init(sequence: Sequence) {
    self.sequence = sequence
    eventQueue = DispatchQueue(label: "Track\(sequence.tracks.count)")
  }

  func registrationTimes<S:Swift.Sequence>(forAdding events: S) -> [BarBeatTime]
    where S.Iterator.Element == MIDIEvent
  {
    guard let eot = events.first(where: {
      guard case .meta(let event) = $0, event.data == .endOfTrack else { return false }
      return true
    }) else { return [] }
    return [eot.time]
  }

  /// Overridden by subclasses to handle actual event generation
  func dispatch(event: MIDIEvent) { }

  var description: String {
    return "\n".join("name: \(name)", "events:\n\(eventContainer)")
  }

}

// MARK: - Notifications
extension Track: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case didUpdate, didChangeName, forceMuteStatusDidChange, muteStatusDidChange, soloStatusDidChange

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }
  }

}


