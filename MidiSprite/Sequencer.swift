//
//  Sequencer.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AudioToolbox
import MoonKit

/** Manager for MIDI-related aspects of the application */
final class Sequencer {

  // MARK: - Private static propertiess

  static private(set) var sequence = Sequence()

  /** The MIDI clock */
  static private let clock = MIDIClock(resolution: resolution)
  static private let barBeatTime = BarBeatTime(clockSource: clock.endPoint)
  static private var synchronizedTimes: Set<BarBeatTime> = []

  // MARK: - Public facing properties

  /** The tempo used by the MIDI clock in beats per minute */
  // TODO: Need to make sure the current tempo is set at the beginning of a new sequence and probably turn off continuous
  // updates for slider
  static var tempo: Double {
    get { return Double(clock.beatsPerMinute) }
    set {
      clock.beatsPerMinute = UInt16(newValue)
      sequence.insertTempoChange(tempo)
    }
  }

  static var timeSignature: SimpleTimeSignature = .FourFour

  /**
  synchronizeTime:

  - parameter time: BarBeatTime
  */
  static func synchronizeTime(time: BarBeatTime) {
    guard time !== barBeatTime else { return }
    guard !synchronizedTimes.contains(time) else { synchronizedTimes.remove(time); return }
    time.synchronizeWithTime(barBeatTime)
    synchronizedTimes.insert(time)
  }

  /** The current track in use */
  private static var _currentTrack: Track?

  /** The MIDI clock's end point */
  static var clockSource: MIDIEndpointRef { return clock.endPoint }
  
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

  /** The current time as reported by the MIDI clock */
//  static var currentTime: MIDITimeStamp { return barBeatTime.timestamp }

  static var resolution: UInt64 = 480 { didSet { clock.resolution = resolution } }

  static var measure: String  { return barBeatTime.description }

  // MARK: - Error enumeration

  /** An enumeraton for errors originating with `Sequencer` */
  enum Error: String, ErrorType, CustomStringConvertible {
    case GraphNotInitialized = "The audio graph should already be initialized"
    case NilGraph = "Graph is nil"
    case GraphAlreadySet = "The audio graph has already been set"
  }

  // MARK: - Creating a new track

  /**
  Creates a new `Track` attached to a new `Instrument` that uses the specified sound set and program

  - parameter soundSet: SoundSet
  - parameter program: Instrument.Program
  
  - returns: The new `Track`
  */
  static func newTrackUsingSoundSet(soundSet: SoundSet, setToProgram program: Instrument.Program) throws -> Track {
    let instrument = try Instrument(soundSet: soundSet)
    let bus = try Mixer.connectInstrument(instrument)
    if program != 0 { try instrument.setProgram(program, onChannel: 0) }
    return try sequence.newTrackOnBus(bus)
  }

  // MARK: - Starting/stopping and resetting the sequencer

  static var playing: Bool { return clock.running }

  /** Starts the MIDI clock */
  static func start() { guard !playing else { return }; clock.start() }

  /** Moves the time back to 0 */
  static func reset() { if playing { stop() }; ([barBeatTime] + synchronizedTimes).forEach({time in time.reset()}) }

  /** Stops the MIDI clock */
  static func stop() { guard playing else { return }; clock.stop() }

}