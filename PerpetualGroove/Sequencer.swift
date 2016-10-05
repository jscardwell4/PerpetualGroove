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

/// Manager for MIDI-related aspects of the application
final class Sequencer {

  // MARK: - Initialization

  fileprivate(set) static var initialized = false

  /// Initializes `soundSets` using the bundled sound font files and creates `auditionInstrument` with the
  /// first found
  static func initialize() throws {
    guard !initialized else { return }

    observeTransport(transport)

    soundSets = [
      EmaxSoundSet(.brassAndWoodwinds),
      EmaxSoundSet(.keyboardsAndSynths),
      EmaxSoundSet(.guitarsAndBasses),
      EmaxSoundSet(.worldInstruments),
      EmaxSoundSet(.drumsAndPercussion),
      EmaxSoundSet(.orchestral),
      SoundSet.spyro
    ]

    let soundSet = soundSets[0]
    let presetHeader = soundSet.presetHeaders[0]
    let preset = Instrument.Preset(soundFont: soundSet, presetHeader: presetHeader, channel: UInt8(0))
    auditionInstrument = try Instrument(track: nil, preset: preset)
    postNotification(name: .didUpdateAvailableSoundSets, object: self, userInfo: nil)

    initialized = true
    logDebug("Sequencer initialized")
  }

  fileprivate static let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist()
    receptionist.logContext = LogManager.SequencerContext
    receptionist.observe(name: DocumentManager.NotificationName.didChangeDocument.rawValue,
                    from: DocumentManager.self,
                   queue: OperationQueue.main,
                callback: {_ in Sequencer.sequence = DocumentManager.currentDocument?.sequence})
    return receptionist
    }()

  // MARK: - Sequence

  static fileprivate(set) weak var sequence: Sequence? {
    willSet {
      guard sequence !== newValue else { return }
      postNotification(name: .willChangeSequence, object: self, userInfo: nil)
    }
    didSet {
      guard sequence !== oldValue else { return }
      postNotification(name: .didChangeSequence, object: self, userInfo: nil)
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

    static func == (lhs: TransportAssignment, rhs: TransportAssignment) -> Bool {
      switch (lhs, rhs) {
        case let (.primary(t1),   .primary(t2))   where t1 === t2: return true
        case let (.auxiliary(t1), .auxiliary(t2)) where t1 === t2: return true
        default:                                                   return false
      }
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
      postNotification(name: .didChangeTransport, object: self, userInfo: nil)
    }
  }

  static var transport: Transport { return transportAssignment.transport }

  static fileprivate func observeTransport(_ transport: Transport) {
    receptionist.observe(name: Transport.NotificationName.didStart.rawValue, from: transport) {
      postNotification(name: .didStart, object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(name: Transport.NotificationName.didPause.rawValue, from: transport) {
      postNotification(name: .didPause, object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(name: Transport.NotificationName.didStop.rawValue, from: transport) {
      postNotification(name: .didStop, object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(name: Transport.NotificationName.didJog.rawValue, from: transport) {
      postNotification(name: .didJog, object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(name: Transport.NotificationName.didBeginJogging.rawValue, from: transport) {
      postNotification(name: .didBeginJogging, object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(name: Transport.NotificationName.didEndJogging.rawValue, from: transport) {
      postNotification(name: .didEndJogging, object: self, userInfo: $0.userInfo)
    }
    receptionist.observe(name: Transport.NotificationName.didReset.rawValue, from: transport) {
      postNotification(name: .didReset, object: self, userInfo: $0.userInfo)
    }
  }

  static var time: Time { return transport.time }

//  static let resolution: UInt64 = 480

  static var tickInterval: UInt64 { return transport.clock.tickInterval }
  static var nanosecondsPerBeat: UInt64 { return transport.clock.nanosecondsPerBeat }
  static var microsecondsPerBeat: UInt64 { return transport.clock.microsecondsPerBeat }
  static var secondsPerBeat: Double { return transport.clock.secondsPerBeat }
  static var secondsPerTick: Double { return transport.clock.secondsPerTick }

  /// The tempo used by the MIDI clock in beats per minute
  // TODO: Need to make sure the current tempo is set at the beginning of a new sequence
  static var tempo: Double { get { return transport.tempo } set { setTempo(newValue) } }
  static var beatsPerMinute: UInt = 120 { didSet { tempo = Double(beatsPerMinute) } }

  static func setTempo(_ tempo: Double, automated: Bool = false) {
    primaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    auxiliaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    if recording && !automated { sequence?.tempo = tempo }
  }

  static var timeSignature: TimeSignature = .fourFour {
    didSet {
      guard timeSignature != oldValue else { return }
      sequence?.timeSignature = timeSignature
      postNotification(name: .timeSignatureDidChange, object: self, userInfo: nil)
    }
  }

  static func setTimeSignature(_ signature: TimeSignature, automated: Bool = false) {
    if recording && !automated { sequence?.timeSignature = signature }
  }

  // MARK: - Tracking modes and states

  static fileprivate var clockRunning = false

  static var mode: Mode = .default {
    willSet {
      guard mode != newValue else { return }
      logDebug("willSet: \(mode.rawValue) ➞ \(newValue.rawValue)")
      switch newValue {
        case .default: postNotification(name: .willExitLoopMode, object: self, userInfo: nil)
        case .loop:    postNotification(name: .willEnterLoopMode, object: self, userInfo: nil)
      }
    }
    didSet {
      guard mode != oldValue else { return }
      logDebug("didSet: \(oldValue.rawValue) ➞ \(mode.rawValue)")
      switch mode {
        case .default:
          transportAssignment = primaryTransport
          postNotification(name: .didExitLoopMode, object: self, userInfo: nil)
        case .loop:
          transportAssignment = auxiliaryTransport
          postNotification(name: .didEnterLoopMode, object: self, userInfo: nil)
      }
      postNotification(name: .didChangeTransport, object: self, userInfo: nil)
    }
  }

  // MARK: - Tracks

  static fileprivate(set) var soundSets: [SoundFont] = []

  static func soundSet(withURL url: URL) -> SoundFont? {
    return soundSets.first(where: {$0.url == url})
  }

  static func soundSet(withName name: String) -> SoundFont? {
    return soundSets.first(where: {$0.fileName == name})
  }

  static fileprivate(set) var auditionInstrument: Instrument!

//  static weak var soundSetSelectionTarget: Instrument! = Sequencer.auditionInstrument {
//    didSet {
//      guard oldValue !== soundSetSelectionTarget else { return }
//      postNotification(name: .soundSetSelectionTargetDidChange, object: self, userInfo: [
//        "oldSoundSetSelectionTarget": oldValue,
//        "newSoundSetSelectionTarget": soundSetSelectionTarget
//      ])
//    }
//  }

  // MARK: - Transport

  static var playing:   Bool { return transport.playing   }
  static var paused:    Bool { return transport.paused    }
  static var jogging:   Bool { return transport.jogging   }
  static var recording: Bool { return transport.recording }

  /// Starts the MIDI clock
  static func play() { transport.play() }

  static func toggleRecord() { transport.toggleRecord() }

  static func pause() { transport.pause() }

  /// Moves the time back to 0
  static func reset() { transport.reset() }

  /// Stops the MIDI clock
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
    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }
  }

}

extension Sequencer {
  enum Mode: String { case `default`, loop }
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
