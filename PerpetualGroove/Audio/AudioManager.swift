
//  AudioManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AVFoundation
import MoonKit

// TODO: Review file
import CoreMIDI
import CoreAudio
import AudioToolbox

final class AudioManager {

  static let queue = DispatchQueue(label: "midi", attributes: [])

  private(set) static var isInitialized = false

  static private let engine = AVAudioEngine()

  static var mixer: AVAudioMixerNode { return engine.mainMixerNode }

  static private(set) var instruments: [Instrument] = []

  static private(set) var metronome: Metronome!

  static func attach(node: AVAudioNode, for instrument: Instrument) {
    guard isInitialized else { fatalError("attempt to attach node before engine isInitialized") }

    guard !instruments.contains(instrument) && node.engine == nil else { return }

    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))
    instruments.append(instrument)
  }

  static func initialize() throws {
    guard !isInitialized else { return }

    let outputFormat = engine.outputNode.outputFormat(forBus: 0)
    guard outputFormat.sampleRate != 0 else { fatalError("output disabled (sample rate = 0)") }

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    try audioSession.setActive(true)

    let node = AVAudioUnitSampler()
    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))

    metronome = try Metronome(sampler: node)

    isInitialized = true

    Log.debug("AudioManager initialized…")

    try start()
  }

  static func start() throws { Log.debug("starting audio…"); try engine.start() }

  static func stop() throws { Log.debug("stopping audio…"); engine.stop() }

  static var running: Bool { return engine.isRunning }

  static func reset() { Log.debug("resetting audio…"); engine.reset() }

  static func pause() { Log.debug("pausing audio…"); engine.pause() }
}
