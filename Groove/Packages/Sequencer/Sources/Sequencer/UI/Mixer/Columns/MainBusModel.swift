//
//  MainBusModel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/15/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import MoonDev
import SoundFont

@available(iOS 14.0, *)
class MainBusModel: ObservableObject
{
  /// The volume of the represented track's instrument.
  @Published var volume: Float

  /// The pan of the represented track's instrument.
  @Published var pan: Float

  /// The set of subscriptions held by the model.
  private var cancellables: Set<AnyCancellable> = []

  /// Initializer configures the models subscriptions.
  init()
  {
    // Capture the current values for the represented track.
    volume = audioEngine.masterVolume
    pan = audioEngine.masterPan

    // Generate subscriptions to keep our published properties up to date.
    cancellables.store
    {
      audioEngine.$masterVolume.assign(to: \.volume, on: self)
      audioEngine.$masterPan.assign(to: \.pan, on: self)
    }
  }
}

