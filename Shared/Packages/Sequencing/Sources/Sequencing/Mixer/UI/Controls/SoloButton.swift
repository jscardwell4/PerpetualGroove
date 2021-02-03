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

/// A button for toggling a track's participation in a 'Solo Group'.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoloButton: View
{
  /// The bus for which this button serves as a control.
  @EnvironmentObject var bus: Bus

  var body: some View
  {
    Button(action: { self.bus.isSoloed.toggle() })
    {
      Text("Solo").evelethFont(family: .normal, weigth: .light, size: 14)
    }
    .preference(key: TrackBus.SoloPreferenceKey.self, value: bus.isSoloed ? [bus.id] : [])
    .frame(width: 68, height: 14)
    .accentColor(Color("\(bus.isSoloed ? "" : "dis")engagedTintColor", bundle: .module))
  }
}
