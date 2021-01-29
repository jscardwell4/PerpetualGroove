//
//  TrackBus.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import MoonDev
import SoundFont
import SwiftUI

// MARK: - TrackBus

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct TrackBus: View
{
  @EnvironmentObject var track: InstrumentTrack

  /// Bound to the `SoloButton`.
  @State private var isSoloed = false

  /// Bound to the `MuteButton`.
  @State private var isMuted = false

  /// Flag indicating whether this bus has been force muted.
  let isForceMuted: Bool

  var body: some View
  {
    VStack(spacing: 20)
    {
      Text("VOL").controlLabel()
      VerticalSlider(value: $track.volume)
      Text("PAN").controlLabel()
      Knob(value: $track.pan)
      SoloButton(isSoloed: $isSoloed)
      MuteButton(isDisabled: isSoloed || isForceMuted,
                 isMute: track.isMute,
                 isMuted: $isMuted)
      SoundFontButton()
      Marquee()
      ColorButton()
    }
  }

  init(isSoloed: Bool = false, isForceMuted: Bool = false, isMuted: Bool = false)
  {
    self.isSoloed = isSoloed
    self.isForceMuted = isForceMuted
    self.isMuted = isMuted
  }

  struct SoloPreferenceKey: PreferenceKey
  {
    static var defaultValue: Set<UUID> = []
    static func reduce(value: inout Set<UUID>, nextValue: () -> Set<UUID>)
    {
      value.formUnion(nextValue())
    }
  }
}
