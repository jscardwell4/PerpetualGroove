//
//  MixerView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import MoonDev
import SoundFont
import SwiftUI

// MARK: - MixerView

@available(iOS 14.0, *)
public struct MixerView: View
{
  @ObservedObject var model: MixerModel

  public var body: some View
  {
    // Generate the grid items.
    let columns = Array(repeating: GridItem(.fixed(100)),
                        count: model.sequence.instrumentTracks.count)
    HStack
    {
      MainBus()
      LazyVGrid(columns: columns, alignment: .center)
      {
        ForEach(model.sequence.instrumentTracks)
        {
          TrackBus(track: $0)
        }
      }
      AddTrackButton()
    }
  }

  public init(sequence: Sequence)
  {
    model = MixerModel(sequence: sequence)
  }
}

// MARK: - MixerView_Previews

@available(iOS 14.0, *)
struct MixerView_Previews: PreviewProvider
{
  static let previewSequence: Sequence = {
    let sequence = Sequence()
    for index in 0 ..< 3
    {
      let font = SoundFont.bundledFonts.randomElement()!
      let header = font.presetHeaders.randomElement()!
      let preset = Instrument.Preset(font: font, header: header, channel: 0)
      let instrument = try! Instrument(preset: preset, audioEngine: audioEngine)
      sequence.add(track: try! InstrumentTrack(
        index: index + 1,
        color: Track.Color[index],
        instrument: instrument
      ))
    }
    return sequence
  }()

  static var previews: some View
  {
    MixerView(sequence: previewSequence)
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .fixedSize()
  }
}
