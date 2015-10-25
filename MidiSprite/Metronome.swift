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

  private let sampler: AVAudioUnitSampler

  var channel: Byte = 0
  var on = false {
    didSet {
      guard oldValue != on else { return }
      if on { Sequencer.time.registerCallback({ [weak self] in self?.click($0) }, predicate: isAudibleTick, forKey: callbackKey) }
      else { Sequencer.time.removeCallbackForKey(callbackKey) }
    }
  }


  /** initialize */
  init(node: AVAudioUnitSampler) throws {
    sampler = node
    guard let url = NSBundle.mainBundle().URLForResource("Woodblock", withExtension: "wav") else {
      fatalError("Failed to get url for 'Woodblock.wav'")
    }
    try sampler.loadAudioFilesAtURLs([url])
  }

  private let callbackKey = "click"

  /**
  click:

  - parameter time: CABarBeatTime
  */
  private func click(time: CABarBeatTime) {
    guard Sequencer.playing else { return }
    sampler.startNote(time.beat == 1 ? 0x3C : 0x37, withVelocity: 64, onChannel: 0)
  }


  /**
  isAudibleTick:

  - parameter time: CABarBeatTime

  - returns: Bool
  */
  private func isAudibleTick(time: CABarBeatTime) -> Bool { return time.subbeat  == 1 }

}