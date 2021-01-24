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

  let track: InstrumentTrack

  /// The set of subscriptions held by the model.
  private var cancellables: Set<AnyCancellable> = []

  /// Initializing with an instrument track.
  ///
  /// - Parameter instrumentTrack: The track assigned to this bus in the mixer.
  init(instrumentTrack: InstrumentTrack)
  {
    track = instrumentTrack

    // Capture the current values for the represented track.
    isMuteEnabled = !instrumentTrack.isForceMuted
    isMuted = instrumentTrack.isMuted
    isSoloed = instrumentTrack.isSoloed
    volume = instrumentTrack.volume
    pan = instrumentTrack.pan
    soundFont = instrumentTrack.instrument.soundFont
    displayName = instrumentTrack.displayName
    color = instrumentTrack.color
    isCurrent = instrumentTrack.isCurrentDispatch

    // Generate subscriptions to keep our published properties up to date.
    cancellables.store
    {
      instrumentTrack.$isSoloed.assign(to: \.isSoloed, on: self)
      instrumentTrack.$isForceMuted.sink { self.isMuteEnabled = !$0 }
      instrumentTrack.$isMute.assign(to: \.isMute, on: self)
      instrumentTrack.$isMuted.assign(to: \.isMuted, on: self)
      instrumentTrack.volumePublisher.assign(to: \.volume, on: self)
      instrumentTrack.panPublisher.assign(to: \.pan, on: self)
      instrumentTrack.soundFontPublisher.assign(to: \.soundFont, on: self)
      instrumentTrack.displayNamePublisher.assign(to: \.displayName, on: self)
      instrumentTrack.$color.assign(to: \.color, on: self)
      instrumentTrack.isCurrentDispatchPublisher.assign(to: \.isCurrent, on: self)
    }
  }
}
