//
//  MainBus.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI

// MARK: - MainBus

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct MainBus: View
{
  @Environment(\.audioEngine) var audioEngine: AudioEngine

  var body: some View
  {
    VStack
    {
      VStack(spacing: 20)
      {
        Text("VOL")
          .controlLabel()
        VerticalSlider(value: Binding<Float>(get: { audioEngine.masterVolume },
                                             set: { audioEngine.masterVolume = $0}))
        Text("PAN")
          .controlLabel()
        Knob(value: Binding<Float>(get: { audioEngine.masterPan },
                                   set: { audioEngine.masterPan = $0 }))
      }
      Spacer()
      Text("Main")
        .busLabel()
        .padding(.bottom, 37)
    }
  }
}

