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
  @State var volume: Float = 5

  @State var pan: Float = 0

  @State private var label = "Main"

  var body: some View
  {
    VStack
    {
      VolumeSlider(volume: $volume)
      PanKnob(pan: $pan)
      Spacer()
      BusLabel(label: $label).padding()
      Spacer()
        .frame(height: 22)
//        .padding()
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
