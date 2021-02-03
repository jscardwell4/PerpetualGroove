//
//  Controller.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import class AVFoundation.AVAudioUnitSampler
import Combine
import Foundation
import MIDI
import MoonDev
import os
import SoundFont

/// A class for overseeing the creation and playback of a sequence in the MIDI node player.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class Sequencer: ObservableObject
{
  // MARK: Stored Properties

  /// Storing the shared singleton instance.
  private static var _shared: Sequencer? = nil

  /// The shared singleton instance.
  public private(set) static var shared: Sequencer
  {
    get
    {
      if _shared == nil { _shared = Sequencer() }
      return _shared!
    }
    set
    {
      _shared = newValue
    }
  }

  /// The sequencer's node player.
  public internal(set) var player: Player

  /// An instrument made availabe by the sequencer intended for use as a means of
  /// providing auditory feedback while configuring a separate `Instrument` instance.
  @usableFromInline internal private(set) var auditionInstrument: Instrument

  /// A metronome made available by the Controller.shared.
  @usableFromInline internal private(set) var metronome: Metronome

  /// The sequencer's audio engine.
  @usableFromInline internal let audioEngine: AudioEngine

  /// The primary transport used by the Controller.shared.
  public let primaryTransport = Transport(name: "primary")

  /// An additional transport used by the sequencer for loops.
  public let auxiliaryTransport = Transport(name: "auxiliary")

  /// The current assigned transport. The value of this property should always be
  /// identical to either `primaryTransport` or `auxiliaryTransport`.
  @Published public private(set) var transport: Transport

  /// Flag for specifying whether the primary transport's clock was running at the time
  /// of its replacement as the assigned transport.
  private var primaryClockRunning = false

  /// The sequence currently in use by the MIDI node player. Setting this property
  /// resets the transport currently in use.
  @Published public var sequence: Sequence
  {
    willSet
    {
      subscriptions.forEach { $0.cancel() }
      transport.reset()
    }
    didSet
    {
      subscriptions.store
      {
        sequence.trackRemovalPublisher.sink
        {
          self.loops[ObjectIdentifier($0)] = nil
          self.updateNodeDispatch()
        }
        sequence.trackChangePublisher.sink { _ in self.updateNodeDispatch() }
      }

      updateNodeDispatch()
    }
  }

  /// The time signature currently in use. The default is 4/4. Changes to the value of
  /// this property update the time signature for the current sequence.
  public var timeSignature: TimeSignature = .fourFour
  {
    didSet { sequence.timeSignature = timeSignature }
  }

  /// The current sequencer mode. Changing the value of this property affects
  /// which transport is in use and whether event processing is looped or linear.
  @Published public private(set) var mode: Mode = .linear
  {
    didSet
    {
      reconfigure(for: mode)
    }
  }

  /// Collection of active loops.
  private var loops: [ObjectIdentifier: Loop] = [:]

  /// The start time for active loops.
  public private(set) var loopStart: BarBeatTime = .zero

  /// The end time for active loops.
  public private(set) var loopEnd: BarBeatTime = .zero

  /// Sequence subscriptions.
  private var subscriptions: Set<AnyCancellable> = []

  // MARK: Initializer

  /// Initializing with a Sequence
  /// - Parameter sequence: The sequence to load into the sequencer.
  public init(sequence: Sequence = Sequence())
  {
    // Initialize the sequencer's sequence.
    self.sequence = sequence

    // Initialize the audio engine.
    let audioEngine = tryOrDie { try AudioEngine() }

    // Get the first sound font.
    let soundFont = SoundFont.bundledFonts[0]

    // Get the first preset header of the first sound font.
    let header = soundFont.presetHeaders[0]

    // Create a preset for the audition instrument.
    let preset = Instrument.Preset(font: soundFont, header: header, channel: 0)

    // Create the audition instrument.
    auditionInstrument = tryOrDie { try Instrument(preset: preset,
                                                   audioEngine: audioEngine) }

    transport = primaryTransport

    // Create a sampler for the metronome.
    metronome = Metronome(sampler: AVAudioUnitSampler())

    audioEngine.attach(node: metronome.sampler)

    // Start the audio engine.
    tryOrDie { try audioEngine.start() }
    self.audioEngine = audioEngine

    player = Player()
    defer { Sequencer._shared = self }
  }

  // MARK: Computed Properties

  /// The number of beats per bar.
  public var beatsPerBar: UInt { UInt(timeSignature.beatsPerBar) }

  public var time: Time { transport.time }

  /// Accessor for the `clock.beatsPerMinute` property of the sequencer's transports.
  public var tempo: Double
  {
    get { Double(transport.tempo) }
    set
    {
      // Update both the transport's `tempo` property.
      primaryTransport.clock.beatsPerMinute = UInt16(newValue)
      auxiliaryTransport.clock.beatsPerMinute = UInt16(newValue)

      // Update the sequence's `tempo` property if the current transport is recording.
      if transport.isRecording { sequence.tempo = tempo }
    }
  }

  // MARK: Mode Management

  /// Performs any necessary steps to reconfigure the sequencer for the specified mode.
  /// - Parameter mode: The new mode for which to configure the Controller.shared.
  private func reconfigure(for mode: Mode)
  {
    // Manage the transports
    switch mode
    {
      case .linear:
        transport.reset()
        transport = primaryTransport
        if primaryClockRunning { transport.clock.resume(); primaryClockRunning = false }

      case .loop:
        primaryClockRunning = transport.clock.isRunning
        transport.clock.stop()
        transport = auxiliaryTransport
    }
    // Update node dispatch.
    updateNodeDispatch()
  }

  /// Sets `mode` to `.loop` and reconfigures the sequencer appropriately.
  /// - precondition: `mode == .linear`
  public func enterLoopMode()
  {
    precondition(mode == .linear)

    // Fade out any linear nodes.
    player.playerNode?.linearNodes.forEach { $0.fadeOut() }

    // Ensure a blank slate.
    loops.removeAll()

    // Update the mode.
    mode = .loop // Triggers `updateNodeDispatch`
  }

  /// Sets `mode` to `.linear` and reconfigures the sequencer appropriately.
  /// - precondition: `mode == .loop`
  public func exitLoopMode()
  {
    precondition(mode == .loop)

    // Fade out any loop nodes.
    player.playerNode?.loopNodes.forEach { $0.fadeOut(remove: true) }

    // Insert the loops into their respective tracks.
    insertLoops()

    // Reset the loops
    loops.removeAll()
    loopStart = .zero
    loopEnd = .zero

    // Update the mode.
    mode = .linear // Triggers `updateNodeDispatch`
  }

  // MARK: Loop Management

  /// Adds any non-empty loops to their respective tracks.
  private func insertLoops()
  {
    logi("inserting loops: \(self.loops)")

    // Calculate the start and end times
    let currentTime = time.barBeatTime
    let startTime = currentTime + loopStart
    let endTime = currentTime + loopEnd

    // Iterate through non-empty loops to update start/end times and add them to
    // their track.
    for loop in loops.values where !loop.eventContainer.isEmpty
    {
      loop.start = startTime
      loop.end = endTime
      loop.track.add(loop: loop)
    }
  }

  /// Updates `loopStart` with the current value of `time.barBeatTime`.
  public func markLoopStart() { loopStart = time.barBeatTime }

  /// Updates `loopEnd` with the current value of `time.barBeatTime`.
  public func markLoopEnd() { loopEnd = time.barBeatTime }

  /// Removes all loops and resets loop start and end to `.zero`.
  private func resetLoops() { loops.removeAll(); loopStart = .zero; loopEnd = .zero }

  // MARK: Player Management

  /// Configures `player.currentDispatch` appropriately for the current values
  /// of `sequence` and `mode`.
  private func updateNodeDispatch()
  {
    switch mode
    {
      case .linear:
        player.currentDispatch = sequence.instrumentTracks.first
      case .loop:
        guard let track = sequence.currentTrack else { break }
        if let loop = loops[ObjectIdentifier(track)]
        {
          player.currentDispatch = loop
        }
        else
        {
          let loop = Loop(track: track)
          loops[ObjectIdentifier(track)] = loop
          player.currentDispatch = loop
        }
    }
  }
}
