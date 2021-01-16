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

struct MainBus: View
{
  @ObservedObject private var model = MainBusModel()

  var body: some View
  {
    VStack
    {
      VolumeSlider(volume: model.volume)
      PanKnob(pan: model.pan)
      Spacer()
      BusLabel(label: "Main").padding()
      Spacer()
        .frame(height: 22)
    }
  }
}

// MARK: - MainBus_Previews

struct MainBus_Previews: PreviewProvider
{
  static var previews: some View
  {
    MainBus()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
