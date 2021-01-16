//
//  MixerModel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/15/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import MoonDev

final class MixerModel: ObservableObject
{
  /// The total number of tracks held by `sequence` or `0` if `sequence == nil`.
  @Published var trackCount: Int

  /// The sequence being modeled.
  @Published var sequence: Sequence
  {
    willSet
    {
      sequenceSubscriptions.forEach { $0.cancel() }
      trackCount = 0
    }
    didSet
    {
      trackCount = sequence.instrumentTracks.count
      sequenceSubscriptions.store
      {
        sequence.trackAdditionPublisher.sink { _ in self.trackCount += 1 }
        sequence.trackRemovalPublisher.sink { _ in self.trackCount -= 1 }
      }
    }
  }

  /// The set of subscriptions held by the model for `sequence`.
  private var sequenceSubscriptions: Set<AnyCancellable> = []

  private var sequencerSubscription: Cancellable?

  /// Initializing without a sequence.
  init()
  {
    trackCount = 0
    sequence = EmptySequence()
    sequencerSubscription = sequencer.$sequence.sink
    {
      if let sequence = $0 { self.sequence = sequence }
      else { self.sequence = EmptySequence() }
    }
  }

  /// Initializing with a sequence.
  ///
  /// - Parameter sequence: The sequence loaded into the mixer.
  init(sequence: Sequence)
  {
    self.sequence = sequence
    trackCount = sequence.instrumentTracks.count
    sequencerSubscription = sequencer.$sequence.sink
    {
      if let sequence = $0 { self.sequence = sequence }
      else { self.sequence = EmptySequence() }
    }
    sequenceSubscriptions.store
    {
      sequence.trackAdditionPublisher.sink { _ in self.trackCount += 1 }
      sequence.trackRemovalPublisher.sink { _ in self.trackCount -= 1 }
    }
  }
}
