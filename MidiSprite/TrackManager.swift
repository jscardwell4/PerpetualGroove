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

  /** The current track in use */
  private static var _currentTrack: Track?

  /** Wraps the private `_currentTrack` so that a new track may be created if the property is `nil` */
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

  /** This should only be set within `initializeWithGraph:`, which should only be called by `AudioManager` */
  static private var graph: AUGraph!

  /** An enumeraton for errors originating with `TrackManager` */
  enum Error: String, ErrorType, CustomStringConvertible {
    case GraphNotInitialized = "The audio graph should already be initialized"
    case NilGraph = "Graph is nil"
  }

  /** Collection of all the tracks in the composition */
  static private(set) var tracks: [Track] = []

  /**
  Sets the `graph` static property for use in methods that require it.

  - parameter graph: AUGraph
  */
  static func initializeWithGraph(g: AUGraph) throws {
    var isInitialized = DarwinBoolean(false)
    try AUGraphIsInitialized(g, &isInitialized) ➤ "\(location()) Failed to check whether graph is initialized"
    guard isInitialized else { throw Error.GraphNotInitialized }
    graph = g
  }

  /**
  Creates a new `Track` attached to a new `Instrument` that uses the specified sound set and program

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

  /** The current time as reported by the MIDI clock */
  static var currentTime: MIDITimeStamp { return clock.clockTimeStamp }

  /** The MIDI clock */
  static private let clock = MIDIClockSource()

  /** The MIDI clock's end point */
  static var clockSource: MIDIEndpointRef { return clock.endPoint }

  /** The tempo used by the MIDI clock in beats per minute */
  static var currentTempo: Double = 120

  /** Starts the MIDI clock */
  static func start() { guard !clock.running else { return }; clock.start(); MSLogDebug("start time = \(currentTime)") }

  /** Stops the MIDI clock */
  static func stop() { guard clock.running else { return }; clock.stop(); MSLogDebug("stop time = \(currentTime)") }

  // TODO: Incorporate 'Beats'
}