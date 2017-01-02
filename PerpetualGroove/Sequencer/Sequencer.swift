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

// TODO: Review file

/// Manager for MIDI-related aspects of the application
final class Sequencer {

  // MARK: - Initialization

  private(set) static var initialized = false

  /// Initializes `soundSets` using the bundled sound font files and creates `auditionInstrument` with the
  /// first found
  static func initialize() throws {

    guard !initialized else { return }

    receptionist.observe(name: .didChangeDocument,
                         from: DocumentManager.self,
                         queue: OperationQueue.main,
                         callback: {_ in Sequencer.sequence = DocumentManager.currentDocument?.sequence})

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
    auditionInstrument = try Instrument(preset: preset)
    postNotification(name: .didUpdateAvailableSoundSets, object: self, userInfo: nil)

    initialized = true
    Log.debug("Sequencer initialized")
  }

  private static let receptionist = NotificationReceptionist()

  // MARK: - Sequence

  static private(set) weak var sequence: Sequence? {
    willSet {
      guard sequence !== newValue else { return }
      postNotification(name: .willChangeSequence, object: self, userInfo: nil)
    }
    didSet {
      guard sequence !== oldValue else { return }
      postNotification(name: .didChangeSequence, object: self, userInfo: nil)
      transport.reset()
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

  static private var transportAssignment: TransportAssignment = Sequencer.primaryTransport {
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
      if case .primary(let transport) = transportAssignment , clockRunning {
        transport.clock.resume()
        clockRunning = false
      }
      postNotification(name: .didChangeTransport, object: self, userInfo: nil)
    }
  }

  static var transport: Transport { return transportAssignment.transport }

  /// The tempo used by the MIDI clock in beats per minute
  // TODO: Need to make sure the current tempo is set at the beginning of a new sequence
  static var tempo: Double { get { return transport.tempo } set { setTempo(newValue) } }
  static var beatsPerMinute: UInt = 120 { didSet { tempo = Double(beatsPerMinute) } }

  static func setTempo(_ tempo: Double, automated: Bool = false) {
    primaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    auxiliaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    if transport.isRecording && !automated { sequence?.tempo = tempo }
  }

  static var timeSignature: TimeSignature = .fourFour {
    didSet {
      guard timeSignature != oldValue else { return }
      sequence?.timeSignature = timeSignature
      postNotification(name: .timeSignatureDidChange, object: self, userInfo: nil)
    }
  }

  // MARK: - Tracking modes and states

  static private var clockRunning = false

  static var mode: Mode = .default {
    willSet {
      guard mode != newValue else { return }
      Log.debug("willSet: \(mode.rawValue) ➞ \(newValue.rawValue)")
      switch newValue {
        case .default: postNotification(name: .willExitLoopMode, object: self, userInfo: nil)
        case .loop:    postNotification(name: .willEnterLoopMode, object: self, userInfo: nil)
      }
    }
    didSet {
      guard mode != oldValue else { return }
      Log.debug("didSet: \(oldValue.rawValue) ➞ \(mode.rawValue)")
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

  static private(set) var soundSets: [SoundFont] = []
  static private(set) var auditionInstrument: Instrument!

}

// MARK: - Notification
extension Sequencer: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case didToggleRecording
    case willEnterLoopMode, willExitLoopMode
    case didEnterLoopMode, didExitLoopMode
    case didChangeTransport
    case willChangeSequence, didChangeSequence
    case didUpdateAvailableSoundSets
    case timeSignatureDidChange

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }
  }

}

extension Sequencer {
  enum Mode: String { case `default`, loop }
}
