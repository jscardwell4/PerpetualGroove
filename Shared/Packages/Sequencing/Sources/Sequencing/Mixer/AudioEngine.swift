
//  AudioEngine.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import AVFoundation
import Foundation
import MoonDev

/// Singleton class for managing the application's audio environment and resources.
public final class AudioEngine: ObservableObject
{
  /// The underlying audio engine.
  private let engine = AVAudioEngine()

  /// The mixer node provided by the audio engine.
  internal var mixer: AVAudioMixerNode { engine.mainMixerNode }

  /// Accessors for the volume of the master bus.
  @Published public var masterVolume: Float
  {
    didSet { mixer.volume = (0 ... 1).clamp(masterVolume) }
  }

  /// Accessors for the pan of the master bus.
  @Published public var masterPan: Float
  {
    didSet { mixer.pan = (-1 ... 1).clamp(masterPan) }
  }

  /// Attach an `AVAudioNode` instance.
  ///
  /// - Parameter node: The node to attach.
  public func attach(node: AVAudioNode)
  {
    precondition(node.engine == nil)
    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: node.outputFormat(forBus: 0))
  }

  /// The default initializer simply configures the application's audio session.
  ///
  /// - Throws: Any error thrown configuring the audio session.
  init() throws
  {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSession.Category.playback)
    try audioSession.setActive(true)
    masterVolume = engine.mainMixerNode.volume
    masterPan = engine.mainMixerNode.pan
  }

  /// Starts the audio engine.
  /// - Throws: Any error encountered starting the engine.
  public func start() throws
  {
    guard !isRunning else { return }
    logv("starting audio…")
    try engine.start()
  }

  /// Stops the audio engine.
  public func stop()
  {
    guard isRunning else { return }
    logv("stopping audio…")
    engine.stop()
  }

  /// Whether the audio engine is currently running.
  public var isRunning: Bool { return engine.isRunning }

  /// Resets the audio engine.
  public func reset()
  {
    logv("resetting audio…")
    engine.reset()
  }

  /// Pauses the audio engine.
  public func pause()
  {
    guard engine.isRunning else { return }
    logv("pausing audio…")
    engine.pause()
  }
}
