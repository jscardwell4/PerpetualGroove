//
//  Sequencer.swift
//  PerpetualGroove
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

  private(set) static var initialized = false

  /** 
  Initializes `soundSets` using the bundled sound font files and creates `auditionInstrument` with the first found
  */
  static func initialize() {
    globalBackgroundQueue.async {
      guard !initialized else { return }

      let _ = receptionist
      soundSets = [
        EmaxSoundSet(.BrassAndWoodwinds),
        EmaxSoundSet(.KeyboardsAndSynths),
        EmaxSoundSet(.GuitarsAndBasses),
        EmaxSoundSet(.WorldInstruments),
        EmaxSoundSet(.DrumsAndPercussion),
        EmaxSoundSet(.Orchestral)
      ]
      let bundle = NSBundle.mainBundle()
      let exclude = soundSets.map({$0.url})
      guard var urls = bundle.URLsForResourcesWithExtension("sf2", subdirectory: nil) else { return }
      urls = urls.flatMap({$0.fileReferenceURL()})
      do {
        try urls.filter({$0 ∉ exclude}).forEach { soundSets.append(try SoundSet(url: $0)) }
        guard soundSets.count > 0 else { fatalError("failed to create any sound sets from bundled sf2 files") }
        let soundSet = soundSets[0]
        let program = UInt8(soundSet.presets[0].program)
        auditionInstrument = try Instrument(soundSet: soundSet, program: program, channel: 0)
        Notification.DidUpdateAvailableSoundSets.post()
      } catch {
        logError(error)
      }
      sequence = MIDIDocumentManager.currentDocument?.sequence
      initialized = true
      logDebug("Sequencer initialized")
    }
  }

  private static let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist()
    receptionist.logContext = LogManager.SequencerContext
    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument,
                    from: MIDIDocumentManager.self,
                   queue: NSOperationQueue.mainQueue(),
                callback: Sequencer.didChangeDocument)
    return receptionist
    }()

  /**
  didChangeDocument:

  - parameter notification: NSNotification
  */
  private static func didChangeDocument(notification: NSNotification) {
    sequence = MIDIDocumentManager.currentDocument?.sequence
  }

  // MARK: - Sequence

  static private(set) var sequence: Sequence? { didSet { if oldValue != nil { reset() } } }

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
    set { setTempo(newValue) }
  }

  /**
  setTempo:automated:

  - parameter tempo: Double
  - parameter automated: Bool = false
  */
  static func setTempo(tempo: Double, automated: Bool = false) {
    clock.beatsPerMinute = UInt16(tempo)
    if recording && !automated { sequence?.tempo = tempo }
  }

  static var timeSignature: TimeSignature = .FourFour {
    didSet {
      sequence?.timeSignature = timeSignature
    }
  }

  /**
  setTimeSignature:automated:

  - parameter signature: TimeSignature
  - parameter automated: Bool = false
  */
  static func setTimeSignature(signature: TimeSignature, automated: Bool = false) {
    if recording && !automated { sequence?.timeSignature = signature }
  }

  // MARK: - Tracks

  static private var state: State = [] { didSet { logDebug("didSet…old state: \(oldValue); new state: \(state)") } }
  
  static private(set) var soundSets: [SoundSetType] = []

  static private(set) var auditionInstrument: Instrument!

  /** instrumentWithCurrentSettings */
  static func instrumentWithCurrentSettings() -> Instrument { return Instrument(instrument: auditionInstrument) }

  // MARK: - Properties used to initialize a new `MIDINode`

  static var currentNote: MIDINoteGenerator = MIDINote()

  /** Plays a note using the current note attributes and instrument settings */
  static func auditionCurrentNote() {
    guard let auditionInstrument = auditionInstrument else { return }
    auditionInstrument.playNote(currentNote)
  }

  static weak var soundSetSelectionTarget: Instrument! = Sequencer.auditionInstrument {
    didSet {
      guard oldValue !== soundSetSelectionTarget else { return }
      Notification.SoundSetSelectionTargetDidChange.post(object: self, userInfo: [
        .OldSoundSetSelectionTarget: oldValue,
        .NewSoundSetSelectionTarget: soundSetSelectionTarget
      ])
    }
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
  static func toggleRecord() { state ⊻= .Recording; Notification.DidToggleRecording.post() }

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

// MARK: - State
extension Sequencer {

  private struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int

    static let Playing   = State(rawValue: 0b0000_0010)
    static let Recording = State(rawValue: 0b0000_0100)
    static let Paused    = State(rawValue: 0b0001_0000)
    static let Jogging   = State(rawValue: 0b0010_0000)

    var description: String {
      var result = "["
      var flagStrings: [String] = []
      if contains(.Playing)   { flagStrings.append("Playing")   }
      if contains(.Recording) { flagStrings.append("Recording") }
      if contains(.Paused)    { flagStrings.append("Paused")    }
      if contains(.Jogging)   { flagStrings.append("Jogging")   }
      result += ", ".join(flagStrings)
      result += " ]"
      return result
    }
  }

}

// MARK: - Notification
extension Sequencer {

  // MARK: - Notifications
  enum Notification: String, NotificationType, NotificationNameType {
    case DidStart, DidPause, DidStop, DidReset
    case DidToggleRecording
    case DidBeginJogging, DidEndJogging
    case DidJog
    case SoundSetSelectionTargetDidChange
    case DidUpdateAvailableSoundSets

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

    enum Key: String, NotificationKeyType {
      case Time, Ticks, JogTime, OldSoundSetSelectionTarget, NewSoundSetSelectionTarget
    }
  }

}

// MARK: - Error
extension Sequencer {
  enum Error: String, ErrorType {
    case InvalidBarBeatTime
    case NotPermitted
  }
}

extension NSNotification {
  var jogTime: CABarBeatTime? {
    return (userInfo?[Sequencer.Notification.Key.JogTime.key] as? NSValue)?.barBeatTimeValue
  }
  var time: CABarBeatTime? {
    return (userInfo?[Sequencer.Notification.Key.Time.key] as? NSValue)?.barBeatTimeValue
  }
  var ticks: MIDITimeStamp? {
    return (userInfo?[Sequencer.Notification.Key.Ticks.key] as? NSNumber)?.unsignedLongLongValue
  }
  var oldSoundSetSelectionTarget: Instrument? {
    return userInfo?[Sequencer.Notification.Key.OldSoundSetSelectionTarget.key] as? Instrument
  }
  var newSoundSetSelectionTarget: Instrument? {
    return userInfo?[Sequencer.Notification.Key.NewSoundSetSelectionTarget.key] as? Instrument
  }
}