
//  AudioManager.swift
//  PerpetualGroove
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

  static let queue = DispatchQueue(label: "midi", attributes: [])

  fileprivate(set) static var initialized = false

  static fileprivate let engine = AVAudioEngine()
  static var mixer: AVAudioMixerNode { return engine.mainMixerNode }

  static fileprivate(set) var instruments: [Instrument] = []

  static fileprivate(set) var metronome: Metronome!

  /**
  attachNode:forInstrument:

  - parameter node: AVAudioNode
  - parameter instrument: Instrument
  */
  static func attachNode(_ node: AVAudioNode, forInstrument instrument: Instrument) {
    guard initialized else { fatalError("attempt to attach node before engine initialized") }
    guard !instruments.contains(instrument) && node.engine == nil else { return }
    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))
    instruments.append(instrument)
  }

  /** initialize */
  static func initialize() {
    guard !initialized else { return }
    let outputFormat = engine.outputNode.outputFormat(forBus: 0)
    guard outputFormat.sampleRate != 0 else { fatalError("output disabled (sample rate = 0)") }

    do {
      try configureAudioSession()
      let node = AVAudioUnitSampler()
      engine.attach(node)
      engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))
      metronome = try Metronome.init(node: node)
      initialized = true
      logDebug("AudioManager initialized")
      try start()
    } catch {
      logError(error)
    }
  }

  /** configureAudioSession */
  fileprivate static func configureAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    try audioSession.setActive(true)
  }



  /** start */
  static func start() throws { logDebug("starting audio…"); try engine.start() }

  /** stop */
  static func stop() throws { logDebug("stopping audio…"); engine.stop() }

  static var running: Bool { return engine.isRunning }

  /** reset */
  static func reset() { logDebug("resetting audio…"); engine.reset() }

  /** pause */
  static func pause() { logDebug("pausing audio…"); engine.pause() }
}
