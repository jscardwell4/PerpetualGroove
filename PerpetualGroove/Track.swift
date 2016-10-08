//
//  Track.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

class Track: Named, MIDIEventDispatch, CustomStringConvertible {

  unowned let sequence: Sequence

  /// Queue used generating `MIDIFile` track events
  let eventQueue: DispatchQueue

  var eventContainer = MIDIEventContainer()

  var endOfTrack: BarBeatTime { return eventContainer.maxTime ?? BarBeatTime.zero }

  fileprivate var trackNameEvent: AnyMIDIEvent = .meta(MetaEvent(.sequenceTrackName(name: "")))
  fileprivate var endOfTrackEvent: AnyMIDIEvent = .meta(MetaEvent(.endOfTrack))

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
      postNotification(name: .didUpdate, object: self, userInfo: nil)
      postNotification(name: .didChangeName, object: self, userInfo: nil)
    }
  }

  var displayName: String { return name }

  func validate(events container: inout MIDIEventContainer) { endOfTrackEvent.time = endOfTrack }

  var chunk: MIDIFile.TrackChunk {
    validate(events: &eventContainer)
    let events: [AnyMIDIEvent] = headEvents + Array<AnyMIDIEvent>(eventContainer) + tailEvents
    return MIDIFile.TrackChunk(events: events)
  }

  var headEvents: [AnyMIDIEvent] { return [trackNameEvent] }

  var tailEvents: [AnyMIDIEvent] { return [endOfTrackEvent] }

  init(sequence: Sequence) {
    self.sequence = sequence
    eventQueue = DispatchQueue(label: "Track\(sequence.tracks.count)")
  }

  func registrationTimes<S:Swift.Sequence>(forAdding events: S) -> [BarBeatTime]
    where S.Iterator.Element == AnyMIDIEvent
  {
    guard let eot = events.first(where: {($0.event as? MetaEvent)?.data == .endOfTrack}) else { return [] }
    return [eot.time]
  }

  /// Overridden by subclasses to handle actual event generation
  func dispatch(event: AnyMIDIEvent) { }

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


