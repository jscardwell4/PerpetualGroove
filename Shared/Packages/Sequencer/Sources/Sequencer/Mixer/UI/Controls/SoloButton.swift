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
  @Binding var isSoloed: Bool

  var body: some View
  {
    Button(action: { self.isSoloed.toggle() })
    {
      Text("Solo").evelethFont(family: .normal, weigth: .light, size: 14)
    }
    .preference(key: TrackBus.SoloPreferenceKey.self, value: isSoloed ? [track.id] : [])
    .frame(width: 68, height: 14)
    .accentColor(Color("\(isSoloed ? "" : "dis")engagedTintColor", bundle: .module))
  }
}
