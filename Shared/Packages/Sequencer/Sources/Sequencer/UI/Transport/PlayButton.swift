//
//  PlayButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonDev
import SwiftUI

// MARK: - PlayButton

/// A view for manipulating the transport's playback state.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct PlayButton: View
{
  /// The transport for which the button control's playback.
  @EnvironmentObject private var transport: Transport

  /// The button action.
  let action: () -> Void

  /// The name of the image appropriate for the current `transport` state.
  private var imageName: String
  {
    transport.isPlaying && !transport.isPaused ? "pause" : "play"
  }

  /// The view's body is composed of a single state sensitive button
  /// that displays either a play or a pause symbol.
  var body: some View
  {
    Button(action: action)
    {
      Image(imageName, bundle: .module)
        .accentColor(.primaryColor1)
    }
  }
}
