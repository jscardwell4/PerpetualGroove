//
//  TempoTrack.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreMIDI
import MoonKit
import struct AudioToolbox.CABarBeatTime


final class TempoTrack: MIDITrackType {

  let time = Sequencer.time
  var trackEnd: CABarBeatTime { return eventContainer.endOfTrackEvent?.time ?? time.time }

  var eventContainer = MIDIEventContainer()

  var hasTimeSignatureEvent: Bool {
    let isTimeSignature: (MIDIEvent) -> Bool = {
      if let event = $0 as? MetaEvent, case .TimeSignature = event.data { return true } else { return false }
    }
    return eventContainer.events.filter(isTimeSignature).count != 0
  }

  var hasTempoEvent: Bool {
    let isTempoEvent: (MIDIEvent) -> Bool = {
      if let event = $0 as? MetaEvent, case .Tempo = event.data { return true } else { return false }
    }
    return eventContainer.events.filter(isTempoEvent).count != 0
  }

  private let receptionist = NotificationReceptionist()

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    guard receptionist.count == 0 else { return }

    receptionist.observe(Sequencer.Notification.DidToggleRecording, from: Sequencer.self, queue: NSOperationQueue.mainQueue()) {
      [weak self] _ in self?.recording = Sequencer.recording
    }
  }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    guard recording else { return }
    eventContainer.append(MetaEvent(time.time, .Tempo(microseconds: Byte4(60_000_000 / tempo))))
  }

  let name = "Tempo"
  var recording = false

  /**
  Initializer for non-playback mode tempo track
  
  - parameter s: MIDISequence
  */
  init(/*sequence s: MIDISequence*/) {
//    sequence = s
    recording = Sequencer.recording
    eventContainer.append(TempoTrack.timeSignatureEvent)
    eventContainer.append(TempoTrack.tempoEvent)
  }


  static private var timeSignatureEvent: MetaEvent {
    return MetaEvent(.TimeSignature(upper: Sequencer.timeSignature.beatsPerBar,
                                    lower: Sequencer.timeSignature.beatUnit,
                                    clocks: 36,
                                    notes: 8))
  }

  static private var tempoEvent: MetaEvent {
    return MetaEvent(.Tempo(microseconds: Byte4(60_000_000 / Sequencer.tempo)))
  }

  /**
  isTempoTrackEvent:

  - parameter trackEvent: MIDIEvent

  - returns: Bool
  */
  static func isTempoTrackEvent(trackEvent: MIDIEvent) -> Bool {
    guard let metaEvent = trackEvent as? MetaEvent else { return false }
    switch metaEvent.data {
      case .Tempo, .TimeSignature, .EndOfTrack: return true
      case .SequenceTrackName(let name) where name.lowercaseString == "tempo": return true
      default: return false
    }
  }

  private(set) var eventMap = MIDIEventMap()

  /**
  dispatchEventsForTime:

  - parameter time: CABarBeatTime
  */
  private func dispatchEventsForTime(time: CABarBeatTime) {
    guard let events = eventMap.eventsForTime(time) else { return }
    for event in events where event is MetaEvent {
      switch (event as! MetaEvent).data {
        case let .Tempo(microseconds): Sequencer.tempo = Double(60_000_000 / microseconds)
        case let .TimeSignature(upper, lower, _, _): Sequencer.timeSignature = TimeSignature(upper, lower)
        default: break
      }
    }
  }

//  private(set) unowned var sequence: MIDISequence

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  - parameter s: MIDISequence
  */
  init(trackChunk: MIDIFileTrackChunk/*, sequence s: MIDISequence*/) {
//    sequence = s
    eventContainer = MIDIEventContainer(events: trackChunk.events.filter(TempoTrack.isTempoTrackEvent))

    if !hasTimeSignatureEvent { eventContainer.insert(TempoTrack.timeSignatureEvent, atIndex: 0) }
    if !hasTempoEvent { eventContainer.insert(TempoTrack.tempoEvent, atIndex: 1) }

    eventMap.insert(eventContainer.events)

    time.registerCallback(dispatchEventsForTime, forTimes: eventMap.times, forObject: self)
  }

}

extension TempoTrack: CustomStringConvertible {
  var description: String {
    return "\n".join(
      "events:\n\(eventContainer.description.indentedBy(1, useTabs: true))",
      "map:\n\(eventMap.description.indentedBy(1, useTabs: true))"
    )
  }
}

extension TempoTrack: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}