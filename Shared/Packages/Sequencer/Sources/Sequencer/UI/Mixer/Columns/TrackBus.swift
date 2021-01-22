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
  @ObservedObject var model: TrackBusModel

  init(track: InstrumentTrack) { model = TrackBusModel(track: track) }

  /*
   removal display
   */
  var body: some View
  {
    VStack
    {
      VolumeSlider(volume: model.volume)
      PanKnob(pan: model.pan)
      SoloButton(isEngaged: model.isSoloed)
        .padding()
      MuteButton(isEngaged: model.isMute,
                 isEnabled: model.isMuteEnabled)
        .padding()
      SoundFontButton(soundFont: model.soundFont)
      BusLabel(label: model.displayName)
        .padding(.top)
      ColorButton(color: model.color,
                  isSelected: model.isCurrent)
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
