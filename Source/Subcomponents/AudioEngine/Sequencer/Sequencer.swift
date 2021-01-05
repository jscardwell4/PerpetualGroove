//
//  Sequencer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MIDI
import MoonKit
import SoundFont

// MARK: - Sequencer

/// A class for overseeing the creation and playback of a sequence in the MIDI node player.
public final class Sequencer {
  // MARK: Stored Properties

  /// The shared singleton instance.
  public static let shared = Sequencer()

  /// An instrument made availabe by the sequencer intended for use as a means of
  /// providing auditory feedback while configuring a separate `Instrument` instance.
  public private(set) var auditionInstrument: Instrument

  /// The primary transport used by the sequencer.
  public let primaryTransport = Transport(name: "primary")

  /// An additional transport used by the sequencer for loops.
  public let auxiliaryTransport = Transport(name: "auxiliary")

  /// The current assigned transport. The value of this property should always be
  /// identical to either `primaryTransport` or `auxiliaryTransport`.
  @Published public private(set) var transport: Transport {
    willSet {
      // Check that the value will actually change.
      guard transport !== newValue else { return }

      if transport === primaryTransport {
        primaryClockRunning = transport.clock.isRunning
        transport.clock.stop()
      } else if transport === auxiliaryTransport {
        transport.reset()
        primaryClockRunning = false
      }
    }

    didSet {
      // Check that the value has actually changed.
      guard transport !== oldValue else { return }

      // If the new transport is assigned the primary role and its clock was previously
      // running then resume the clock and clear the `clockRunning` flag.
      if transport === primaryTransport, primaryClockRunning {
        // Resume the clock.
        transport.clock.resume()

        // Clear the flag.
        primaryClockRunning = false
      }
    }
  }

  /// Flag for specifying whether the primary transport's clock was running at the time
  /// of its replacement as the assigned transport.
  private var primaryClockRunning = false

  /// Handles registration/reception of document change notifications.
  private let receptionist = NotificationReceptionist()

  /// The sequence currently in use by the MIDI node player. Setting this property
  /// resets the transport currently in use.
  @Published public private(set) var sequence: Sequence? {
    didSet { transport.reset() }
  }

  /// The time signature currently in use. The default is 4/4. Changes to the value of
  /// this property update the time signature for the current sequence.
  public var timeSignature: TimeSignature = .fourFour {
    didSet { sequence?.timeSignature = timeSignature }
  }

  /// The current sequencer mode. Changing the value of this property affects
  /// which transport is in use and whether event processing is looped or linear.
  @Published public var mode: Mode = .linear {
    didSet {
      switch mode {
        case .linear: transport = primaryTransport
        case .loop: transport = auxiliaryTransport
      }
    }
  }

  /// The sound fonts made available by the sequencer.
  public let soundFonts: [SoundFont2] = [EmaxSoundFont(.brassAndWoodwinds),
                                         EmaxSoundFont(.keyboardsAndSynths),
                                         EmaxSoundFont(.guitarsAndBasses),
                                         EmaxSoundFont(.worldInstruments),
                                         EmaxSoundFont(.drumsAndPercussion),
                                         EmaxSoundFont(.orchestral),
                                         AnySoundFont.spyro]

  // MARK: Initializer

  /// The private initializer for the singleton.
  private init() {
    // Get the first sound font.
    let soundFont = soundFonts[0]

    // Get the first preset header of the first sound font.
    let presetHeader = soundFont.presetHeaders[0]

    // Create a preset for the audition instrument.
    let preset = Instrument.Preset(soundFont: soundFont,
                                   presetHeader: presetHeader,
                                   channel: UInt8(0))

    // Create the audition instrument.
    auditionInstrument = tryOrDie { try Instrument(preset: preset) }

    transport = primaryTransport
  }

  // MARK: Computed Properties

  /// The number of beats per bar.
  public var beatsPerBar: UInt { UInt(timeSignature.beatsPerBar) }

  public var time: Time { transport.time }

  /// Accessor for the `clock.beatsPerMinute` property of the sequencer's transports.
  public var tempo: Double {
    get { transport.tempo }
    set {
      // Update both the transport's `tempo` property.
      primaryTransport.clock.beatsPerMinute = UInt16(newValue)
      auxiliaryTransport.clock.beatsPerMinute = UInt16(newValue)

      // Update the sequence's `tempo` property if the current transport is recording.
      if transport.isRecording { sequence?.tempo = tempo }
    }
  }
}

public extension Sequencer {
  /// An enumeration for specifying the sequencer's mode of operation.
  enum Mode: String {
    /// The sequencer is manipulating it's current sequence as a whole.
    case linear

    /// The sequencer is manipulating a subsequence belonging to it's current sequence.
    case loop
  }
}
