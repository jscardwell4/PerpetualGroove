//
//  MidiManager.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AVFoundation
import MoonKit

final class MidiManager {

  static let engine = AVAudioEngine()
  static let mixer = engine.mainMixerNode

  static private(set) var instruments: [Instrument] = []

  /**
  connectInstrument:

  - parameter instrument: Instrument
  */
  static func connectInstrument(instrument: Instrument) {
    guard !instrument.connected else { return }
    engine.attachNode(instrument.sampler)
    engine.connect(instrument.sampler, to: mixer, format: nil)
    instruments.append(instrument)
    guard !engine.running else { return }
    do {
      try engine.start()
    } catch {
      logError(error)
    }
  }

  /**
  disconnectInstrument:

  - parameter instrument: Instrument
  */
  static func disconnectInstrument(instrument: Instrument) {
    guard let idx = instruments.indexOf(instrument) else { return }
    engine.disconnectNodeOutput(instrument.sampler)
    instruments.removeAtIndex(idx)
  }

  /** 
  Starts the audio engine if not already running
  
  - throws: Any error encountered starting `engine`
  */
  static func startEngine() throws { guard !engine.running else { return }; try engine.start() }


}