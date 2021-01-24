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
struct MainBus: View
{
  @ObservedObject private var master = audioEngine

  var body: some View
  {
    VStack
    {
      VolumeSlider(volume: $master.masterVolume)
      PanKnob(pan: $master.masterPan)
      Spacer()
      BusLabel(label: .constant("Main")).padding()
      Spacer()
        .frame(height: 22)
    }
  }
}

// MARK: - MainBus_Previews

@available(iOS 14.0, *)
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
