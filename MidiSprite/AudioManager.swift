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

  static private var graph = AUGraph()
  static private var ioNode = AUNode()
  static private var ioUnit = AudioUnit()
  static private var mixerNode = AUNode()
  static private(set) var mixer: Mixer?

  private static var initialized = false

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    // Try to configure the audio session
    do {
      try configureAudioSession()
      try configureAudioGraph()
    } catch { logError(error); return }

    MSLogDebug("tracks = \(tracks)")

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

    var mixerUnit = AudioUnit()
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

    mixer = Mixer(mixerUnit: mixerUnit)

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

  static private(set) var tracks: [TrackType] = [MasterTrack.sharedInstance]

  /**
  instrumentWithKey:

  - parameter key: InstrumentKey

  - returns: InstrumentTrack?
  */
  static func trackWithInstrumentWithKey(key: Instrument.Key) -> InstrumentTrack? {
    guard tracks.count > 1, let instrumentTracks = Array(tracks[1..<]) as? [InstrumentTrack] else { return nil }
    return instrumentTracks.filter({ (track: InstrumentTrack) -> Bool in return track.instrument.key == key }).first
  }

  /**
  addTrackWithSoundSet:program:channel:

  - parameter soundSet: SoundSet
  - parameter program: UInt8
  - parameter channel: MusicDeviceGroupID
  
  - returns: The new `InstrumentTrack`

  - throws: Any error encountered while updating the graph with the new component
  */
  static func addTrackWithSoundSet(soundSet: SoundSet,
                           program: UInt8,
                           channel: MusicDeviceGroupID) throws -> InstrumentTrack
  {
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

    let bus = AudioUnitElement(tracks.count)
    status = AUGraphConnectNodeInput(graph, instrumentNode, 0, mixerNode, bus)
    try checkStatus(status, "Failed to connect instrument node to output node")

    status = AUGraphUpdate(graph, nil)
    try checkStatus(status, "Failed to update audio graph")

    print("graph before \(__FUNCTION__)…")
    CAShow(UnsafeMutablePointer<COpaquePointer>(graph))
    print("")

    let instrument = try Instrument(soundSet: soundSet, program: program, channel: channel, unit: instrumentUnit)
    let track = InstrumentTrack(instrument: instrument, bus: bus)
    tracks.append(track)

    MSLogDebug("tracks = \(tracks)")
    return track
  }

}