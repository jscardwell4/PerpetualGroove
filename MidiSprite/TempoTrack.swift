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


final class TempoTrack: MIDITrackType {

  let time = BarBeatTime(clockSource: Sequencer.clockSource)

  let playbackMode: Bool

  private(set) var events: [MIDITrackEvent] = [
    MetaEvent(.TimeSignature(upper: 4, lower: 4, clocks: 36, notes: 8)),
    MetaEvent(.Tempo(microseconds: Byte4(60_000_000 / Sequencer.tempo)))
  ]

  var includesTempoChange: Bool { return events.count > 2 }

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    guard !playbackMode else { return }
    events.append(MetaEvent(time.time, .Tempo(microseconds: Byte4(60_000_000 / tempo))))
  }

  let name = "Tempo"

  /**
  Initializer for non-playback mode tempo track
  */
  init(playbackMode: Bool = false) { self.playbackMode = playbackMode }


  /**
  isTempoTrackEvent:

  - parameter trackEvent: MIDITrackEvent

  - returns: Bool
  */
  static func isTempoTrackEvent(trackEvent: MIDITrackEvent) -> Bool {
    guard let metaEvent = trackEvent as? MetaEvent else { return false }
    switch metaEvent.data {
      case .Tempo, .TimeSignature, .EndOfTrack: return true
      case .SequenceTrackName(let name) where name.lowercaseString == "tempo": return true
      default: return false
    }
  }


  /**
  initWithTrackChunk:

  - parameter trackChunk: MIDIFileTrackChunk
  */
  init(trackChunk: MIDIFileTrackChunk) {
    playbackMode = true
    events = trackChunk.events.filter { TempoTrack.isTempoTrackEvent($0) }
  }

  var description: String {
    var result = "\(self.dynamicType.self) {\n"
    result += "  playbackMode: \(playbackMode)\n"
    result += "  includesTempoChange: \(includesTempoChange)\n"
    result += "  events: {\n" + ",\n".join(events.map({$0.description.indentedBy(8)})) + "\n\t}\n"
    result += "}"
    return result
  }

}