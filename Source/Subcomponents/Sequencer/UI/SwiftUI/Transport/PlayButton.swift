//
//  PlayButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonKit
import SwiftUI

struct PlayButton: View
{
  @Binding var isPlaying: Bool

  @Binding var isPaused: Bool

  var body: some View
  {
    Button(action: {
      [self] in
      isPaused = isPlaying ^ isPaused
      isPlaying = isPlaying ^ isPaused
    })
    {
      Image(isPlaying && !isPaused ? "pause" : "play", bundle: bundle)
        .accentColor(isPaused ? .primaryColor2 : .primaryColor1)
    }
  }
}
