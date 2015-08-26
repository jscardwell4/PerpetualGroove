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

  /*
  Time Signature

  FF 58 04 nn dd cc bb

  Time signature is expressed as 4 numbers. nn and dd represent the "numerator" and "denominator" of the signature as notated on sheet music. The denominator is a negative power of 2: 2 = quarter note, 3 = eighth, etc.

  The cc expresses the number of MIDI clocks in a metronome click.

  The bb parameter expresses the number of notated 32nd notes in a MIDI quarter note (24 MIDI clocks). This event allows a program to relate what MIDI thinks of as a quarter, to something entirely different.

  For example, 6/8 time with a metronome click every 3 eighth notes and 24 clocks per quarter note would be the following event:

  FF 58 04 06 03 18 08

  NOTE: If there are no time signature events in a MIDI file, then the time signature is assumed to be 4/4.

  In a format 0 file, the time signatures changes are scattered throughout the one MTrk. In format 1, the very first MTrk should consist of only the time signature (and tempo) events so that it could be read by some device capable of generating a "tempo map". It is best not to place MIDI events in this MTrk. In format 2, each MTrk should begin with at least one initial time signature (and tempo) event.
*/
  // 1111_1111_0101_1000_0000_0100_0100_0010_0011_0000_0000_10000
  // FF 58 04 04 04 30 08
  // 4/4 time with a metronome click every eigth note and 24 clocks per quarter note???

  /*
  source: http://www.mobilefish.com/tutorials/midi/midi_quickguide_specification.html
  MIDI file format:
  MThd and length: 4D 54 68 64 00 00 00 06
  Format (simultaneous tracks): 00 01
  The number of tracks: NN NN
  Time Divison (bits - N = number of ticks per quarter note): 0NNN NNNN NNNN NNNN
  MTrk and length (N = total number of bytes used in track events): 4D 54 72 6B NN NN NN NN
  See delta time and events…
  
  Sequence Number	11111111  (FF)	00000000  (00)	00000010 (02)	data
  Text Event	11111111  (FF)	00000001  (01)	len	text
  Copyright Notice	11111111  (FF)	00000010  (02)	len	text
  Sequence/Track Name	11111111  (FF)	00000011  (03)	len	text
  Instrument Name	11111111  (FF)	00000100  (04)	len	text
  Lyric	11111111  (FF)	00000101  (05)	len	text
  Marker	11111111  (FF)	00000110  (06)	len	text
  Cue Point	11111111  (FF)	00000111  (07)	len	text
  MIDI Channel Prefix	11111111  (FF)	00100000  (20)	00000001  (01)	0000nnnn
  End Of Track	11111111  (FF)	00101111  (2F)	00000000  (00)	[none]
  Set Tempo in microseconds per quarter note	11111111  (FF)	01010001  (51)	00000011  (03)	data
  SMPTE Offset	11111111  (FF)	01010100  (54)	00000101  (05)	data
  Time Signature	11111111  (FF)	01011000  (58)	00000100  (04)	data
  Key Signature	11111111  (FF)	01011001  (59)	00000010  (02)	data
  Sequencer Specific Meta Event	11111111  (FF)	01111111  (7F)	len	data

  */


// MARK: - Manager for MIDI-related aspects of the application
final class Sequencer {

  // MARK: - Private static propertiess

  /** This should only be set within `initializeWithGraph:`, which should only be called by `AudioManager` */
  static private var graph: AUGraph!
  static private(set) var sequence = Sequence()

  /** The MIDI clock */
  static private let clock = MIDIClockSource()
  static private let barBeatTime = BarBeatTime(clockSource: clock.endPoint)
  static private var synchronizedTimes: Set<BarBeatTime> = []

  // MARK: - Public facing properties

  /** The tempo used by the MIDI clock in beats per minute */
  // TODO: Need to make sure the current tempo is set at the beginning of a new sequence and probably turn off continuous
  // updates for slider
  static var tempo: Double {
    get { return clock.beatsPerMinute }
    set {
      clock.beatsPerMinute = newValue
      do { try sequence.insertTempoChange(tempo) } catch { logError(error) }
    }
  }

  /**
  synchronizeTime:

  - parameter time: BarBeatTime
  */
  static func synchronizeTime(time: BarBeatTime) {
    guard time != barBeatTime else { return }
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
  static var currentTime: MIDITimeStamp { return barBeatTime.timestamp }

  static private(set) var resolution: Double {
    get { return clock.resolution} set { clock.resolution = newValue }
  }

  static var measure: String  { return barBeatTime.description }

  // MARK: - Error enumeration

  /** An enumeraton for errors originating with `Sequencer` */
  enum Error: String, ErrorType, CustomStringConvertible {
    case GraphNotInitialized = "The audio graph should already be initialized"
    case NilGraph = "Graph is nil"
    case GraphAlreadySet = "The audio graph has already been set"
  }

  // MARK: - Class setup

  /**
  Sets the `graph` static property for use in methods that require it.

  - parameter graph: AUGraph
  */
  static func initializeWithGraph(g: AUGraph) throws {
    guard case .None = graph else { throw Error.GraphAlreadySet }
    var isInitialized = DarwinBoolean(false)
    try AUGraphIsInitialized(g, &isInitialized) ➤ "\(location()) Failed to check whether graph is initialized"
    guard isInitialized else { throw Error.GraphNotInitialized }
    graph = g
  }

  // MARK: - Creating a new track

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
    return try sequence.newTrackOnBus(bus)
  }

  // MARK: - Starting/stopping and resetting the sequencer

  /** Starts the MIDI clock */
  static func start() {
    guard !clock.running else { return }
    clock.start()
  }

  /** Moves the time back to 0 */
  static func reset() {
    if clock.running { stop() }
    ([barBeatTime] + synchronizedTimes).forEach({time in time.reset()})
  }

  /** Stops the MIDI clock */
  static func stop() {
    guard clock.running else { return }
    clock.stop()
  }

}