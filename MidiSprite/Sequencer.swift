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
    let _ = notificationReceptionist
    guard let urls = NSBundle.mainBundle().URLsForResourcesWithExtension("sf2", subdirectory: nil) else { return }
    do {
      try urls.forEach { soundSets.append(try SoundSet(url: $0)) }
      guard soundSets.count > 0 else { fatalError("failed to create any sound sets from bundled sf2 files") }
      auditionInstrument = try Instrument(soundSet: soundSets[0], program: UInt8(soundSets[0].presets[0].program), channel: 0)
      Notification.DidInitializeSoundSets.post()
    } catch {
      logError(error)
    }
    sequence = MIDIDocumentManager.currentDocument?.sequence
    initialized = true
    logVerbose("Sequencer initialized")
  }

  // MARK: - Notifications
  enum Notification: String, NotificationType, NotificationNameType {
    case DidInitializeSoundSets
    case DidStart, DidPause, DidStop, DidReset
    case DidTurnOnRecording, DidTurnOffRecording
    case DidBeginJogging, DidEndJogging
    case DidJog

    var object: AnyObject? { return Sequencer.self }

    var userInfo: [Key:AnyObject?]? {
      switch self {
        case .DidStart, .DidPause, .DidStop, .DidReset, .DidBeginJogging, .DidEndJogging, .DidJog:
          var result: [Key:AnyObject?] = [
            Key.Ticks: NSNumber(unsignedLongLong: Sequencer.time.ticks),
            Key.Time: NSValue(barBeatTime: Sequencer.time.time)
          ]
          if case .DidJog = self { result[Key.JogTime] = NSValue(barBeatTime: Sequencer.jogTime) }
          return result
        default: return nil
      }
    }

    enum Key: String, NotificationKeyType { case Time, Ticks, URL, FromTrack, ToTrack, JogTime}
  }

  enum Error: String, ErrorType {
    case InvalidBarBeatTime
    case NotPermitted
  }


  /**
  didChangeCurrentDocument:

  - parameter notification: NSNotification
  */
  private static func didChangeCurrentDocument(notification: NSNotification) {
    logVerbose()
    sequence = MIDIDocumentManager.currentDocument?.sequence
  }

  private static var notificationReceptionist: NotificationReceptionist = {
    let queue = NSOperationQueue.mainQueue()
    typealias Callback = NotificationReceptionist.Callback
    let changeCurrentDocument: Callback = (MIDIDocumentManager.self, queue, Sequencer.didChangeCurrentDocument)
    return NotificationReceptionist(callbacks:[
      MIDIDocumentManager.Notification.DidChangeDocument.rawValue : changeCurrentDocument
      ])
    }()

  // MARK: - Sequence

  static private(set) var sequence: MIDISequence? { didSet { if oldValue != nil { reset() } } }


  // MARK: - Time

  /** The MIDI clock */
  static private let clock = MIDIClock(resolution: resolution)
  static let time = BarBeatTime(clockSource: clock.endPoint)

  static var resolution: UInt64 = 480 { didSet { clock.resolution = resolution } }
  static var measure: String  { return time.description }

  /** The MIDI clock's end point */
  static var clockSource: MIDIEndpointRef { return clock.endPoint }

  static var tickInterval: UInt64 { return clock.tickInterval }
  static var nanosecondsPerBeat: UInt64 { return clock.nanosecondsPerBeat }
  static var microsecondsPerBeat: UInt64 { return clock.microsecondsPerBeat }
  static var secondsPerBeat: Double { return clock.secondsPerBeat }
  static var secondsPerTick: Double { return clock.secondsPerTick }

  /** The tempo used by the MIDI clock in beats per minute */
  // TODO: Need to make sure the current tempo is set at the beginning of a new sequence
  static var tempo: Double {
    get { return Double(clock.beatsPerMinute) }
    set {
      clock.beatsPerMinute = UInt16(newValue)
      if recording { sequence?.insertTempoChange(tempo) }
    }
  }

  // ???: Don't we need to do anything about changes to timeSignature?
  static var timeSignature: SimpleTimeSignature = .FourFour

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

  static private var state: State = []
  
  static private(set) var soundSets: [SoundSet] = []

  static private(set) var auditionInstrument: Instrument!

  /** instrumentWithCurrentSettings */
  static func instrumentWithCurrentSettings() -> Instrument { return Instrument(instrument: auditionInstrument) }

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
  private static var maxTicks: MIDITimeStamp = 0
  private static var jogTime: CABarBeatTime = .start
  private static var ticksPerRevolution: MIDITimeStamp = 0

  /** beginJog */
  static func beginJog() {
    guard !jogging, let sequence = sequence else { return }
    clock.stop()
    jogTime = time.time
    maxTicks = max(jogTime.ticks, sequence.sequenceEnd.ticks)
    ticksPerRevolution = MIDITimeStamp(timeSignature.beatsPerBar) * MIDITimeStamp(time.partsPerQuarter)
    state ⊻= [.Jogging]
    Notification.DidBeginJogging.post()
  }

  /**
  jog:

  - parameter revolutions: Float
  */
  static func jog(revolutions: Float) {
    guard jogging else { logWarning("not jogging"); return }

    let 𝝙ticks = MIDITimeStamp(Double(abs(revolutions)) * Double(ticksPerRevolution))

    let ticks: MIDITimeStamp

    switch revolutions.isSignMinus {
      case true where time.ticks < 𝝙ticks:             	ticks = 0
      case true:                                        ticks = time.ticks - 𝝙ticks
      case false where time.ticks + 𝝙ticks > maxTicks: 	ticks = maxTicks
      default:                                          ticks = time.ticks + 𝝙ticks
    }

    do { try jogToTime(CABarBeatTime(tickValue: ticks)) } catch { logError(error) }
  }

  /** endJog */
  static func endJog() {
    guard jogging && clock.paused else { logWarning("not jogging"); return }
    state ⊻= [.Jogging]
    time.time = jogTime
    maxTicks = 0
    Notification.DidEndJogging.post()
    guard !paused else { return }
    clock.resume()
  }

  /**
  jogToTime:

  - parameter time: CABarBeatTime
  */
  static func jogToTime(t: CABarBeatTime) throws {
    guard jogTime != t else { return }
    guard jogging else { throw Error.NotPermitted }
    guard time.isValidTime(t) else { throw Error.InvalidBarBeatTime }
    jogTime = t
    Notification.DidJog.post()
  }

  /** Starts the MIDI clock */
  static func play() {
    guard !playing else { logWarning("already playing"); return }
    Notification.DidStart.post()
    if paused { clock.resume(); state ⊻= [.Paused, .Playing] }
    else { clock.start(); state ⊻= [.Playing] }
  }

  /** toggleRecord */
  static func toggleRecord() {
    state ⊻= .Recording
    (recording ? Notification.DidTurnOnRecording : Notification.DidTurnOffRecording).post()
  }

  /** pause */
  static func pause() {
    guard playing else { return }
    clock.stop()
    state ⊻= [.Paused, .Playing]
    Notification.DidPause.post()
  }

  /** Moves the time back to 0 */
  static func reset() {
    if playing || paused { stop() }
    clock.reset()
    time.reset {Sequencer.Notification.DidReset.post()}
  }

  /** Stops the MIDI clock */
  static func stop() {
    guard playing || paused else { logWarning("not playing or paused"); return }
    clock.stop()
    state ∖= [.Playing, .Paused]
    Notification.DidStop.post()
  }

}