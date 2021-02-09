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

  @Environment(\.player) var player: Player

  @State private var isSelected = false

  var body: some View
  {
    Button
    {
      isSelected.toggle()
      bus.isCurrentDispatch = isSelected
      player.currentDispatch = isSelected ? bus.track.nodeManager : nil
    }
    label:
    {
      Image("color_swatch\(isSelected ? "-selected" : "")", bundle: .module)
    }
    .accentColor(bus.color)
    .onReceive(player.$currentDispatch)
    {
      newDispatch in
      if isSelected, newDispatch !== bus.track.nodeManager
      {
        isSelected = false
      }
    }
  }
}
