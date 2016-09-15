//
//  Metronome.swift
//  PerpetualGroove
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

  fileprivate let sampler: AVAudioUnitSampler

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
    guard let url = Bundle.main.url(forResource: "Woodblock", withExtension: "wav") else {
      fatalError("Failed to get url for 'Woodblock.wav'")
    }
    try sampler.loadAudioFiles(at: [url])
  }

  fileprivate let callbackKey = "click"

  /**
  click:

  - parameter time: BarBeatTime
  */
  fileprivate func click(_ time: BarBeatTime) {
    guard Sequencer.playing else { return }
    sampler.startNote(time.beat == 1 ? 0x3C : 0x37, withVelocity: 64, onChannel: 0)
  }


  /**
  isAudibleTick:

  - parameter time: BarBeatTime

  - returns: Bool
  */
  fileprivate func isAudibleTick(_ time: BarBeatTime) -> Bool { return time.subbeat  == 1 }

}
