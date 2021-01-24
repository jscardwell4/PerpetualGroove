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
struct TrackBus: View
{
  @StateObject var track: InstrumentTrack

  /*
   removal display
   */
  var body: some View
  {
    VStack
    {
      VolumeSlider(volume: $track.volume)
      PanKnob(pan: $track.pan)
      SoloButton(isEngaged: $track.isSoloed).padding()
      MuteButton(isEngaged: $track.isMuted,
                 isEnabled: !(track.isForceMuted || track.isSoloed))
        .padding()
      SoundFontButton(soundFont: track.instrument.soundFont)
      BusLabel(label: $track.displayName).padding(.top)
      ColorButton(color: $track.color,
                  isSelected: player.currentDispatch as? InstrumentTrack === track)
        .padding(.bottom)
    }
  }
}

// MARK: - TrackBus_Previews

@available(iOS 14.0, *)
struct TrackBus_Previews: PreviewProvider
{
  static let previewTrack: InstrumentTrack = {
    let font = SoundFont.bundledFonts.randomElement()!
    let header =
      unwrapOrDie(font.presetHeaders.randomElement())
    let preset = Instrument.Preset(font: font, header: header, channel: 0)
    let instrument = tryOrDie { try Instrument(preset: preset, audioEngine: audioEngine) }
    return tryOrDie
    {
      try InstrumentTrack(index: 1, color: .muddyWaters, instrument: instrument)
    }
  }()

  static var previews: some View
  {
    TrackBus(track: previewTrack)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
