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

  var eventContainer = MIDIEventContainer() {
    didSet {
      logDebug("posting 'DidUpdateEvents'")
      Notification.DidUpdateEvents.post(object: self)
    }
  }
  var eventMap = MIDIEventMap()

  var endOfTrack: CABarBeatTime { return eventContainer.endOfTrackEvent.time ?? Sequencer.time.time }

  var name: String { get { return eventContainer.trackName } set { eventContainer.trackName = newValue } }

  /** validateEvents */
  func validateEvents() { eventContainer.validate() }

  var chunk: MIDIFileTrackChunk {
    validateEvents()
    return MIDIFileTrackChunk(eventContainer: eventContainer)
  }

  private let receptionist = NotificationReceptionist()

  private(set) var recording = false

  /** init */
  init() {
    receptionist.logContext = LogManager.SequencerContext
    receptionist.observe(Sequencer.Notification.DidToggleRecording, from: Sequencer.self, queue: NSOperationQueue.mainQueue()) {
      [weak self] _ in self?.recording = Sequencer.recording
    }
    recording = Sequencer.recording
  }

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

