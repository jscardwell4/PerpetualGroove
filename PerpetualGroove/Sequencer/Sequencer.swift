//
//  Sequencer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// A class for overseeing the creation and playback of a sequence in the MIDI node player.
final class Sequencer: NotificationDispatching {

  /// Flag specifying whether `initialize()` has been invoked.
  private(set) static var isInitialized = false

  /// Registers for document change notifications and creates the audition instrument.
  /// - Throws: Any error encountered creating the audition instrument.
  static func initialize() throws {

    // Check that the sequencer is not already initialized.
    guard !isInitialized else { return }

    // Register for document change notifications with a closure that updates `sequence`.
    receptionist.observe(name: .didChangeDocument, from: DocumentManager.self) {
      _ in Sequencer.sequence = DocumentManager.currentDocument?.sequence
    }

    // Get the first sound font.
    let soundFont = soundFonts[0]

    // Get the first preset header of the first sound font.
    let presetHeader = soundFont.presetHeaders[0]

    // Create a preset for the audition instrument.
    let preset = Instrument.Preset(soundFont: soundFont,
                                   presetHeader: presetHeader,
                                   channel: UInt8(0))

    // Create the audition instrument.
    auditionInstrument = try Instrument(preset: preset)

    // Set the initialization flag.
    isInitialized = true

    Log.debug("Sequencer initialized")

  }

  /// Handles registration/reception of document change notifications.
  private static let receptionist = NotificationReceptionist()

  /// The sequence currently in use by the MIDI node player. Changes to the value of this property
  /// cause the sequencer to post `willChangeSequence` and `didChangeSequence` notifications.
  static private(set) weak var sequence: Sequence? {

    willSet {

      // Check that the value will actually change.
      guard sequence !== newValue else { return }

      // Post notification that the sequence will change.
      postNotification(name: .willChangeSequence, object: self)

    }

    didSet {

      // Check that the value has actually changed.
      guard sequence !== oldValue else { return }

      // Post notification that the sequence has changed.
      postNotification(name: .didChangeSequence, object: self)

      // Reset the transport.
      transport.reset()

    }

  }

  /// The number of subbeats per beat.
  static let partsPerQuarter: UInt = 480

  /// The number of beats per bar.
  static var beatsPerBar: UInt { return UInt(timeSignature.beatsPerBar) }

  /// An enumeration of the possible roles for which a transport may be assigned to the sequencer.
  enum TransportAssignment: Equatable {

    /// The primary transport responsible for manipulating the sequence as a whole.
    case primary(Transport)

    /// An additional transport which might by employed for operations like loop creation.
    case auxiliary(Transport)

    /// The transport instance wrapped by the enumerated value.
    var transport: Transport {
      switch self { case .primary(let t): return t; case .auxiliary(let t): return t }
    }

    /// Returns `true` iff the two assignments are the same case with the same transport.
    static func == (lhs: TransportAssignment, rhs: TransportAssignment) -> Bool {
      switch (lhs, rhs) {
        case let (.primary(t1),   .primary(t2))   where t1 === t2: return true
        case let (.auxiliary(t1), .auxiliary(t2)) where t1 === t2: return true
        default:                                                   return false
      }
    }

  }

  /// The primary transport made available by the sequencer.
  static let primaryTransport: TransportAssignment = .primary(Transport(name: "primary"))

  /// An additional transport made available by the sequencer.
  static let auxiliaryTransport: TransportAssignment = .auxiliary(Transport(name: "auxiliary"))

  /// The current assigned transport. The value of this property should always be identical
  /// to either `primaryTransport` or `auxiliaryTransport`. When the value of this property
  /// is changed the sequencer posts a `didChangeTransport` notification.
  static private var transportAssignment: TransportAssignment = Sequencer.primaryTransport {

    willSet {

      // Check that the value will actually change.
      guard transportAssignment != newValue else { return }

      // Handle the old transport according to it's assignment.
      switch transportAssignment {

        case .primary(let transport):
          // Capture whether the clock is running and then make sure it is stopped.
          
          clockRunning = transport.clock.isRunning
          transport.clock.stop()

        case .auxiliary(let transport):
          // Reset the transport and clear the `clockRunning` flag.

          transport.reset()
          clockRunning = false

      }

    }

    didSet {

      // Check that the value has actually changed.
      guard transportAssignment != oldValue else { return }

      // If the new transport is assigned the primary role and its clock was previous running
      // then resume the clock and clear the `clockRunning` flag.
      if case .primary(let transport) = transportAssignment, clockRunning {

        // Resume the clock.
        transport.clock.resume()

        // Clear the flag.
        clockRunning = false

      }

      // Post notification that the transport has changed.
      postNotification(name: .didChangeTransport, object: self)

    }

  }

