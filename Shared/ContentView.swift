//
//  ContentView.swift
//  Shared
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import Documents
import MIDI
import MoonDev
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
  @EnvironmentObject var document: GrooveDocument

  @Environment(\.scenePhase) private var scenePhase: ScenePhase

  var body: some View
  {
    VStack
    {
      HStack
      {
        MixerView()
          .padding()
          .fixedSize()
        Spacer()
        VStack
        {
          DocumentNameField(documentName: $document.name)
          PlayerView()
            .padding()
            .fixedSize()
        }
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
    .edgesIgnoringSafeArea(.all)
    .onChange(of: scenePhase)
    {
      phase in
      switch phase
      {
        case .active:
          logi("\(#fileID) \(#function) scenePhase = .active")
        case .inactive:
          logi("\(#fileID) \(#function) scenePhase = .inactive")
        case .background:
          logi("\(#fileID) \(#function) scenePhase = .background")
        default:
          logi("\(#fileID) \(#function) scenePhase = ???")
      }
    }
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
      sequence.add(track: try! InstrumentTrack(
        index: index + 1,
        color: Track.Color[index],
        instrument: instrument
      ))
    }
    return GrooveDocument(sequence: sequence)
  }()

  static var previews: some View
  {
    MixerView()
      .environmentObject(Sequence.mock)
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .fixedSize()
    TransportView()
      .padding()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
    PlayerView()
      .padding()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .fixedSize()
    ContentView()
      .environmentObject(document)
      .previewLayout(.fixed(width: 2_732 / 2, height: 2_048 / 2))
      .preferredColorScheme(.dark)
  }
}
