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
  static private var dynamicsNode = AUNode()
  static private var dynamicsUnit = AudioUnit()
  static private(set) var musicPlayer = MusicPlayer()
  static private(set) var musicSequence = MusicSequence()
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
      try configureMusicPlayer()
    } catch { logError(error); return }

  }

  /** configureMusicPlayer */
  static func configureMusicPlayer() throws {
    try checkStatus(NewMusicPlayer(&musicPlayer), "Failed to create music player")
    try checkStatus(NewMusicSequence(&musicSequence), "Failed to create music sequence")
    try checkStatus(MusicSequenceSetAUGraph(musicSequence, graph), "Failed to set graph from sequence")
    try checkStatus(MusicPlayerSetSequence(musicPlayer, musicSequence), "Failed to set sequence on player")
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
    try checkStatus(NewAUGraph(&graph), "Failed to create new audio graph")

    // Add nodes
    var ioComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                                           componentSubType: kAudioUnitSubType_RemoteIO,
                                                           componentManufacturer: kAudioUnitManufacturer_Apple,
                                                           componentFlags: 0,
                                                           componentFlagsMask: 0)

    try checkStatus(AUGraphAddNode(graph, &ioComponentDescription, &ioNode), "Failed to add io node")

    var dynamicsComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Effect,
                                                                 componentSubType: kAudioUnitSubType_DynamicsProcessor,
                                                                 componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                 componentFlags: 0,
                                                                 componentFlagsMask: 0)
    try checkStatus(AUGraphAddNode(graph, &dynamicsComponentDescription, &dynamicsNode), "Failed to add dynamics node")

    var mixerComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_Mixer,
                                                              componentSubType: kAudioUnitSubType_MultiChannelMixer,
                                                              componentManufacturer: kAudioUnitManufacturer_Apple,
                                                              componentFlags: 0,
                                                              componentFlagsMask: 0)
    try checkStatus(AUGraphAddNode(graph, &mixerComponentDescription, &mixerNode), "Failed to add mixer node to audio graph")

    // Open graph

    try checkStatus(AUGraphOpen(graph), "Failed to open audio graph")

    // Retrieve audio units

    try checkStatus(AUGraphNodeInfo(graph, ioNode, nil, &ioUnit), "Failed to retrieve io unit")
    try checkStatus(AUGraphNodeInfo(graph, dynamicsNode, nil, &dynamicsUnit), "Failed to retrieve dynamics unit")
    try checkStatus(AUGraphNodeInfo(graph, mixerNode, nil, &mixerUnit), "Failed to retrieve mixer unit")

    // Configure units

    var maxFrames = UInt32(4096)
    try checkStatus(AudioUnitSetProperty(ioUnit,
                                         kAudioUnitProperty_MaximumFramesPerSlice,
                                         AudioUnitScope(kAudioUnitScope_Global),
                                         0,
                                         &maxFrames,
                                         UInt32(sizeof(UInt32.self))), "Failed to set max frames per slice on io unit")
    try checkStatus(AudioUnitSetProperty(dynamicsUnit,
                                         kAudioUnitProperty_MaximumFramesPerSlice,
                                         AudioUnitScope(kAudioUnitScope_Global),
                                         0,
                                         &maxFrames,
                                         UInt32(sizeof(UInt32.self))), "Failed to set max frames per slice on dynamics unit")
    try checkStatus(AudioUnitSetProperty(mixerUnit,
                                         kAudioUnitProperty_MaximumFramesPerSlice,
                                         AudioUnitScope(kAudioUnitScope_Global),
                                         0,
                                         &maxFrames,
                                         UInt32(sizeof(UInt32.self))), "Failed to set max frames per slice on mixer unit")
    try checkStatus(AUGraphConnectNodeInput(graph, dynamicsNode, 0, ioNode, 0), "Failed to connect dynamics to io")
    try checkStatus(AUGraphConnectNodeInput(graph, mixerNode, 0, dynamicsNode, 0), "Failed to connect mixer to dynamis")


    // Initialize graph

    try checkStatus(AUGraphInitialize(graph), "Failed to initialize audio graph")

    Mixer.mixerNode = mixerNode
  }

  /** start */
  static func start() throws {
    var running = DarwinBoolean(false)
    try checkStatus(AUGraphIsRunning(graph, &running), "Failed to check running status of audio graph")
    guard !running else { return }
    try checkStatus(AUGraphStart(graph), "Failed to start audio graph")
  }

  /** stop */
  static func stop() throws {
    var running = DarwinBoolean(false)
    try checkStatus(AUGraphIsRunning(graph, &running), "Failed to check running status of audio graph")
    guard running else { return }
    try checkStatus(AUGraphStop(graph), "Failed to stop audio graph")
    try checkStatus(MusicPlayerIsPlaying(musicPlayer, &running), "Failed to check playing status of music player")
    guard running else { return }
    try checkStatus(MusicPlayerStop(musicPlayer), "Failed to stop music player")
  }

}
