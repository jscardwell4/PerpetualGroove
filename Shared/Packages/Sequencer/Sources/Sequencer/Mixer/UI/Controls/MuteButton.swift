//
//  MuteButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI

// MARK: - MuteButton

/// A button for explictly muting bus audio.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct MuteButton: View
{
  /// Flag used to determine the button's accent color.
  @Environment(\.isEnabled) var isEnabled

  /// The bus for which this button serves as a control.
  @EnvironmentObject var bus: Bus

  var body: some View
  {
    Button { self.bus.isMuted.toggle() }
      label: { Text("Mute").evelethFont(family: .normal, weigth: .light, size: 14) }
      .frame(width: 68, height: 14)
      .accentColor(Color((bus.isMute ? "engaged" : isEnabled ? "disengaged" : "disabled")
                          + "TintColor", bundle: .module))
  }
}
