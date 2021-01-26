//
//  SoloButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI

// MARK: - SoloButton

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoloButton: View
{
  @EnvironmentObject var track: InstrumentTrack

  var body: some View
  {
    Button(action: { track.isSoloed.toggle() })
    {
      Text("Solo").evelethFont(family: .normal, weigth: .light, size: 14)
    }
    .frame(width: 68, height: 14)
    .accentColor(Color("\(track.isSoloed ? "" : "dis")engagedTintColor", bundle: .module))
  }
}
