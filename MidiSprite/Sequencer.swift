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

  // MARK: - Initialization

  private static var initialized = false

  /** 
  Initializes `soundSets` using the bundled sound font files and creates `auditionInstrument` with the first found
  */
  static func initialize() {
    guard !initialized else { return }
    guard let urls = NSBundle.mainBundle().URLsForResourcesWithExtension("sf2", subdirectory: nil) else { return }
    do {
      try urls.forEach { soundSets.append(try SoundSet(url: $0)) }
      guard soundSets.count > 0 else { fatalError("failed to create any sound sets from bundled sf2 files") }
      auditionInstrument = try Instrument(soundSet: soundSets[0], program: UInt8(soundSets[0].presets[0].program), channel: 0)
      Notification.SoundSetsInitialized.post()
    } catch {
      logError(error)
    }
    initialized = true
    logDebug("Sequencer initialized")
  }

  // MARK: - Notifications
  enum Notification: String, NotificationNameType, NotificationType {
    case FileLoaded, FileUnloaded
    case SoundSetsInitialized
    case CurrentTrackDidChange
    case DidStart, DidStop, DidReset
    case DidTurnOnRecording, DidTurnOffRecording
    var object: AnyObject? { return Sequencer.self }
  }

  private static var notificationReceptionist = NotificationReceptionist(callbacks:
    [
      MIDISequence.Notification.Name.TrackRemoved.rawValue :
        (MIDISequence.self, NSOperationQueue.mainQueue(), {
          notification in

          if let track = notification.userInfo?["track"] as? InstrumentTrack where track == Sequencer._currentTrack {
            Sequencer._currentTrack = nil
            if let prev = Sequencer.previousTrack { Sequencer.currentTrack = prev }
          }

        })
    ])
  

  // MARK: - Sequence

  static private var recordableSequence = MIDISequence()
  static private var playbackSequence: MIDISequence?
  static var sequence: MIDISequence { return playbackSequence ?? recordableSequence }


  // MARK: - Time

  /** The MIDI clock */
  static private let clock = MIDIClock(resolution: resolution)
  static private let barBeatTime = BarBeatTime(clockSource: clock.endPoint)
  static private var synchronizedTimes: Set<BarBeatTime> = []

  static var resolution: UInt64 = 480 { didSet { clock.resolution = resolution } }
  static var measure: String  { return barBeatTime.description }

  /** The MIDI clock's end point */
  static var clockSource: MIDIEndpointRef { return clock.endPoint }
  
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

  // MARK: - Files

  static var currentFile: NSURL? {
    didSet {
      guard oldValue != currentFile else { return }
      if let currentFile = currentFile {
        do {
          let midiFile = try MIDIFile(file: currentFile)
          logDebug("midiFile = \(midiFile)")
          playbackSequence = MIDISequence(file: midiFile)
          logDebug("playbackSequence = " + (playbackSequence?.description ?? "nil"))
          Notification.FileLoaded.post()
        } catch {
          logError(error)
          self.currentFile = nil
        }
      } else {
        Notification.FileUnloaded.post()
      }
    }
  }

  // MARK: - Tracks

  private struct State: OptionSetType {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    static let Default          = State(rawValue: 0b0000_0000)
    static let Playing          = State(rawValue: 0b0010_0000)
    static let Recording        = State(rawValue: 0b0100_0000)
    static let HasPlayed        = State(rawValue: 0b1000_0000)
  }

  static private var state = State.Default

  static private(set) var soundSets: [SoundSet] = []

  static private(set) var auditionInstrument: Instrument!

  /** instrumentWithCurrentSettings */
  static func instrumentWithCurrentSettings() -> Instrument {
    return Instrument(instrument: auditionInstrument)
  }

  private static var previousTrack: InstrumentTrack?

  /** The current track in use */
  private static var _currentTrack: InstrumentTrack?

  /**
  currentTrackForState

  - returns: Track?
  */
  private static func currentTrackForState() -> InstrumentTrack {
    if let track = _currentTrack where track.instrument == auditionInstrument { return track }
    do {
      let track = try sequence.newTrackWithInstrument(instrumentWithCurrentSettings())
      _currentTrack = track
      return track
    } catch {
      logError(error)
      fatalError("unable to create a new track when current track has been requested … error: \(error)")
    }
  }

  /** Wraps the private `_currentTrack` so that a new track may be created if the property is `nil` */
  static var currentTrack: InstrumentTrack {
    get {
      guard _currentTrack == nil else { return _currentTrack! }
      do {
        _currentTrack = try sequence.newTrackWithInstrument(instrumentWithCurrentSettings())
        return _currentTrack!
      } catch {
        logError(error)
        fatalError("unable to create a new track when current track has been requested … error: \(error)")
      }
    }
    set {
      guard sequence.instrumentTracks ∋ newValue else { fatalError("setting currentTrack to a track not owned by sequence") }
      guard _currentTrack != newValue else { return }
      previousTrack = _currentTrack
      _currentTrack = newValue
      Notification.CurrentTrackDidChange.post()
    }
  }

  static var currentTrackForAddingNode: InstrumentTrack {
    if _currentTrack?.instrument.settingsEqualTo(auditionInstrument) == true { return _currentTrack! }
    else {
      do {
        _currentTrack = try sequence.newTrackWithInstrument(instrumentWithCurrentSettings())
        return _currentTrack!
      } catch {
        logError(error)
        fatalError("unable to create a new track when current track for adding a node has been requested … error: \(error)")
      }
    }
  }


  // MARK: - Properties used to initialize a new `MIDINode`

  static var currentNoteAttributes = NoteAttributes()

  /** Plays a note using the current note attributes and instrument settings */
  static func auditionCurrentNote() {
    guard let auditionInstrument = auditionInstrument else { return }
    auditionInstrument.playNoteWithAttributes(currentNoteAttributes)
  }

  static var currentTexture = MIDINode.TextureType.allCases[0]

  // MARK: - Transport

  static var playing: Bool { return state ∋ .Playing }

  static var recording: Bool {
    get { return state ∋ .Recording }
    set {
      guard newValue != recording else { return }
      state ⊻= .Recording
      (newValue ? Notification.DidTurnOnRecording : Notification.DidTurnOffRecording).post()
    }
  }

  /** Starts the MIDI clock */
  static func start() {
    guard !playing else { return }
    clock.start()
    state ∪= [.Playing, .HasPlayed]
    Notification.DidStart.post()
  }

  /** Moves the time back to 0 */
  static func reset() {
    if playing { stop() }
    ([barBeatTime] + synchronizedTimes).forEach({time in time.reset()})
    state.remove(.HasPlayed)
    Notification.DidReset.post()
  }

  /** Stops the MIDI clock */
  static func stop() {
    guard playing else { return }
    clock.stop()
    state.remove(.Playing)
    Notification.DidStop.post()
  }

}