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
   Initializes `soundSets` using the bundled sound font files and creates `auditionInstrument` with the
   first found
  */
  static func initialize() {
    guard !initialized else { return }

    observeTransport(transport)

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
      guard soundSets.count > 0 else {
        fatalError("failed to create any sound sets from bundled sf2 files")
      }
      let soundSet = soundSets[0]
      let program = UInt8(soundSet.presets[0].program)
      auditionInstrument = try Instrument(track: nil, soundSet: soundSet, program: program, channel: 0)
      Notification.DidUpdateAvailableSoundSets.post()
    } catch {
      logError(error)
    }
    initialized = true
    logDebug("Sequencer initialized")
  }

  private static let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist()
    receptionist.logContext = LogManager.SequencerContext
    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument,
                    from: MIDIDocumentManager.self,
                   queue: NSOperationQueue.mainQueue(),
                callback: {_ in Sequencer.sequence = MIDIDocumentManager.currentDocument?.sequence})
    return receptionist
    }()

  // MARK: - Sequence

  static private(set) weak var sequence: Sequence? {
    willSet {
      guard sequence !== newValue else { return }
      Notification.WillChangeSequence.post()
    }
    didSet {
      guard sequence !== oldValue else { return }
      Notification.DidChangeSequence.post()
      reset()
    }
  }

  // MARK: - Time

  static let partsPerQuarter: UInt = 480
  static var beatsPerBar: UInt { return UInt(timeSignature.beatsPerBar) }

  enum TransportAssignment: Equatable {
    case Primary(Transport)
    case Auxiliary(Transport)

    var transport: Transport {
      switch self { case .Primary(let t): return t; case .Auxiliary(let t): return t }
    }
  }

  static let primaryTransport: TransportAssignment = .Primary(Transport(name: "primary"))
  static let auxiliaryTransport: TransportAssignment = .Auxiliary(Transport(name: "auxiliary"))

  static private var transportAssignment: TransportAssignment = Sequencer.primaryTransport {
    willSet {
      guard transportAssignment != newValue else { return }
      receptionist.stopObservingObject(transportAssignment.transport)
      let transport = transportAssignment.transport
      if case .Primary(_) = transportAssignment {
        clockRunning = transport.clock.running
        transport.clock.stop()
      } else {
        transport.clock.stop()
        transport.reset()
        clockRunning = false
      }
    }
    didSet {
      guard transportAssignment != oldValue else { return }
      observeTransport(transportAssignment.transport)
      if case .Primary(let transport) = transportAssignment where clockRunning {
        transport.clock.resume()
        clockRunning = false
      }
      Notification.DidChangeTransport.post()
    }
  }

  static var transport: Transport { return transportAssignment.transport }

  static private func observeTransport(transport: Transport) {
    receptionist.observe(.DidStart, from: transport) {
      Notification.DidStart.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(.DidPause, from: transport) {
      Notification.DidPause.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(.DidStop, from: transport) {
      Notification.DidStop.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(.DidJog, from: transport) {
      Notification.DidJog.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(.DidBeginJogging, from: transport) {
      Notification.DidBeginJogging.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(.DidEndJogging, from: transport) {
      Notification.DidEndJogging.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(.DidReset, from: transport) {
      Notification.DidReset.post(object: self, userInfo: $0.userInfo)
    }
  }

  static var time: Time { return transport.time }

//  static let resolution: UInt64 = 480

  static var tickInterval: UInt64 { return transport.clock.tickInterval }
  static var nanosecondsPerBeat: UInt64 { return transport.clock.nanosecondsPerBeat }
  static var microsecondsPerBeat: UInt64 { return transport.clock.microsecondsPerBeat }
  static var secondsPerBeat: Double { return transport.clock.secondsPerBeat }
  static var secondsPerTick: Double { return transport.clock.secondsPerTick }

  /** The tempo used by the MIDI clock in beats per minute */
  // TODO: Need to make sure the current tempo is set at the beginning of a new sequence
  static var tempo: Double { get { return transport.tempo } set { setTempo(newValue) } }
  static var beatsPerMinute: UInt = 120 { didSet { tempo = Double(beatsPerMinute) } }

  /**
  setTempo:automated:

  - parameter tempo: Double
  - parameter automated: Bool = false
  */
  static func setTempo(tempo: Double, automated: Bool = false) {
    primaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    auxiliaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    if recording && !automated { sequence?.tempo = tempo }
  }

  static var timeSignature: TimeSignature = .FourFour {
    didSet {
      guard timeSignature != oldValue else { return }
      sequence?.timeSignature = timeSignature
      Notification.TimeSignatureDidChange.post()
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

  // MARK: - Tracking modes and states

  static private var clockRunning = false

  static var mode: Mode = .Default {
    willSet {
      guard mode != newValue else { return }
      logDebug("willSet: \(mode.rawValue) ➞ \(newValue.rawValue)")
      switch newValue {
        case .Default: Notification.WillExitLoopMode.post()
        case .Loop:    Notification.WillEnterLoopMode.post()
      }
    }
    didSet {
      guard mode != oldValue else { return }
      logDebug("didSet: \(oldValue.rawValue) ➞ \(mode.rawValue)")
      switch mode {
        case .Default:
          transportAssignment = primaryTransport
          Notification.DidExitLoopMode.post()
        case .Loop:
          transportAssignment = auxiliaryTransport
          Notification.DidEnterLoopMode.post()
      }
      Notification.DidChangeTransport.post()
    }
  }

  // MARK: - Tracks

  static private(set) var soundSets: [SoundSetType] = []

  static func soundSetWithURL(url: NSURL) -> SoundSetType? {
    return soundSets.first({$0.url == url})
  }

  static func soundSetWithName(name: String) -> SoundSetType? {
    return soundSets.first({$0.fileName == name})
  }

  static private(set) var auditionInstrument: Instrument!

  /** instrumentWithCurrentSettings */
  static func instrumentWithCurrentSettings() -> Instrument {
    return Instrument(track: nil, instrument: auditionInstrument)
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

  static var playing:          Bool { return transport.playing   }
  static var paused:           Bool { return transport.paused    }
  static var jogging:          Bool { return transport.jogging   }
  static var recording:        Bool { return transport.recording }

  /** beginJog */
//  static func beginJog() { transport.beginJog() }

  /**
  jog:

  - parameter revolutions: Float
  */
//  static func jog(revolutions: Float) { transport.jog(revolutions) }

  /** endJog */
//  static func endJog() { transport.endJog() }

  /**
  jogToTime:

  - parameter time: BarBeatTime
  */
//  static func jogToTime(t: BarBeatTime) throws { try transport.jogToTime(t) }

  /** Starts the MIDI clock */
  static func play() { transport.play() }

  /** toggleRecord */
  static func toggleRecord() { transport.toggleRecord() }

  /** pause */
  static func pause() { transport.pause() }

  /** Moves the time back to 0 */
  static func reset() { transport.reset() }

  /** Stops the MIDI clock */
  static func stop() { transport.stop() }

}

// MARK: - Notification
extension Sequencer: NotificationDispatchType {

  // MARK: - Notifications
  enum Notification: String, NotificationType, NotificationNameType {
    case DidStart, DidPause, DidStop, DidReset
    case DidToggleRecording
    case DidBeginJogging, DidEndJogging
    case DidJog
    case WillEnterLoopMode, WillExitLoopMode
    case DidEnterLoopMode, DidExitLoopMode
    case DidChangeTransport
    case WillChangeSequence, DidChangeSequence
    case SoundSetSelectionTargetDidChange
    case DidUpdateAvailableSoundSets
    case TimeSignatureDidChange

    var object: AnyObject? { return Sequencer.self }

    enum Key: String, NotificationKeyType {
      case OldSoundSetSelectionTarget, NewSoundSetSelectionTarget
    }
  }

}

func == (lhs: Sequencer.TransportAssignment, rhs: Sequencer.TransportAssignment) -> Bool {
  switch (lhs, rhs) {
    case let (.Primary(t1),   .Primary(t2))   where t1 === t2: return true
    case let (.Auxiliary(t1), .Auxiliary(t2)) where t1 === t2: return true
    default:                                                   return false
  }
}
extension Sequencer {
  enum Mode: String { case Default, Loop }
}

// MARK: - Error
extension Sequencer {
  enum Error: String, ErrorType {
    case InvalidBarBeatTime
    case NotPermitted
  }
}

extension NSNotification {
  var oldSoundSetSelectionTarget: Instrument? {
    return userInfo?[Sequencer.Notification.Key.OldSoundSetSelectionTarget.key] as? Instrument
  }
  var newSoundSetSelectionTarget: Instrument? {
    return userInfo?[Sequencer.Notification.Key.NewSoundSetSelectionTarget.key] as? Instrument
  }
}