//
//  TempoTrack.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit


final class TempoTrack: TrackType {

  private let time = BarBeatTime(clockSource: Sequencer.clockSource)
  private(set) var events: [TrackEvent] = [
    MetaEvent(deltaTime: .zero, data: .TimeSignature(upper: 4, lower: 4, clocks: 36, notes: 8)),
    MetaEvent(deltaTime: .zero, data: .Tempo(microseconds: Byte4(60_000_000 / Sequencer.tempo)))
  ]

  private(set) var includesTempoChange = false

  /**
  insertTempoChange:

  - parameter tempo: Double
  */
  func insertTempoChange(tempo: Double) {
    events.append(MetaEvent(deltaTime: time.timeStamp, data: .Tempo(microseconds: Byte4(60_000_000 / tempo))))
    includesTempoChange = true
  }

  let label = "Tempo"

  var description: String {
    return "TempoTrack(\(label)) {\n\tincludesTempoChange: \(includesTempoChange)\n\tevents: {\n" +
      ",\n".join(events.map({$0.description.indentedBy(8)})) + "\n\t}\n}"
  }

}