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
  @StateObject private var master = audioEngine

  var body: some View
  {
    VStack
    {
      VolumeSlider(volume: $master.masterVolume)
      PanKnob(pan: $master.masterPan)
      Spacer()
      Text("Main").busLabel()
        .frame(width: 80, height: 20, alignment: .leading)
        .offset(x: 0, y: -9)
      Spacer()
        .frame(width: ColorButton.buttonSize.width,
               height: ColorButton.buttonSize.height,
               alignment: .center)
        .padding(.bottom)
    }
  }
}

