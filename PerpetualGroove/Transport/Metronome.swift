//
//  Metronome.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import class UIKit.NSDataAsset
import class AVFoundation.AVAudioUnitSampler
import MoonKit

final class Metronome {

  private let sampler: AVAudioUnitSampler

  var channel: UInt8 = 0

  var on = false {
    didSet {
      guard oldValue != on else { return }

      switch on {
        case true:
          Sequencer.time.register(callback:weakMethod(self, Metronome.click),
                                  predicate: Metronome.isAudibleTick,
                                  identifier: callbackIdentifier)
        case false:
          Sequencer.time.removePredicatedCallback(with: callbackIdentifier)
      }
    }
  }


  init(sampler: AVAudioUnitSampler) throws {
    self.sampler = sampler

    guard let url = Bundle.main.url(forResource: "Woodblock", withExtension: "wav") else {
      fatalError("Failed to get url for 'Woodblock.wav'")
    }
    try sampler.loadAudioFiles(at: [url])
  }

  private let callbackIdentifier = UUID()

  private func click(_ time: BarBeatTime) {
    guard Sequencer.playing else { return }
    sampler.startNote(time.beat == 1 ? 0x3C : 0x37, withVelocity: 64, onChannel: 0)
  }

  private static func isAudibleTick(_ time: BarBeatTime) -> Bool {
    return time.subbeat == 1
  }

}
