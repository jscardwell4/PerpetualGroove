//
//  Metronome.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreMIDI
import AudioToolbox
import AVFoundation
import MoonKit

final class Metronome {

  static private let samplerNode = AVAudioUnitSampler()
  static private var node = AUNode()
  static private let time = BarBeatTime(clockSource: Sequencer.clockSource)

  static var channel: Byte = 0
  static var on = false {
    didSet {
      guard oldValue != on else { return }
      if on { time.registerCallback(click, predicate: isAudibleTick, forKey: callbackKey) }
      else { time.removeCallbackForKey(callbackKey) }
    }
  }
  
  static private var initialized = false

  /** initialize */
  static func initialize() throws {
    guard let url = NSBundle.mainBundle().URLForResource("Woodblock", withExtension: "wav") else {
      fatalError("Failed to get url for 'Woodblock.wav'")
    }
    try samplerNode.loadInstrumentAtURL(url)
    AudioManager.engine.connect(samplerNode, to: AudioManager.engine.mainMixerNode, format: samplerNode.outputFormatForBus(0))
    initialized = true
    logDebug("Metronome initialized")
  }

  static private let callbackKey = "click"

  /**
  click:

  - parameter time: CABarBeatTime
  */
  static private func click(time: CABarBeatTime) {
    samplerNode.startNote(time.beat == 1 ? 0x3C : 0x37, withVelocity: 64, onChannel: 0)
  }


  /**
  isAudibleTick:

  - parameter time: CABarBeatTime

  - returns: Bool
  */
  static private func isAudibleTick(time: CABarBeatTime) -> Bool { return time.subbeat  == 1 }

}