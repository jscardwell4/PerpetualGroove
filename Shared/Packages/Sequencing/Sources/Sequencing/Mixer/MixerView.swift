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
  /// The mixer loaded into the environment by `ContentView`.
  @EnvironmentObject var mixer: Mixer

  public var body: some View
  {
    HStack(spacing: 20)
    {
      MainBus()
      ForEach(mixer.buses) { TrackBus().environmentObject($0) }
      AddTrackButton()
    }
    .fixedSize(horizontal: false, vertical: true)
    .onPreferenceChange(TrackBus.SoloPreferenceKey.self) { mixer.update(for: $0) }
  }

  public init() {}
}
