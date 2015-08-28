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

final class Bus: Hashable, CustomStringConvertible {

  let element: AudioUnitElement
  let instrument: Instrument

  var volume: Float = 1  {
    didSet {
      volume = (0 ... 1).clampValue(volume)
      do { try Mixer.setVolume(volume, onBus: self) } catch { logError(error) }
    }
  }

  var pan: Float = 0 {
    didSet {
      pan = (-1 ... 1).clampValue(pan)
      do { try Mixer.setPan(pan, onBus: self) } catch { logError(error) }
    }
  }

  init(_ element: AudioUnitElement, _ instrument: Instrument) {
    self.element = element;
    self.instrument = instrument
    do {
      let currentVolume = try Mixer.volumeOnBus(self)
      let currentPan = try Mixer.panOnBus(self)
      volume = currentVolume
      pan = currentPan
    } catch { logError(error) }
  }

  var hashValue: Int { return Int(element) }

  var description: String {
    return "\(self.dynamicType.self) {\n\t" + "\n\t".join(
      "element: \(element)",
      "volume: \(volume)",
      "pan: \(pan)",
      "instrument: \(instrument)".indentedBy(8, preserveFirstLineIndent: true)
    ) +  "\n}"
  }
}

func ==(lhs: Bus, rhs: Bus) -> Bool { return lhs.element == rhs.element }