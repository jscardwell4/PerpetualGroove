//
//  TrackBus.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import SoundFont
import SwiftUI

// MARK: - TrackBus

struct TrackBus: View
{
  @State var volume: Float = 5

  @State var pan: Float = 0

  @State var isSelected: Bool = false

  @State var isSoloEngaged: Bool = false

  @State var isSoloEnabled: Bool = true

  @State var isMuteEngaged: Bool = false

  @State var isMuteEnabled: Bool = true

  @State var label: String = "Bus 1"

//  @ObservedObject var track: InstrumentTrack

  /*
   removal display
   */
  var body: some View
  {
    VStack
    {
      VolumeSlider(volume: $volume)
      PanKnob(pan: $pan)
      SoloButton(isEngaged: $isSoloEngaged, isEnabled: $isSoloEnabled).padding()
      MuteButton(isEngaged: $isMuteEngaged, isEnabled: $isMuteEnabled).padding()
      SoundFontButton(soundFont: bundledFonts[2])
      BusLabel(label: $label).padding(.top)
      ColorButton(color: .muddyWaters, isSelected: $isSelected).padding(.bottom)
    }
  }
}

// MARK: - TrackBus_Previews

struct TrackBus_Previews: PreviewProvider
{
  static var previews: some View
  {
    TrackBus()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
