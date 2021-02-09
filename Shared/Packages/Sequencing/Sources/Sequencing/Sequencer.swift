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
import SwiftUI

/// A class for overseeing the creation and playback of a sequence in the MIDI node player.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class Sequencer: ObservableObject
{
  @Environment(\.audioEngine) var audioEngine: AudioEngine
  @Environment(\.currentTransport) var currentTransport: Transport
  @Environment(\.linearTransport) var linearTransport: Transport
  @Environment(\.loopTransport) var loopTransport: Transport
  @Environment(\.player) var player: Player

  // MARK: Stored Properties

  /// The sequence currently in use by the MIDI node player. Setting this property
  /// resets the transport currently in use.
  @Published public var sequence: Sequence
  {
    willSet
    {
      subscriptions.forEach { $0.cancel() }
      currentTransport.reset()
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
  public init(sequence: Sequence)
  {
    // Initialize the sequencer's sequence.
    self.sequence = sequence

    // Start the audio engine.
    tryOrDie { try audioEngine.start() }

  }

  // MARK: Mode Management

  /// Performs any necessary steps to reconfigure the sequencer for the specified mode.
  /// - Parameter mode: The new mode for which to configure the Controller.shared.
  private func reconfigure(for mode: Mode)
  {
//    // Manage the transports
//    switch mode
//    {
//      case .linear:
//        currentTransport.reset()
//        if primaryClockRunning { transport.clock.resume(); primaryClockRunning = false }
//
//      case .loop:
//        primaryClockRunning = transport.clock.isRunning
//        transport.clock.stop()
//        transport = auxiliaryTransport
//    }
    // Update node dispatch.
    updateNodeDispatch()
  }

  /// Sets `mode` to `.loop` and reconfigures the sequencer appropriately.
  /// - precondition: `mode == .linear`
  public func enterLoopMode()
  {
    precondition(mode == .linear)

    // Fade out any linear nodes.
    player.playerNode.linearNodes.forEach { $0.coordinator.fadeOut() }

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
    player.playerNode.loopNodes.forEach { $0.coordinator.fadeOut(remove: true) }

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
    let currentTime = currentTransport.time.barBeatTime
    let startTime = currentTime + loopStart
    let endTime = currentTime + loopEnd

    // Iterate through non-empty loops to update start/end times and add them to
    // their track.
    for loop in loops.values where !loop.eventManager.container.isEmpty
    {
      loop.start = startTime
      loop.end = endTime
      loop.track.add(loop: loop)
    }
  }

  /// Updates `loopStart` with the current value of `time.barBeatTime`.
  public func markLoopStart() { loopStart = currentTransport.time.barBeatTime }

  /// Updates `loopEnd` with the current value of `time.barBeatTime`.
  public func markLoopEnd() { loopEnd = currentTransport.time.barBeatTime }

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
        player.currentDispatch = sequence.instrumentTracks.first?.nodeManager
      case .loop:
        guard let track = sequence.currentTrack else { break }
        if let loop = loops[ObjectIdentifier(track)]
        {
          player.currentDispatch = loop.nodeManager
        }
        else
        {
          let loop = Loop(track: track)
          loops[ObjectIdentifier(track)] = loop
          player.currentDispatch = loop.nodeManager
        }
    }
  }
}
