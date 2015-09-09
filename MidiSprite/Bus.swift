//
//  Bus.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import AudioToolbox
import AVFoundation

final class Bus: Hashable, CustomStringConvertible {

  let instrument: Instrument

  var volume: Float {
    get { return instrument.node.volume }
    set { instrument.node.volume = (0 ... 1).clampValue(volume) }
  }

  var pan: Float {
    get { return instrument.node.pan }
    set { instrument.node.pan = (-1 ... 1).clampValue(pan) }
  }

  init(instrument i: Instrument) {
    instrument = i
  }

  var hashValue: Int { return instrument.node.hashValue }

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "volume: \(volume)",
      "pan: \(pan)",
      "instrument: \(instrument)".indentedBy(8, true)
    )
    result +=  "\n}"
    return result
  }
}

func ==(lhs: Bus, rhs: Bus) -> Bool { return lhs.instrument.node == rhs.instrument.node }