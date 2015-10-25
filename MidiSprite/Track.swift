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

class Track: CustomStringConvertible, CustomDebugStringConvertible {

  var eventContainer = MIDIEventContainer() { didSet { Notification.DidUpdateEvents.post(object: self) } }
  var eventMap = MIDIEventMap()

  var endOfTrack: CABarBeatTime { return eventContainer.endOfTrackEvent?.time ?? BarBeatTime.time }

  var name: String { return "" }

  /** validateFirstAndLastEvents */
  func validateFirstAndLastEvents() {
    if var event = eventContainer.trackNameEvent,
      case let .SequenceTrackName(n) = event.data where n != name
    {
      event.data = .SequenceTrackName(name: name)
      eventContainer.trackNameEvent = event
    } else if eventContainer.trackNameEvent == nil {
      eventContainer.trackNameEvent = MetaEvent(.SequenceTrackName(name: name))
    }

    if eventContainer.count < 2 { eventContainer.endOfTrackEvent = MetaEvent(.EndOfTrack) }
    else if eventContainer.endOfTrackEvent == nil {
      eventContainer.endOfTrackEvent = MetaEvent(.EndOfTrack, eventContainer.last?.time)
    } else {
      let previousEvent = eventContainer[eventContainer.count - 2]
      if var event = eventContainer.endOfTrackEvent where event.time != previousEvent.time {
        event.time = previousEvent.time
        eventContainer.endOfTrackEvent = event
      }
    }
  }

  var chunk: MIDIFileTrackChunk {
    validateFirstAndLastEvents()
    return MIDIFileTrackChunk(eventContainer: eventContainer)
  }

  init() {}

  var description: String {
    return "\n".join(
      "events:\n\(eventContainer.description.indentedBy(1, useTabs: true))",
      "map:\n\(eventMap.description.indentedBy(1, useTabs: true))"
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

