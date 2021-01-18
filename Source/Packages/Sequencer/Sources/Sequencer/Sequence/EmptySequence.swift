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
public final class EmptySequence: Sequence
{
  // MARK: Stored Properties

  /// The collection of the EmptySequence's tracks excluding the tempo track.
  public override var instrumentTracks: [InstrumentTrack] { [] }

  // MARK: Initialization

  /// The default initializer.
  public override init() {}

  // MARK: Computed Properties

  public override var currentTrackIndex: Int? { get { nil } set {} }
  public override var currentTrack: InstrumentTrack? { get { nil } set {} }
  public override var tempo: Double { get { 0 } set { } }
  public override var tracks: [Track] { [] }
  public override var soloTracks: [InstrumentTrack] { [] }

  // MARK: Track Management

  public override func exchangeInstrumentTrack(at idx1: Int, with idx2: Int) { }

  public override func insertTrack(instrument: Instrument) throws {}

  public override func add(track: InstrumentTrack) {}

  public override func removeTrack(at index: Int) {}
}

