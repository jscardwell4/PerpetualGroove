
//  AudioManager.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AVFoundation
import MoonKit
import CoreMIDI
import CoreAudio
import AudioToolbox

final class AudioManager {

  static let queue = dispatch_queue_create("midi", DISPATCH_QUEUE_SERIAL)

  private static var initialized = false

  static private let engine = AVAudioEngine()
  static var mixer: AVAudioMixerNode { return engine.mainMixerNode }

  static private(set) var instruments: [Instrument] = []

  static private(set) var metronome: Metronome!

  /**
  attachNode:forInstrument:

  - parameter node: AVAudioNode
  - parameter instrument: Instrument
  */
  static func attachNode(node: AVAudioNode, forInstrument instrument: Instrument) {
    logVerbose()
    guard instruments ∌ instrument && node.engine == nil else { return }
    engine.attachNode(node)
    engine.connect(node, to: engine.mainMixerNode, format: node.outputFormatForBus(0))
    instruments.append(instrument)
  }

  /** initialize */
  static func initialize() {
    guard !initialized else { return }
    let outputFormat = engine.outputNode.outputFormatForBus(0)
    guard outputFormat.sampleRate != 0 else { fatalError("output disabled (sample rate = 0)") }

    do {
      try configureAudioSession()
      let node = AVAudioUnitSampler()
      engine.attachNode(node)
      engine.connect(node, to: engine.mainMixerNode, format: node.outputFormatForBus(0))
      metronome = try Metronome.init(node: node)
      initialized = true
      logVerbose("AudioManager initialized")
      try start()
    } catch {
      logError(error)
    }

  }

  /** configureAudioSession */
  private static func configureAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    try audioSession.setActive(true)
  }



  /** start */
  static func start() throws { logVerbose(); try engine.start() }

  /** stop */
  static func stop() throws { logVerbose(); engine.stop() }

  static var running: Bool { return engine.running }

  /** reset */
  static func reset() { logVerbose(); engine.reset() }

  /** pause */
  static func pause() { logVerbose(); engine.pause() }
}
