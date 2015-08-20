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

  private static var _currentTrack: Track?
  static var currentTrack: Track {
    get {
      guard _currentTrack == nil else { return _currentTrack! }
      do {
        _currentTrack = try newTrackUsingSoundSet(InstrumentViewController.soundSet,
                                     setToProgram: InstrumentViewController.program)
        return _currentTrack!
      } catch {
        logError(error)
        fatalError("unable to create a new track when current track has been requested")
      }
    }
    set { _currentTrack = newValue }
  }

  static private var graph: AUGraph!

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
    let track = try Track(bus: bus)
    tracks.append(track)
    return track
  }

  static var currentTime: MIDITimeStamp {
    return 0
  }
  
  /** start */
  static func start() throws {

  }

  /** stop */
  static func stop() throws {

  }

}