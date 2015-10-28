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

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    logDebug("inserting event for tempo \(tempo)")
    guard recording else { logDebug("not recording…skipping event creation"); return }
    eventContainer.append(MetaEvent(Sequencer.time.time, .Tempo(bpm: tempo)))
  }

  /**
  insertTimeSignature:

  - parameter signature: TimeSignature
  */
  func insertTimeSignature(signature: TimeSignature) {
    logDebug("inserting event for signature \(signature)")
    guard recording else { logDebug("not recording…skipping event creation"); return }
    eventContainer.append(MetaEvent(Sequencer.time.time, .TimeSignature(signature: signature, clocks: 36, notes: 8)))
  }

  override var name: String { get { return "Tempo" } set {} }

  private(set) var tempo: Double = 120
  private(set) var timeSignature: TimeSignature = .FourFour

  /**
  Initializer for non-playback mode tempo track
  
  - parameter s: MIDISequence
  */
  override init() {
    super.init()
    initializeNotificationReceptionist()
    eventContainer.append(TempoTrack.timeSignatureEvent)
    eventContainer.append(TempoTrack.tempoEvent)
  }

  static private var timeSignatureEvent: MetaEvent {
    return MetaEvent(.TimeSignature(signature: Sequencer.timeSignature, clocks: 36, notes: 8))
  }

  static private var tempoEvent: MetaEvent {
    return MetaEvent(.Tempo(bpm: Sequencer.tempo))
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
    guard let events = eventContainer[time] else { return }
    for event in events where event is MetaEvent {
      switch (event as! MetaEvent).data {
        case let .Tempo(bpm): tempo = bpm; Sequencer.setTempo(bpm, automated: true)
        case let .TimeSignature(signature, _, _): timeSignature = signature
        default: break
      }
    }
  }

  private let receptionist: NotificationReceptionist = {
    let r = NotificationReceptionist()
    r.logContext = LogManager.SequencerContext
    return r
  }()

  /** initializeNotificationReceptionist */
  private func initializeNotificationReceptionist() {
    receptionist.observe(Sequencer.Notification.DidToggleRecording, from: Sequencer.self, queue: NSOperationQueue.mainQueue()) {
      [weak self] _ in
      self?.recording = Sequencer.recording
    }
  }

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  - parameter s: MIDISequence
  */
  init(trackChunk: MIDIFileTrackChunk) {
    super.init()
    initializeNotificationReceptionist()
    eventContainer = MIDIEventContainer(events: trackChunk.events.filter(TempoTrack.isTempoTrackEvent))

    if eventContainer.events.filter({
      if let event = $0 as? MetaEvent, case .TimeSignature = event.data { return true } else { return false }
    }).count == 0
    {
      eventContainer.append(TempoTrack.timeSignatureEvent)
    }

    if eventContainer.events.filter({
      if let event = $0 as? MetaEvent, case .Tempo = event.data { return true } else { return false }
    }).count == 0
    {
      eventContainer.append(TempoTrack.tempoEvent)
    }
  }

}
