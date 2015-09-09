//
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

  static let engine = AVAudioEngine()

  /** initialize */
  static func initialize() {
    guard !initialized else { return }
    let outputFormat = engine.outputNode.outputFormatForBus(0)
    guard outputFormat.sampleRate != 0 else { fatalError("output disabled (sample rate = 0)") }

    do {
      try configureAudioSession()
      try Metronome.initialize()
      initialized = true
      logDebug("AudioManager initialized")
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
  static func start() throws {
    try engine.start()
  }

  /** stop */
  static func stop() throws {
    engine.stop()
  }

}
