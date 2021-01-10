
//  AudioEngine.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import AVFoundation
import Foundation
import MoonKit

/// Singleton class for managing the application's audio environment and resources.
public final class AudioEngine
{
  /// The underlying audio engine.
  private let engine = AVAudioEngine()
  
  /// The mixer node provided by the audio engine.
  public var mixer: AVAudioMixerNode { engine.mainMixerNode }
  
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
  }
  
  /// Starts the audio engine.
  /// - Throws: Any error encountered starting the engine.
  public func start() throws { logi("starting audio…"); try engine.start() }
  
  /// Stops the audio engine.
  public func stop() { logi("stopping audio…"); engine.stop() }
  
  /// Whether the audio engine is currently running.
  public var running: Bool { return engine.isRunning }
  
  /// Resets the audio engine.
  public func reset() { logi("resetting audio…"); engine.reset() }
  
  /// Pauses the audio engine.
  public func pause() { logi("pausing audio…"); engine.pause() }
}
