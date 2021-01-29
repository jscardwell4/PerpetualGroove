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

/// A view for displaying the color associated with an instrument track and
/// for selecting a track as the current track.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ColorButton: View
{
  /// The track whose color is being displayed.
  @EnvironmentObject var track: InstrumentTrack

  var body: some View
  {
    Button
    {
      track.isCurrentDispatch = true
      logi("<\(#fileID) \(#function)> selected track '\(track.displayName)'")
    }
    label:
    {
      Image("color_swatch\(track.isCurrentDispatch ? "-selected" : "")", bundle: .module)
    }
    .accentColor(track.color.color)
  }
}
