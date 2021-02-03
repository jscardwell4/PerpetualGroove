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
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct MixerView: View
{
  /// The sequencer loaded into the environment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  /// The mixer loaded into the environment by `ContentView`.
  @EnvironmentObject var mixer: Mixer

  public var body: some View
  {
    HStack(spacing: 20)
    {
      MainBus()
        .environmentObject(sequencer.audioEngine) // Add the audio engine.
      ForEach(mixer.buses)
      {
        TrackBus().environmentObject($0) // Add the bus.
      }
      AddTrackButton()
    }
    .onPreferenceChange(TrackBus.SoloPreferenceKey.self) { mixer.update(for: $0) }
  }

  public init() {}
}
