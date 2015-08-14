//
//  MIDIManager.swift
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

final class MIDIManager {

  static let queue = dispatch_queue_create("midi", DISPATCH_QUEUE_SERIAL)

  static private var graph = AUGraph()
  static private var ioNode = AUNode()
  static private var ioUnit = AudioUnit()
  static private var mixerNode = AUNode()
  static private var mixerUnit = AudioUnit()

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

    var mixerComponentDescription = AudioComponentDescription()
    mixerComponentDescription.componentType = kAudioUnitType_Mixer
    mixerComponentDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer
    mixerComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple

    status = AUGraphAddNode(graph, &mixerComponentDescription, &mixerNode)
    try checkStatus(status, "Failed to add mixer node to audio graph")


    // Open graph

    status = AUGraphOpen(graph)
    try checkStatus(status, "Failed to open audio graph")

    // Retrieve audio units

    status = AUGraphNodeInfo(graph, ioNode, nil, &ioUnit)
    try checkStatus(status, "Failed to retrieve io audio unit from audio graph node")

    status = AUGraphNodeInfo(graph, mixerNode, nil, &mixerUnit)
    try checkStatus(status, "Failed to retrieve mixer audio unit from audio graph node")

    // Configure units

    var maxFrames = UInt32(4096)
    status = AudioUnitSetProperty(ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  AudioUnitScope(kAudioUnitScope_Global),
                                  0,
                                  &maxFrames,
                                  UInt32(sizeof(UInt32.self)))
    try checkStatus(status, "Failed to set maximum frames per slice on io unit")

    status = AudioUnitSetProperty(mixerUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  AudioUnitScope(kAudioUnitScope_Global),
                                  0,
                                  &maxFrames,
                                  UInt32(sizeof(UInt32.self)))
    try checkStatus(status, "Failed to set maximum frames per slice on mixer unit")

    // Connect units

    status = AUGraphConnectNodeInput(graph, mixerNode, 0, ioNode, 0)
    try checkStatus(status, "Failed to connect mixer to io")

    // Initialize graph

    status = AUGraphInitialize(graph)
    try checkStatus(status, "Failed to initialize audio graph")

    // Start graph

//    status = AUGraphStart(graph)
//    try checkStatus(status, "Failed to start audio graph")

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

  static private(set) var instruments: [Instrument] = []

  /**
  connectedInstrumentWithSoundSet:program:channel:

  - parameter soundSet: Instrument.SoundSet
  - parameter program: UInt8
  - parameter channel: UInt8

  - returns: Instrument?
  */
  static func connectedInstrumentWithSoundSet(soundSet: SoundSet, program: UInt8, channel: MusicDeviceGroupID) -> Instrument? {
    return instruments.filter({ $0.soundSet == soundSet && $0.program == program && $0.channel == channel }).first
  }

  /**
  connectInstrument:

  - parameter instrument: Instrument
  
  - returns: MusicDeviceComponent
  
  - throws: Any error encountered while updating the graph with the new component
  */
  static func connectInstrument(instrument: Instrument) throws -> MusicDeviceComponent {
    var instrumentComponentDescription = AudioComponentDescription()
    instrumentComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
    instrumentComponentDescription.componentType = kAudioUnitType_MusicDevice
    instrumentComponentDescription.componentSubType = kAudioUnitSubType_Sampler

    var instrumentNode = AUNode()
    var instrumentUnit = MusicDeviceComponent()
    var status = AUGraphAddNode(graph, &instrumentComponentDescription, &instrumentNode)
    try checkStatus(status, "Failed to add instrument node to audio graph")

    status = AUGraphNodeInfo(graph, instrumentNode, nil, &instrumentUnit)
    try checkStatus(status, "Failed to retrieve instrument audio unit from audio graph node")

    status = AUGraphConnectNodeInput(graph, instrumentNode, 0, mixerNode, UInt32(instruments.count))
    try checkStatus(status, "Failed to connect instrument node to output node")

    status = AUGraphUpdate(graph, nil)
    try checkStatus(status, "Failed to update audio graph")

    print("graph before \(__FUNCTION__)…")
    CAShow(UnsafeMutablePointer<COpaquePointer>(graph))
    print("")

    instruments.append(instrument)
    return instrumentUnit
  }

}