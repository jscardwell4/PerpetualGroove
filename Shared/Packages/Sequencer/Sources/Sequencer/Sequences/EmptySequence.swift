//
//  EmptySequence.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/16/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//

// MARK: - EmptySequence

/// The `EmptySequence` class is a specialized subclass of `Sequence` that
/// never has any instrument tracks. Used as a standin when `sequencer.sequence == nil`.
@available(iOS 14.0, *)
public final class EmptySequence
{
  // MARK: Stored Properties

  /// The collection of the EmptySequence's tracks excluding the tempo track.
  public var instrumentTracks: [InstrumentTrack] { [] }

  // MARK: Initialization

  /// The default initializer.
  public init() {}

  // MARK: Computed Properties

  public var currentTrackIndex: Int? { get { nil } set {} }
  public var currentTrack: InstrumentTrack? { get { nil } set {} }
  public var tempo: Double { get { 0 } set { } }
  public var tracks: [Track] { [] }
  public var soloTracks: [InstrumentTrack] { [] }

  // MARK: Track Management

  public func exchangeInstrumentTrack(at idx1: Int, with idx2: Int) { }

  public func insertTrack(instrument: Instrument) throws {}

  public func add(track: InstrumentTrack) {}

  public func removeTrack(at index: Int) {}
}

