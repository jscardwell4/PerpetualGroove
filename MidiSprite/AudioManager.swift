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

  static private(set) var graph = AUGraph()
  static private var ioNode = AUNode()
  static private var ioUnit = AudioUnit()

  private static var initialized = false

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    // Try to configure the audio session
    do {
      try configureAudioSession()
      try configureAudioGraph()
    } catch { logError(error); return }

  }


  /** configureAudioSession */
  private static func configureAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    try audioSession.setActive(true)
  }

  /** configureAudioGraph */
  private static func configureAudioGraph() throws {
    // Create graph
    var status = NewAUGraph(&graph)
    try checkStatus(status, "Failed to create new audio graph")

    // Add node
    var ioComponentDescription = AudioComponentDescription()
    ioComponentDescription.componentType = kAudioUnitType_Output
    ioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO
    ioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple

    status = AUGraphAddNode(graph, &ioComponentDescription, &ioNode)
    try checkStatus(status, "Failed to add io node to audio graph")

    try Mixer.addNodeToGraph(graph)

    // Open graph

    status = AUGraphOpen(graph)
    try checkStatus(status, "Failed to open audio graph")

    // Retrieve audio units

    status = AUGraphNodeInfo(graph, ioNode, nil, &ioUnit)
    try checkStatus(status, "Failed to retrieve io audio unit from audio graph node")

    // Configure units

    var maxFrames = UInt32(4096)
    status = AudioUnitSetProperty(ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  AudioUnitScope(kAudioUnitScope_Global),
                                  0,
                                  &maxFrames,
                                  UInt32(sizeof(UInt32.self)))
    try checkStatus(status, "Failed to set maximum frames per slice on io unit")

    try Mixer.configureMixerUnitInGraph(graph, outputNode: ioNode)

    // Initialize graph

    status = AUGraphInitialize(graph)
    try checkStatus(status, "Failed to initialize audio graph")

    print("graph after \(__FUNCTION__)…")
    CAShow(UnsafeMutablePointer<COpaquePointer>(graph))
    print("")
  }

  /** start */
  static func start() throws {
    var running = DarwinBoolean(false)
    var status = AUGraphIsRunning(graph, &running)
    try checkStatus(status, "Failed to check running status of audio graph")
    guard !running else { return }
    status = AUGraphStart(graph)
    try checkStatus(status, "Failed to start audio graph")
  }

  /** stop */
  static func stop() throws {
    var running = DarwinBoolean(false)
    var status = AUGraphIsRunning(graph, &running)
    try checkStatus(status, "Failed to check running status of audio graph")
    guard running else { return }
    status = AUGraphStop(graph)
    try checkStatus(status, "Failed to stop audio graph")
  }

}
