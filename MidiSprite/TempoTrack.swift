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

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    guard recording else { return }
    eventContainer.append(MetaEvent(Sequencer.time.time, .Tempo(bpm: tempo)))
  }

  /**
  insertTimeSignature:

  - parameter signature: TimeSignature
  */
  func insertTimeSignature(signature: TimeSignature) {
    guard recording else { return }
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
    guard let events = eventMap.eventsForTime(time) else { return }
    for event in events where event is MetaEvent {
      switch (event as! MetaEvent).data {
        case let .Tempo(bpm): tempo = bpm; Sequencer.setTempo(bpm, automated: true)
        case let .TimeSignature(signature, _, _): timeSignature = signature
        default: break
      }
    }
  }

  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  - parameter s: MIDISequence
  */
  init(trackChunk: MIDIFileTrackChunk) {
    super.init()
    eventContainer = MIDIEventContainer(events: trackChunk.events.filter(TempoTrack.isTempoTrackEvent))

    if !hasTimeSignatureEvent { eventContainer.insert(TempoTrack.timeSignatureEvent, atIndex: 0) }
    if !hasTempoEvent { eventContainer.insert(TempoTrack.tempoEvent, atIndex: 1) }

    eventMap.insert(eventContainer.events)

    Sequencer.time.registerCallback({ [weak self] in self?.dispatchEventsForTime($0) },
                           forTimes: eventMap.times,
                          forObject: self)
  }

}