  /// The `Transport` instance wrapped by the current transport assignment.
  static var transport: Transport { return transportAssignment.transport }

  /// The tempo in use by the current transport. The accessor for this property simply forwards
  /// the value returned by `transport`. The mutator for this property invokes 
  /// `set(tempo:automated:)` where `automated` is `false`.
  /// - TODO: Ensure the tempo is properly set at the beginning of a new sequence.
  static var tempo: Double {
    get { return transport.tempo }
    set { set(tempo: newValue) }
  }

  /// The number of beats per minute.
  static var beatsPerMinute: UInt = 120 { didSet { tempo = Double(beatsPerMinute) } }

  /// Sets the tempo for both the primary and auxiliary transports. If the current transport is
  /// recording and `automated` is `false`, the tempo for the current sequence is also set
  /// generating a new tempo change MIDI event.
  static func set(tempo: Double, automated: Bool = false) {

    // Update both the transport's `tempo` property.
    primaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)
    auxiliaryTransport.transport.clock.beatsPerMinute = UInt16(tempo)

    // Update the sequence's `tempo` property if the current transport is recording and 
    // `automated` is `false`.
    if transport.isRecording && !automated { sequence?.tempo = tempo }

  }

  /// The time signature currently in use. The default is 4/4. Changes to the value of this property
  /// update the time signature for the current sequenced and cause the sequencer to post a
  /// `timeSignatureDidChange` notification.
  static var timeSignature: TimeSignature = .fourFour {

    didSet {

      // Check that the value has actually changed.
      guard timeSignature != oldValue else { return }

      // Update the current sequence's time signature.
      sequence?.timeSignature = timeSignature

      // Post notification that the time signature has changed.
      postNotification(name: .timeSignatureDidChange, object: self)

    }

  }

  /// Flag for specifying whether the primary transport's clock was running at the time of its
  /// replacement as the assigned transport.
  static private var clockRunning = false

  /// The current sequencer mode. Changing the value of this property affects which transport
  /// is assigned and causes the sequencer to post `willExitLoopMode` or `willEnterLoopMode`
  /// and `didExitLoopMode` or `didEnterLoopMode` notifications according to the new value.
  static var mode: Mode = .default {

    willSet {

      // Check that the value will actually change.
      guard mode != newValue else { return }

      Log.debug("willSet: \(mode.rawValue) ➞ \(newValue.rawValue)")

      // Post notification according to the new mode.
      switch newValue {
        case .default: postNotification(name: .willExitLoopMode, object: self)
        case .loop:    postNotification(name: .willEnterLoopMode, object: self)
      }

    }

    didSet {

      // Check that the value has actually changed.
      guard mode != oldValue else { return }

      Log.debug("didSet: \(oldValue.rawValue) ➞ \(mode.rawValue)")

      // Update the transport assignment and post notification according to the new value.
      switch mode {

        case .default:
          transportAssignment = primaryTransport
          postNotification(name: .didExitLoopMode, object: self)

        case .loop:
          transportAssignment = auxiliaryTransport
          postNotification(name: .didEnterLoopMode, object: self)

      }

    }

  }

  /// The sound fonts made available by the sequencer. Changes to the value of this property cause
  /// the sequencer to post a `didUpdateAvailableSoundFonts` notification.
  static private(set) var soundFonts: [SoundFont] = [
      EmaxSoundFont(.brassAndWoodwinds),
      EmaxSoundFont(.keyboardsAndSynths),
      EmaxSoundFont(.guitarsAndBasses),
      EmaxSoundFont(.worldInstruments),
      EmaxSoundFont(.drumsAndPercussion),
      EmaxSoundFont(.orchestral),
      AnySoundFont.spyro
    ] {

    didSet {

      // Post notification that the collection of available sound fonts has updated.
      postNotification(name: .didUpdateAvailableSoundFonts, object: self)

    }

  }

  /// An instrument made availabe by the sequencer intended for use as a means of providing 
  /// auditory feedback while configuring a separate `Instrument` instance.
  static private(set) var auditionInstrument: Instrument!

  /// An enumeration of the names of notifications posted by `Sequencer`.
  enum NotificationName: String, LosslessStringConvertible {

    case willEnterLoopMode, willExitLoopMode
    case didEnterLoopMode, didExitLoopMode
    case didChangeTransport
    case willChangeSequence, didChangeSequence
    case didUpdateAvailableSoundFonts
    case timeSignatureDidChange

    var description: String { return rawValue }

    init?(_ description: String) { self.init(rawValue: description) }

  }

  /// An enumeration for specifying the sequencer's mode of operation.
  enum Mode: String {

    /// The sequencer is manipulating it's current sequence as a whole.
    case `default`

    /// The sequencer is manipulating a subsequence belonging to it's current sequence.
    case loop

  }

}
