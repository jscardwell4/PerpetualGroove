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
  @EnvironmentObject var bus: Bus

  var body: some View
  {
    VStack(spacing: 20)
    {
      Text("VOL").controlLabel()
      VerticalSlider(value: bus.$volume)
      Text("PAN").controlLabel()
      Knob(value: bus.$pan)
      SoloButton()
      MuteButton().disabled(bus.isMuteDisabled)
      SoundFontButton().frame(maxHeight: 64)
      Marquee()
      ColorButton()
    }
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
