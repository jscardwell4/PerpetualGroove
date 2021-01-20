//
//  ContentView.swift
//  Shared
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import Documents
import MIDI
import Sequencer
import SoundFont
import SwiftUI

// MARK: - ContentView

/// The main content.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ContentView: View
{
  @Binding var document: GrooveDocument

  var body: some View
  {
    VStack
    {
      HStack
      {
        MixerView(sequence: document.sequence)
          .padding()
          .fixedSize()
        Spacer()
        PlayerView()
          .padding()
          .fixedSize()
      }
      Spacer()
      HStack
      {
        Spacer()
        TransportView()
      }
      .padding()
    }
    .padding()
    .background(Color.backgroundColor1)
    .navigationBarHidden(true)
    .statusBar(hidden: true)
  }

  /// Initializing with a groove document. This initializer loads the sequence
  /// from the specified document into the sequencer.
  /// - Parameter document: The document to load.
  init(document: Binding<GrooveDocument>)
  {
    _document = document
    sequencer.sequence = document.wrappedValue.sequence
  }
}

// MARK: - ContentView_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ContentView_Previews: PreviewProvider
{
  @State static var document: GrooveDocument = {
    let sequence = Sequence()
    for index in 0 ..< 3
    {
      let font = SoundFont.bundledFonts.randomElement()!
      let header = font.presetHeaders.randomElement()!
      let preset = Instrument.Preset(font: font, header: header, channel: 0)
      let instrument = try! Instrument(preset: preset, audioEngine: audioEngine)
      sequence.add(track: try! InstrumentTrack(index: index + 1, instrument: instrument))
    }
    return GrooveDocument(sequence: sequence)
  }()

  static var previews: some View
  {
    MixerView(sequence: document.sequence)
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .fixedSize()
    TransportView()
      .padding()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
//      .fixedSize()
    PlayerView()
      .padding()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .fixedSize()
    ContentView(document: .constant(document))
      .previewLayout(.fixed(width: 2_732 / 2, height: 2_048 / 2))
      .preferredColorScheme(.dark)
  }
}
