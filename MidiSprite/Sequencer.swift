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
      Notification.DidInitializeSoundSets.post()
    } catch {
      logError(error)
    }
    initialized = true
    logDebug("Sequencer initialized")
  }

  // MARK: - Notifications
  enum Notification: String, NotificationNameType, NotificationType {
    case DidLoadFile, DidUnloadFile
    case DidInitializeSoundSets
    case DidChangeCurrentTrack
    case DidStart, DidPause, DidStop, DidReset
    case DidTurnOnRecording, DidTurnOffRecording
    case DidBeginJogging, DidEndJogging
    case DidJog
    var object: AnyObject? { return Sequencer.self }
  }

  enum Error: String, ErrorType {
    case InvalidBarBeatTime
    case NotPermitted
  }

  private static var notificationReceptionist = NotificationReceptionist(callbacks:
    [
      MIDISequence.Notification.Name.DidAddTrack.rawValue :
        (MIDISequence.self, NSOperationQueue.mainQueue(), {
          notification in

          if let track = notification.userInfo?["track"] as? InstrumentTrack where track == Sequencer.currentTrack {
            Sequencer.currentTrack = Sequencer.previousTrack
          }

        })
    ])
  

  // MARK: - Sequence

  static private var _sequence: MIDISequence? { didSet { reset() } }

  static var sequence: MIDISequence {
    guard _sequence == nil else { return _sequence! }
    _sequence = MIDISequence()
    return _sequence!
  }


  // MARK: - Time

  /** The MIDI clock */
  static private let clock = MIDIClock(resolution: resolution)
  static let barBeatTime = BarBeatTime(clockSource: clock.endPoint)

  static var resolution: UInt64 = 480 { didSet { clock.resolution = resolution } }
  static var measure: String  { return barBeatTime.description }

  /** The MIDI clock's end point */
  static var clockSource: MIDIEndpointRef { return clock.endPoint }

  /** The tempo used by the MIDI clock in beats per minute */
  // TODO: Need to make sure the current tempo is set at the beginning of a new sequence and probably turn off continuous
  // updates for slider
  static var tempo: Double {
    get { return Double(clock.beatsPerMinute) }
    set {
      clock.beatsPerMinute = UInt16(newValue)
      if recording { sequence.insertTempoChange(tempo) }
    }
  }

  // ???: Don't we need to do anything about changes to timeSignature?
  static var timeSignature: SimpleTimeSignature = .FourFour

  // MARK: - Files

  static var currentFile: NSURL? {
    didSet {
      logVerbose("didSet… oldValue: \(oldValue); newValue: \(currentFile)")
      guard oldValue != currentFile else { return }
      if let currentFile = currentFile {
        do {
          let midiFile = try MIDIFile(file: currentFile)
          logDebug("midiFile = \(midiFile)")
          _sequence = MIDISequence(file: midiFile)
          logDebug("playbackSequence = " + (_sequence?.description ?? "nil"))
          Notification.DidLoadFile.post()
        } catch {
          logError(error)
          self.currentFile = nil
        }
      } else {
        Notification.DidUnloadFile.post()
      }
    }
  }

  // MARK: - Tracks

  private struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    static let Playing   = State(rawValue: 0b0000_0010)
    static let Recording = State(rawValue: 0b0000_0100)
    static let Paused    = State(rawValue: 0b0001_0000)
    static let Jogging   = State(rawValue: 0b0010_0000)

    var description: String {
      var result = "Sequencer.State { "
      var flagStrings: [String] = []
      if contains(.Playing)   { flagStrings.append("Playing")   }
      if contains(.Recording) { flagStrings.append("Recording") }
      if contains(.Paused)    { flagStrings.append("Paused")    }
      if contains(.Jogging)   { flagStrings.append("Jogging")   }
      result += ", ".join(flagStrings)
      result += " }"
      return result
    }
  }

  static private var state: State = [] {
    didSet {
      let notification: Notification?
      switch state ⊻ oldValue {
        case [.Recording]:        notification = recording ? .DidTurnOnRecording : .DidTurnOffRecording
        case [.Playing, .Paused]: notification = playing   ? .DidStart           : .DidPause
        case [.Playing]:          notification = playing   ? .DidStart           : .DidStop
        case [.Paused]:           notification = paused    ? .DidPause           : .DidStop
        case [.Jogging]:          notification = jogging   ? .DidBeginJogging    : .DidEndJogging
        default:                  notification = nil
      }
      logVerbose("didSet…old state: \(oldValue); new state: \(state); notification: \(notification)")
      notification?.post()
    }
  }

  static private(set) var soundSets: [SoundSet] = []

  static private(set) var auditionInstrument: Instrument!

  /** instrumentWithCurrentSettings */
  static func instrumentWithCurrentSettings() -> Instrument { return Instrument(instrument: auditionInstrument) }

  private static var previousTrack: InstrumentTrack?

  /** Wraps the private `_currentTrack` so that a new track may be created if the property is `nil` */
  static var currentTrack: InstrumentTrack? { didSet { Notification.DidChangeCurrentTrack.post() } }

  // MARK: - Properties used to initialize a new `MIDINode`

  static var currentNoteAttributes = NoteAttributes()

  /** Plays a note using the current note attributes and instrument settings */
  static func auditionCurrentNote() {
    guard let auditionInstrument = auditionInstrument else { return }
    auditionInstrument.playNoteWithAttributes(currentNoteAttributes)
  }

  // MARK: - Transport

  static var playing:   Bool { return state ∋ .Playing   }
  static var paused:    Bool { return state ∋ .Paused    }
  static var jogging:   Bool { return state ∋ .Jogging   }
  static var recording: Bool { return state ∋ .Recording }

  private static var jogStartTimeTicks: UInt64 = 0
  private static var jogMaxTimeTicks:   UInt64 = 0

  /** beginJog */
  static func beginJog() {
    guard !jogging else { return }
    clock.stop()
    jogStartTimeTicks = barBeatTime.time.tickValueWithBeatsPerBar(timeSignature.beatsPerBar)
    jogMaxTimeTicks =   max(jogMaxTimeTicks, sequence.sequenceEnd.tickValueWithBeatsPerBar(timeSignature.beatsPerBar))
    state ⊻= [.Jogging]
  }

  /**
  jog:

  - parameter revolutions: Float
  */
  static func jog(revolutions: Float) {
    guard jogging else { return }

    let beatsPerBar = timeSignature.beatsPerBar
    let ticksPerRevolution = UInt64(beatsPerBar) * UInt64(barBeatTime.partsPerQuarter)
    let isNegative = revolutions.isSignMinus
    let deltaTicks = UInt64(Double(abs(revolutions)) * Double(ticksPerRevolution))
    let pendingTimeTickValue: UInt64

    switch isNegative {
      case true where jogStartTimeTicks < deltaTicks: pendingTimeTickValue = 0
      case true: pendingTimeTickValue = jogStartTimeTicks - deltaTicks
      case false where jogStartTimeTicks + deltaTicks > jogMaxTimeTicks: pendingTimeTickValue = jogMaxTimeTicks
      default: pendingTimeTickValue = jogStartTimeTicks + deltaTicks
    }


    let pendingTime = CABarBeatTime(tickValue: pendingTimeTickValue,
                                    beatsPerBar: beatsPerBar,
                                    subbeatDivisor: barBeatTime.partsPerQuarter)

    do { try jogToTime(pendingTime) } catch { logError(error) }
  }

  /** endJog */
  static func endJog() {
    guard jogging else { return }
    if clock.paused { clock.resume() }
    state ⊻= [.Jogging] }

  /**
  jogToTime:

  - parameter time: CABarBeatTime
  */
  static func jogToTime(time: CABarBeatTime) throws {
    guard barBeatTime.time != time else { return }
    guard jogging else { throw Error.NotPermitted }
    guard barBeatTime.isValidTime(time) else { throw Error.InvalidBarBeatTime }
    barBeatTime.time = time
    Notification.DidJog.post()
  }

  /** Starts the MIDI clock */
  static func play() {
    guard !playing else { return }
    if paused { clock.resume(); state ⊻= [.Paused, .Playing] }
    else { clock.start(); state ⊻= [.Playing] }
  }

  /** toggleRecord */
  static func toggleRecord() { state ⊻= .Recording }

  /** pause */
  static func pause() { guard playing else { return }; clock.stop(); state ⊻= [.Paused, .Playing] }

  /** Moves the time back to 0 */
  static func reset() { stop(); barBeatTime.reset(); clock.reset(); Notification.DidReset.post() }

  /** Stops the MIDI clock */
  static func stop() {
    guard playing || paused else { return }; clock.stop(); state ∖= [.Playing, .Paused]
  }

}