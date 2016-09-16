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

  fileprivate(set) static var initialized = false

  /** 
   Initializes `soundSets` using the bundled sound font files and creates `auditionInstrument` with the
   first found
  */
  static func initialize() {
    guard !initialized else { return }

    observeTransport(transport)

    soundSets = [
      EmaxSoundSet(.brassAndWoodwinds),
      EmaxSoundSet(.keyboardsAndSynths),
      EmaxSoundSet(.guitarsAndBasses),
      EmaxSoundSet(.worldInstruments),
      EmaxSoundSet(.drumsAndPercussion),
      EmaxSoundSet(.orchestral)
    ]

    let bundle = Bundle.main
    let exclude = soundSets.map({$0.url})
    guard var urls = bundle.urls(forResourcesWithExtension: "sf2", subdirectory: nil) else { return }
    urls = urls.flatMap({($0 as NSURL).fileReferenceURL()})
    do {
      try urls.filter({!exclude.contains($0)}).forEach { soundSets.append(try SoundSet(url: $0)) }
      guard soundSets.count > 0 else {
        fatalError("failed to create any sound sets from bundled sf2 files")
      }
      let soundSet = soundSets[0]
      let program = UInt8(soundSet.presets[0].program)
      auditionInstrument = try Instrument(track: nil, soundSet: soundSet, program: program, channel: 0)
      Notification.didUpdateAvailableSoundSets.post()
    } catch {
      logError(error)
    }
    initialized = true
    logDebug("Sequencer initialized")
  }

  fileprivate static let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist()
    receptionist.logContext = LogManager.SequencerContext
    receptionist.observe(notification: DocumentManager.Notification.DidChangeDocument,
                    from: DocumentManager.self,
                   queue: OperationQueue.main,
                callback: {_ in Sequencer.sequence = DocumentManager.currentDocument?.sequence})
    return receptionist
    }()

  // MARK: - Sequence

  static fileprivate(set) weak var sequence: Sequence? {
    willSet {
      guard sequence !== newValue else { return }
      Notification.willChangeSequence.post()
    }
    didSet {
      guard sequence !== oldValue else { return }
      Notification.didChangeSequence.post()
      reset()
    }
  }

  // MARK: - Time

  static let partsPerQuarter: UInt = 480
  static var beatsPerBar: UInt { return UInt(timeSignature.beatsPerBar) }

  enum TransportAssignment: Equatable {
    case primary(Transport)
    case auxiliary(Transport)

    var transport: Transport {
      switch self { case .primary(let t): return t; case .auxiliary(let t): return t }
    }
  }

  static let primaryTransport: TransportAssignment = .primary(Transport(name: "primary"))
  static let auxiliaryTransport: TransportAssignment = .auxiliary(Transport(name: "auxiliary"))

  static fileprivate var transportAssignment: TransportAssignment = Sequencer.primaryTransport {
    willSet {
      guard transportAssignment != newValue else { return }
      receptionist.stopObserving(object: transportAssignment.transport)
      let transport = transportAssignment.transport
      if case .primary(_) = transportAssignment {
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
      if case .primary(let transport) = transportAssignment , clockRunning {
        transport.clock.resume()
        clockRunning = false
      }
      Notification.didChangeTransport.post()
    }
  }

  static var transport: Transport { return transportAssignment.transport }

  static fileprivate func observeTransport(_ transport: Transport) {
    receptionist.observe(notification: .didStart, from: transport) {
      Notification.didStart.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(notification: .didPause, from: transport) {
      Notification.didPause.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(notification: .didStop, from: transport) {
      Notification.didStop.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(notification: .didJog, from: transport) {
      Notification.didJog.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(notification: .didBeginJogging, from: transport) {
      Notification.didBeginJogging.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(notification: .didEndJogging, from: transport) {
      Notification.didEndJogging.post(object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(notification: .didReset, from: transport) {
      Notification.didReset.post(object: self, userInfo: $0.userInfo)
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
  static func setTempo(_ tempo: Double, automated: Bool = false) {
    primaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    auxiliaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    if recording && !automated { sequence?.tempo = tempo }
  }

  static var timeSignature: TimeSignature = .fourFour {
    didSet {
      guard timeSignature != oldValue else { return }
      sequence?.timeSignature = timeSignature
      Notification.timeSignatureDidChange.post()
    }
  }

  /**
  setTimeSignature:automated:

  - parameter signature: TimeSignature
  - parameter automated: Bool = false
  */
  static func setTimeSignature(_ signature: TimeSignature, automated: Bool = false) {
    if recording && !automated { sequence?.timeSignature = signature }
  }

  // MARK: - Tracking modes and states

  static fileprivate var clockRunning = false

  static var mode: Mode = .Default {
    willSet {
      guard mode != newValue else { return }
      logDebug("willSet: \(mode.rawValue) ➞ \(newValue.rawValue)")
      switch newValue {
        case .Default: Notification.willExitLoopMode.post()
        case .Loop:    Notification.willEnterLoopMode.post()
      }
    }
    didSet {
      guard mode != oldValue else { return }
      logDebug("didSet: \(oldValue.rawValue) ➞ \(mode.rawValue)")
      switch mode {
        case .Default:
          transportAssignment = primaryTransport
          Notification.didExitLoopMode.post()
        case .Loop:
          transportAssignment = auxiliaryTransport
          Notification.didEnterLoopMode.post()
      }
      Notification.didChangeTransport.post()
    }
  }

  // MARK: - Tracks

  static fileprivate(set) var soundSets: [SoundSetType] = []

  static func soundSetWithURL(_ url: URL) -> SoundSetType? {
    return soundSets.first(where: {$0.url == url})
  }

  static func soundSetWithName(_ name: String) -> SoundSetType? {
    return soundSets.first(where: {$0.fileName == name})
  }

  static fileprivate(set) var auditionInstrument: Instrument!

  /** instrumentWithCurrentSettings */
  static func instrumentWithCurrentSettings() -> Instrument {
    return Instrument(track: nil, instrument: auditionInstrument)
  }

  static weak var soundSetSelectionTarget: Instrument! = Sequencer.auditionInstrument {
    didSet {
      guard oldValue !== soundSetSelectionTarget else { return }
      Notification.soundSetSelectionTargetDidChange.post(object: self, userInfo: [
        .oldSoundSetSelectionTarget: oldValue,
        .newSoundSetSelectionTarget: soundSetSelectionTarget
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
extension Sequencer: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case didStart, didPause, didStop, didReset
    case didToggleRecording
    case didBeginJogging, didEndJogging
    case didJog
    case willEnterLoopMode, willExitLoopMode
    case didEnterLoopMode, didExitLoopMode
    case didChangeTransport
    case willChangeSequence, didChangeSequence
    case soundSetSelectionTargetDidChange
    case didUpdateAvailableSoundSets
    case timeSignatureDidChange
  }

}

func == (lhs: Sequencer.TransportAssignment, rhs: Sequencer.TransportAssignment) -> Bool {
  switch (lhs, rhs) {
    case let (.primary(t1),   .primary(t2))   where t1 === t2: return true
    case let (.auxiliary(t1), .auxiliary(t2)) where t1 === t2: return true
    default:                                                   return false
  }
}
extension Sequencer {
  enum Mode: String { case Default, Loop }
}

// MARK: - Error
extension Sequencer {
  enum Error: String, Swift.Error {
    case InvalidBarBeatTime
    case NotPermitted
  }
}

extension Notification {
  var oldSoundSetSelectionTarget: Instrument? {
    return userInfo?["oldSoundSetSelectionTarget"] as? Instrument
  }
  var newSoundSetSelectionTarget: Instrument? {
    return userInfo?["newSoundSetSelectionTarget"] as? Instrument
  }
}
