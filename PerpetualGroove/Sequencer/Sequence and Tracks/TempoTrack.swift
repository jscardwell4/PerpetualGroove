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

// TODO: Review file

final class TempoTrack: Track {

  override var name: String { get { return "Tempo" } set {} }

  var recording: Bool = false
  var tempo: Double = Sequencer.tempo {
    didSet {
      guard tempo != oldValue && recording else { return }
      Log.debug("inserting event for tempo \(tempo)")
      add(event: .meta(tempoEvent))
      postNotification(name: .didUpdate, object: self)
    }
  }

  var timeSignature: TimeSignature = Sequencer.timeSignature {
    didSet {
      guard timeSignature != oldValue && recording else { return }
      Log.debug("inserting event for signature \(timeSignature)")
      add(event: .meta(timeSignatureEvent))
      postNotification(name: .didUpdate, object: self)
    }
  }

  fileprivate var timeSignatureEvent: MIDIEvent.MetaEvent {
    return MIDIEvent.MetaEvent(time: Time.current.barBeatTime,
                     data: .timeSignature(signature: timeSignature, clocks: 36, notes: 8))
  }

  fileprivate var tempoEvent: MIDIEvent.MetaEvent {
    return MIDIEvent.MetaEvent(time: Time.current.barBeatTime, data: .tempo(bpm: tempo))
  }

  static func isTempoTrackEvent(_ trackEvent: MIDIEvent) -> Bool {
    guard case .meta(let metaEvent) = trackEvent else { return false }
    switch metaEvent.data {
      case .tempo, .timeSignature, .endOfTrack: return true
      case .sequenceTrackName(let name) where name.lowercased() == "tempo": return true
      default: return false
    }
  }

  override func dispatch(event: MIDIEvent) {
    guard case .meta(let metaEvent) = event else { return }
    switch metaEvent.data {
      case let .tempo(bpm): tempo = bpm; Sequencer.setTempo(bpm, automated: true)
      case let .timeSignature(signature, _, _): timeSignature = signature
      default: break
    }
  }

  /// Initializer for non-playback mode tempo track
  override init(sequence: Sequence) {
    super.init(sequence: sequence)
    add(event: .meta(timeSignatureEvent))
    add(event: .meta(tempoEvent))
  }

  init(sequence: Sequence, trackChunk: MIDIFile.TrackChunk) {
    super.init(sequence: sequence)
    add(events: trackChunk.events.filter(TempoTrack.isTempoTrackEvent))

    if filterEvents({
      if case .meta(let event) = $0, case .timeSignature = event.data { return true } else { return false }
    }).count == 0
    {
      add(event: .meta(timeSignatureEvent))
    }

    if filterEvents({
      if case .meta(let event) = $0, case .tempo = event.data { return true } else { return false }
    }).count == 0
    {
      add(event: .meta(tempoEvent))
    }
  }

}
