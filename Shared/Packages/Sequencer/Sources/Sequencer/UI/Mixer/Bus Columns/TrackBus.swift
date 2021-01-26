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
  @StateObject var track: InstrumentTrack

  var body: some View
  {
    VStack(spacing: 20)
    {
      Text("VOL").controlLabel()
      VerticalSlider(value: $track.volume)
      Text("PAN").controlLabel()
      Knob(value: $track.pan)
      SoloButton()
      MuteButton()
      SoundFontButton()
      Marquee()
      ColorButton()
    }
    .environmentObject(track)
  }
}
