//
//  Metronome.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import class AVFoundation.AVAudioUnitSampler
import MoonKit

/// A class that plays a note at the start of each beat.
final class Metronome {

  /// The instrument used to produce the metronome's sound.
  private let sampler: AVAudioUnitSampler

  /// The MIDI channel over which the metronome's note events are sent.
  var channel: UInt8 = 0

  /// Whether the metronome is currently producing note events. Changing the value of this property
  /// causes a callback to be registered with or removed from the current instance of `Time` according
  /// to whether the new value is `true` or `false`.
  var isOn = false {

    didSet {

      guard oldValue != isOn else { return }

      switch isOn {

        case true:
          Time.current.register(callback:weakMethod(self, Metronome.click),
                                predicate: Metronome.isAudibleTick,
                                identifier: callbackIdentifier)
        case false:
          Time.current.removePredicatedCallback(with: callbackIdentifier)

      }

    }

  }

  /// Initializing with an audio unit.
  /// - Throws: Any error encountered while attempting to load the metronome's audio file.
  init(sampler: AVAudioUnitSampler) throws {

    /// Initialize the metronome's sampler.
    self.sampler = sampler

    /// Get the url for file to load into the sampler.
    guard let url = Bundle.main.url(forResource: "Woodblock", withExtension: "wav") else {
      fatalError("Failed to get url for 'Woodblock.wav'")
    }

    /// Load the file into the sampler.
    try sampler.loadAudioFiles(at: [url])

  }

  /// Identifier used when registering and removing callbacks.
  private let callbackIdentifier = UUID()

  /// Callback registered with the current instance of `Time`. The predicate with which this callback
  /// is registered ensures that the subbeat of `time` is always `1`. When the current transport is
  /// playing, a note is played using `sampler` with a velocity equal to `64`. If the beat is equal to
  /// `1` then a C4 note is played; otherwise, a G3 note is played.
  private func click(_ time: BarBeatTime) {

    // Check that the transport is playing.
    guard Transport.current.isPlaying else { return }

    // Play a C4 or G3 over `channel` according to whether this is the first beat of the bar.
    sampler.startNote(time.beat == 1 ? 0x3C : 0x37, withVelocity: 64, onChannel: channel)

  }

  /// Returns whether the `subbeat` property of `time` has a value equal to `1`. This method is supplied
  /// when registering callbacks with an instance of `Time` so that the callback is only invoked at the
  /// start of a beat.
  private static func isAudibleTick(_ time: BarBeatTime) -> Bool {
    return time.subbeat == 1
  }

}
