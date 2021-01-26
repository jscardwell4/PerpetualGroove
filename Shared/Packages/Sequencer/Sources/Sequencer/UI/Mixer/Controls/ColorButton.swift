//
//  ColorButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
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

  /// Derived property indicating whether `track` is currently the active track.
  private var isSelected: Bool { player.currentDispatch as? InstrumentTrack === track }

  /// The image used for the button. This image reflects the value of `isSelected`.
  private var image: some View
  {
    Image("color_swatch\(isSelected ? "-selected" : "")", bundle: .module)
  }

  /// The hardcoded size of the button currently utilized by `MainBus` because I
  /// have yet to figure out how to properly use alignment guides.
  static let buttonSize = CGSize(width: 68, height: 14)

  var body: some View
  {
    Button
    {
      logi("<\(#fileID) \(#function)> color button action not yet implemented.")
    }
    label:
    {
      image
    }
    .accentColor(track.color.color)
  }
}
