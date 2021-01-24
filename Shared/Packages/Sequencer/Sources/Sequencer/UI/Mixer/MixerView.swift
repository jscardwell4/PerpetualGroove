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
  @EnvironmentObject var sequence: Sequence

  public var body: some View
  {
    // Generate the grid items.
    let columns = Array(repeating: GridItem(.flexible(minimum: 100)),
                        count: sequence.instrumentTracks.count)
    HStack
    {
      MainBus()
      LazyVGrid(columns: columns, alignment: .center)
      {
        ForEach(sequence.instrumentTracks)
        {
          TrackBus(track: $0)
        }
      }
      AddTrackButton()
    }
    .fixedSize()
  }

  public init() {}
}
