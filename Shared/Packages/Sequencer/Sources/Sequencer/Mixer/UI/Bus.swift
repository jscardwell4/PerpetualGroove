//
//  Bus.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/29/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev
import SwiftUI
import Combine

/// A model for encapsulating the bus assignment of an `InstrumentTrack`
/// from the mixer's perspective.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class Bus: ObservableObject, Identifiable
{
  /// Propogates the unique identifier for the underlying track.
  var id: UUID { track.id }

  /// The track assigned to this bus.
  @Published var track: InstrumentTrack

  /// Flag indicating whether this bus contributes to a 'Solo' group.
  @Published var isSoloed = false
  {
    didSet(wasSoloed)
    {
      if isSoloed ^ wasSoloed { isMute = !isSoloed && (isForceMuted || isMuted) }
    }
  }

  /// Flag indicating whether this bus has been intentionally muted.
  @Published var isMuted = false
  {
    didSet(wasMuted)
    {
      if isMuted ^ wasMuted { isMute = !isSoloed && (isForceMuted || isMuted) }
    }
  }

  /// Flag indicating whether this bus has been muted by a 'Solo' group.
  @Published var isForceMuted = false
  {
    didSet(wasForceMuted)
    {
      if isForceMuted ^ wasForceMuted { isMute = !isSoloed && (isForceMuted || isMuted) }
    }
  }

  /// Flag indicating whether this bus has had its audio suppressed.
  /// Toggling the value of this property swaps current and cached volume levels.
  @Published var isMute: Bool = false
  {
    didSet(wasMute)
    {
      if isMute ^ wasMute { swap(&track.instrument.volume, &cachedVolume) }
    }
  }

  /// Flag indicating whether the mute button for this bus should be disabled.
  /// This is `true` if `isSoloed || isForceMuted` and `false` otherwise.
  var isMuteDisabled: Bool { isSoloed || isForceMuted }

  /// Flag indicating whether `track` is the player's current node dispatch.
  @Published var isCurrentDispatch: Bool = false

  /// Derived property creating a binding to the volume level of the track's instrument.
  @Binding var volume: Float

  /// This property is used when muting to quickly switch between volume levels.
  private var cachedVolume: Float = 0

  /// Derived property creating a binding to the pan setting of the track's instrument.
  @Binding var pan: Float

  /// The sound font image for the bus.
  var image: AnyView { track.instrument.soundFont.image }

  /// The display name for the bus.
  @Binding var displayName: String

  /// The color for the bus.
  var color: Color { track.color.color }

  /// Initializing with the assigned track.
  init(track: InstrumentTrack)
  {
    _volume = Binding(get: { track.instrument.volume },
                      set: { track.instrument.volume = (0 ... 1).clamp($0) })
    _pan = Binding(get: { track.instrument.pan },
                   set: { track.instrument.pan = (-1 ... 1).clamp($0) })
    _displayName = Binding(get: { track.displayName },
                           set: { track.displayName = $0 })
    self.track = track
  }
}
