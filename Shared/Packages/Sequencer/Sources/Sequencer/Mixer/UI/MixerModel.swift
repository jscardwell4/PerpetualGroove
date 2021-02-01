//
//  MixerModel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/29/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Foundation
import MoonDev
import SwiftUI

/// A model for the mixer to encapsulate mixer-specific logic
/// such as track solo/mute management, track addition/removal management, etc.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class MixerModel: ObservableObject
{
  /// The sequence currently being controlled.
  @Published var sequence: Sequence?
  {
    willSet { subscriptions.removeAll() /* Clear any subscriptions we may have had. */ }
    didSet { if let sequence = sequence, sequence !== oldValue { update(for: sequence) } }
  }

  /// The current bus assignments for `sequence?.instrumentTracks`.
  @Published var buses: [Bus] = []

  /// The model's set of cancellable subscriptions.
  private var subscriptions: Set<AnyCancellable> = []

  // MARK: Updating State

  /// Reconfigures the model for the specified sequence.
  /// - Parameter sequence: The sequence for which the model shall be configured.
  func update(for sequence: Sequence)
  {
    sequence.trackAdditionPublisher
      .subscribe(on: RunLoop.main)
      .sink { self.buses.append(Bus(track: $0)) }
      .store(in: &subscriptions)
    sequence.trackRemovalPublisher
      .subscribe(on: RunLoop.main)
      .sink { track in self.buses.removeFirst { $0.id == track.id } }
      .store(in: &subscriptions)
    sequence.trackChangePublisher
      .subscribe(on: RunLoop.main)
      .sink { self.buses = sequence.instrumentTracks.map(Bus.init(track:)) }
      .store(in: &subscriptions)

    buses = sequence.instrumentTracks.map(Bus.init(track:))
  }

  /// Reconfigures the model for the specified solo preference.
  /// - Parameter soloPreference: The set of identifiers of all soloing tracks.
  func update(for soloPreference: Set<UUID>)
  {
    if soloPreference.isEmpty
    {
      for bus in buses { bus.isForceMuted = false }
    }

    else
    {
      for bus in buses
      {
        let isSoloingBus = soloPreference ∋ bus.id
        assert(isSoloingBus == bus.isSoloed)
        bus.isForceMuted = !isSoloingBus
      }
    }
  }
}
