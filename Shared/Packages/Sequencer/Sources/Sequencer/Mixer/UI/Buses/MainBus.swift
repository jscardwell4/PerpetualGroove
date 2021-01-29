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
  @EnvironmentObject var master: AudioEngine

  var body: some View
  {
    VStack(spacing: 20)
    {
      Text("VOL").controlLabel()
      VerticalSlider(value: $master.masterVolume)
      Text("PAN").controlLabel()
      Knob(value: $master.masterPan)
      Spacer()
      Text("Main").busLabel()
        .offset(y: -37)
    }
  }
}

