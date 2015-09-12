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
    events.append(MetaEvent(time.time, .Tempo(microseconds: Byte4(60_000_000 / tempo))))
  }

  let name = "Tempo"

  var description: String {
    return "TempoTrack {\n\tincludesTempoChange: \(includesTempoChange)\n\tevents: {\n" +
      ",\n".join(events.map({$0.description.indentedBy(8)})) + "\n\t}\n}"
  }

}