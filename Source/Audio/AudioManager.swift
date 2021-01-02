
//  AudioManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AVFoundation
import MoonKit

/// Singleton class for managing the application's audio environment and resources.
final class AudioManager {

  /// Flag indicating whether `initialize()` has been invoked.
  private(set) static var isInitialized = false

  /// The application's audio engine.
  static private let engine = AVAudioEngine()

  /// The mixer node provided by the audio engine.
  static var mixer: AVAudioMixerNode { return engine.mainMixerNode }

  /// The collection of instruments for which a node has been connected to the mixer.
  static private(set) var instruments: [Instrument] = []

  /// The `Metronome` instance attached to the mixer.
  static private(set) var metronome: Metronome!

  /// Attachs `node` to the audio engine and connects it to the mixer with output bus `0`.
  /// - Requires: `AudioManager` has been initialized.
  static func attach(node: AVAudioNode, for instrument: Instrument) {

    // Check that the audio engine has been intialized.
    guard isInitialized else { fatalError("attempt to attach node before engine isInitialized") }

    // Check that the node has no engine and the instrument is not connected.
    guard !instruments.contains(instrument) && node.engine == nil else { return }

    // Attach the node to the engine.
    engine.attach(node)

    // Connect the node to the engine's mixer.
    engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))

    // Append the instrument to the collection of connected instruments.
    instruments.append(instrument)

  }

  /// Configures the audio session. Configures and starts the audio engine. Creates and connects 
  /// the metronome. If the audio manager has already been initialized then this method does nothing.
  /// - Requires: Audio output has not been disabled, which is detected by check the audio engine's output
  ///             node for a sample rate of `0`.
  /// - Throws: `Error.audioOutputDisabled`, any error encountered while configuring the audio engine,
  ///            audio session, or metronome.
  static func initialize() throws {

    // Check that the audio manager has not already been initialized.
    guard !isInitialized else { return }

    // Check whether audio output has been disabled.
    guard engine.outputNode.outputFormat(forBus: 0).sampleRate != 0 else {
      throw Error.audioOutputDisabled
    }

    // Get the shared audio session.
    let audioSession = AVAudioSession.sharedInstance()

    // Set the category to allow playback.
    try audioSession.setCategory(AVAudioSession.Category.playback)

    // Active the session.
    try audioSession.setActive(true)

    // Create a sampler for the metronome.
    let node = AVAudioUnitSampler()

    // Attach the sampler to the audio engine.
    engine.attach(node)

    // Connect the sampler to the mixer.
    engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))

    // Create the metronome using the attached and connected sampler.
    metronome = try Metronome(sampler: node)

    // Set the initialization flag.
    isInitialized = true

    // Start the audio engine.
    try start()

    logi("AudioManager initialized…")

  }

  /// Starts the audio engine.
  /// - Throws: Any error encountered starting the engine.
  static func start() throws {

    logi("starting audio…")

    // Start the engine.
    try engine.start()

  }

  /// Stops the audio engine.
  static func stop() {

    logi("stopping audio…")

    // Stop the engine.
    engine.stop()

  }

  /// Whether the audio engine is currently running.
  static var running: Bool { return engine.isRunning }

  /// Resets the audio engine.
  static func reset() {

    logi("resetting audio…")

    // Reset the audio engine.
    engine.reset()

  }

  /// Pauses the audio engine.
  static func pause() {

    logi("pausing audio…")

    // Pause the audio engine.
    engine.pause()

  }

  /// An enumeration of the possible errors thrown by `AudioManager`.
  enum Error: String, Swift.Error, CustomStringConvertible {

    case audioOutputDisabled = "Output disabled (sample rate = 0)"

  }

}
