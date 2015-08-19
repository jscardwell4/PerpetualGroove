//
//  TrackManager.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AudioToolbox
import MoonKit

final class TrackManager {

  static var currentTrack: Track?

  static private var graph: AUGraph!
  static private var musicPlayer = MusicPlayer()
  static private var musicSequence = MusicSequence()

  enum Error: String, ErrorType, CustomStringConvertible {
    case GraphAlreadyExists = "The mixer already has a graph"
    case GraphNotInitialized = "The audio graph should already be initialized"
    case NilGraph = "Graph is nil"

    var description: String { return rawValue }
  }

  static private(set) var tracks: [Track] = []

  /**
  initializeWithGraph:

  - parameter graph: AUGraph
  */
  static func initializeWithGraph(g: AUGraph) throws {
    var isInitialized = DarwinBoolean(false)
    try AUGraphIsInitialized(g, &isInitialized) ➤ "\(location()) Failed to check whether graph is initialized"
    guard isInitialized else { throw Error.GraphNotInitialized }

    try NewMusicPlayer(&musicPlayer) ➤ "\(location()) Failed to create music player"
    try NewMusicSequence(&musicSequence) ➤ "\(location()) Failed to create music sequence"
    try MusicSequenceSetAUGraph(musicSequence, g) ➤ "\(location()) Failed to set graph from sequence"
    try MusicPlayerSetSequence(musicPlayer, musicSequence) ➤ "\(location()) Failed to set sequence on player"
    graph = g
  }

  /**
  newTrackUsingSoundSet:setToProgram:

  - parameter soundSet: SoundSet
  - parameter program: Instrument.Program
  
  - returns: The new `Track`
  */
  static func newTrackUsingSoundSet(soundSet: SoundSet, setToProgram program: Instrument.Program) throws -> Track {
    guard let graph = graph else { throw Error.NilGraph }
    let instrument = try Instrument(graph: graph, soundSet: soundSet)
    let bus = try Mixer.connectInstrument(instrument)
    if program != 0 { try instrument.setProgram(program, onChannel: 0) }

    var musicTrack = MusicTrack()
    try MusicSequenceNewTrack(musicSequence, &musicTrack) ➤ "Failed to create new track in sequence"
    try MusicTrackSetDestNode(musicTrack, instrument.node) ➤ "Failed to set destination node for new track"

    let track = Track(bus: bus, track: musicTrack)
    tracks.append(track)
    return track
  }

  static var playing: Bool {
    var playing = DarwinBoolean(false)
    do {
      try MusicPlayerIsPlaying(musicPlayer, &playing) ➤ "\(location()) Failed to check playing status of music player"
      return Bool(playing)
    } catch { logError(error); return false }

  }

  static var currentTime: MusicTimeStamp {
    do {
      var timestamp = MusicTimeStamp(0)
      try MusicPlayerGetTime(musicPlayer, &timestamp) ➤ "\(location()) Failed to get time from player"
      return timestamp
    } catch {
      logError(error)
      return 0
    }
  }
  
  /** start */
  static func start() throws {
    // ???: Should we add a non-event to sequence just to start player?
    try MusicPlayerStart(musicPlayer) ➤ "\(location()) Failed to start playing music player"
  }

  /** stop */
  static func stop() throws {
    var playing = DarwinBoolean(false)
    try MusicPlayerIsPlaying(musicPlayer, &playing) ➤ "\(location()) Failed to check playing status of music player"
    guard playing else { return }
    try MusicPlayerStop(musicPlayer) ➤ "\(location()) Failed to stop music player"
  }

}