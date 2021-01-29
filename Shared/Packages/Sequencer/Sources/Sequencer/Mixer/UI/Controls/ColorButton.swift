//
//  ColorButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import MoonDev
import SwiftUI

// MARK: - ColorButton

/// A button for displaying a track's assigned color and for setting
/// the player's current node dispatch source.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ColorButton: View
{
  /// The bus for which this button serves as a control.
  @EnvironmentObject var bus: Bus

  var body: some View
  {
    Button { bus.isCurrentDispatch = true }
    label:
    {
      Image("color_swatch\(bus.isCurrentDispatch ? "-selected" : "")", bundle: .module)
    }
    .accentColor(bus.color)
  }
}
