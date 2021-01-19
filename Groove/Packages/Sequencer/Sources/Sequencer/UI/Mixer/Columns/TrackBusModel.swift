//
//  TrackBusModel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import MoonDev
import SoundFont

@available(iOS 14.0, *)
class TrackBusModel: ObservableObject
{
  /// Whether the represented track is being soloed.
  @Published var isSoloed = false

  /// Whether the represented track is being muted for any reason.
  @Published var isMute = false

  /// Whether the represented track is being muted.
  @Published var isMuted = false

  /// Whether the mute button is enabled.
  @Published var isMuteEnabled: Bool

  /// The volume of the represented track's instrument.
  @Published var volume: Float

  /// The pan of the represented track's instrument.
  @Published var pan: Float

  /// The sound font used by the represented track's instrument.
  @Published var soundFont: AnySoundFont

  /// The name of the represented track.
  @Published var displayName: String

  /// The color of the represented track.
  @Published var color: Track.Color

  /// Flag indicating whether `player.currentDispatch` has been set to
  /// the represented track.
  @Published var isCurrent: Bool

  /// The set of subscriptions held by the model.
  private var cancellables: Set<AnyCancellable> = []

  /// Initializing with an instrument track.
  ///
  /// - Parameter track: The track assigned to this bus in the mixer.
  init(track: InstrumentTrack)
  {
    // Capture the current values for the represented track.
    isMuteEnabled = !track.isForceMuted
    isMuted = track.isMuted
    isSoloed = track.isSoloed
    volume = track.volume
    pan = track.pan
    soundFont = track.instrument.soundFont
    displayName = track.displayName
    color = track.color
    isCurrent = track.isCurrentDispatch

    // Generate subscriptions to keep our published properties up to date.
    cancellables.store
    {
      track.$isSoloed.assign(to: \.isSoloed, on: self)
      track.$isForceMuted.sink { self.isMuteEnabled = !$0 }
      track.$isMute.assign(to: \.isMute, on: self)
      track.$isMuted.assign(to: \.isMuted, on: self)
      track.volumePublisher.assign(to: \.volume, on: self)
      track.panPublisher.assign(to: \.pan, on: self)
      track.soundFontPublisher.assign(to: \.soundFont, on: self)
      track.displayNamePublisher.assign(to: \.displayName, on: self)
      track.$color.assign(to: \.color, on: self)
      track.isCurrentDispatchPublisher.assign(to: \.isCurrent, on: self)
    }
  }
}
