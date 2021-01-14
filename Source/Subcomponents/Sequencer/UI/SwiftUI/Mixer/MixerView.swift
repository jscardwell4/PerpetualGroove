//
//  MixerView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI
import MoonKit
import SoundFont

// MARK: - MixerView

struct MixerView: View
{
  var body: some View
  {
    HStack
    {
      MainBus()
      TrackBus()
      AddTrackButton()
    }
    .fixedSize()
  }
}

// MARK: - MixerView_Previews

struct MixerView_Previews: PreviewProvider
{
  static var previews: some View
  {
    MixerView()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
  }
}
