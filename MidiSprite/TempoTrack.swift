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

final class TempoTrack: Track {

  override var name: String { get { return "Tempo" } set {} }

  var tempo: Double = Sequencer.tempo {
    didSet {
      guard tempo != oldValue else { return }
      guard recording else { logDebug("not recording…skipping event creation"); return }
      logDebug("inserting event for tempo \(tempo)")
      addEvent(tempoEvent)
      Notification.DidUpdateEvents.post(object: self)
    }
  }

  var timeSignature: TimeSignature = Sequencer.timeSignature {
    didSet {
      guard timeSignature != oldValue else { return }
      guard recording else { logDebug("not recording…skipping event creation"); return }
      logDebug("inserting event for signature \(timeSignature)")
      addEvent(timeSignatureEvent)
      Notification.DidUpdateEvents.post(object: self)
    }
  }

  private var timeSignatureEvent: MetaEvent {
    return MetaEvent(Sequencer.time.time, .TimeSignature(signature: timeSignature, clocks: 36, notes: 8))
  }

  private var tempoEvent: MetaEvent {
    return MetaEvent(Sequencer.time.time, .Tempo(bpm: tempo))
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

  /**
  dispatchEventsForTime:

  - parameter time: CABarBeatTime
  */
  private func dispatchEventsForTime(time: CABarBeatTime) {
    guard let events = eventsForTime(time) else { return }
    for event in events where event is MetaEvent {
      switch (event as! MetaEvent).data {
        case let .Tempo(bpm): tempo = bpm; Sequencer.setTempo(bpm, automated: true)
        case let .TimeSignature(signature, _, _): timeSignature = signature
        default: break
      }
    }
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist()
    receptionist.logContext = LogManager.SequencerContext
    receptionist.callbackQueue = NSOperationQueue.mainQueue()
    return receptionist
  }()

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    receptionist.observe(Sequencer.Notification.DidToggleRecording, from: Sequencer.self) {
      [weak self] _ in self?.recording = Sequencer.recording
    }
  }

  /**
  Initializer for non-playback mode tempo track
  
  - parameter s: MIDISequence
  */
  override init(sequence: MIDISequence) {
    super.init(sequence: sequence)
    initializeNotificationReceptionist()
    addEvent(timeSignatureEvent)
    addEvent(tempoEvent)
  }

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  - parameter s: MIDISequence
  */
  init(sequence: MIDISequence, trackChunk: MIDIFileTrackChunk) {
    super.init(sequence: sequence)
    initializeNotificationReceptionist()
    addEvents(trackChunk.events.filter(TempoTrack.isTempoTrackEvent))

    if filterEvents({
      if let event = $0 as? MetaEvent, case .TimeSignature = event.data { return true } else { return false }
    }).count == 0
    {
      addEvent(timeSignatureEvent)
    }

    if filterEvents({
      if let event = $0 as? MetaEvent, case .Tempo = event.data { return true } else { return false }
    }).count == 0
    {
      addEvent(tempoEvent)
    }
  }

}
