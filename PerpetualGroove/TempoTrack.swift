//
//  TempoTrack.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreMIDI
import MoonKit

final class TempoTrack: Track {

  override var name: String { get { return "Tempo" } set {} }

  var recording: Bool = false
  var tempo: Double = Sequencer.tempo {
    didSet {
      guard tempo != oldValue && recording else { return }
      logDebug("inserting event for tempo \(tempo)")
      addEvent(.meta(tempoEvent))
      Notification.DidUpdate.post(object: self)
    }
  }

  var timeSignature: TimeSignature = Sequencer.timeSignature {
    didSet {
      guard timeSignature != oldValue && recording else { return }
      logDebug("inserting event for signature \(timeSignature)")
      addEvent(.meta(timeSignatureEvent))
      Notification.DidUpdate.post(object: self)
    }
  }

  fileprivate var timeSignatureEvent: MetaEvent {
    return MetaEvent(Sequencer.time.barBeatTime, .timeSignature(signature: timeSignature, clocks: 36, notes: 8))
  }

  fileprivate var tempoEvent: MetaEvent {
    return MetaEvent(Sequencer.time.barBeatTime, .tempo(bpm: tempo))
  }

  /**
  isTempoTrackEvent:

  - parameter trackEvent: MIDIEvent

  - returns: Bool
  */
  static func isTempoTrackEvent(_ trackEvent: MIDIEvent) -> Bool {
    guard case .meta(let metaEvent) = trackEvent else { return false }
    switch metaEvent.data {
      case .tempo, .timeSignature, .endOfTrack: return true
      case .sequenceTrackName(let name) where name.lowercased() == "tempo": return true
      default: return false
    }
  }

  /**
  dispatchEvent:

  - parameter event: MIDIEvent
  */
  override func dispatchEvent(_ event: MIDIEvent) {
    guard case .meta(let metaEvent) = event else { return }
    switch metaEvent.data {
      case let .tempo(bpm): tempo = bpm; Sequencer.setTempo(bpm, automated: true)
      case let .timeSignature(signature, _, _): timeSignature = signature
      default: break
    }
  }

  /**
  Initializer for non-playback mode tempo track
  
  - parameter s: Sequence
  */
  override init(sequence: Sequence) {
    super.init(sequence: sequence)
    addEvent(.meta(timeSignatureEvent))
    addEvent(.meta(tempoEvent))
  }

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  - parameter s: Sequence
  */
  init(sequence: Sequence, trackChunk: MIDIFileTrackChunk) {
    super.init(sequence: sequence)
    addEvents(trackChunk.events.filter(TempoTrack.isTempoTrackEvent))

    if filterEvents({
      if case .meta(let event) = $0, case .timeSignature = event.data { return true } else { return false }
    }).count == 0
    {
      addEvent(.meta(timeSignatureEvent))
    }

    if filterEvents({
      if case .meta(let event) = $0, case .tempo = event.data { return true } else { return false }
    }).count == 0
    {
      addEvent(.meta(tempoEvent))
    }
  }

}
