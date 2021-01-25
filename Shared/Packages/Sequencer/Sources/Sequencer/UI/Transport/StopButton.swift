//
//  StopButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - StopButton

/// A view for stopping the transport's playback.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct StopButton: View
{
  /// The transport controlled by the button.
  @EnvironmentObject private var transport: Transport

  /// The button's action.
  let action: () -> Void
  
  /// The view's body is composed of a single button that reset's the transport.
  /// This button is only enabled when `transport.playing == true`.
  var body: some View
  {
    Button(action: action)
    {
      Image("stop", bundle: Bundle.module)
    }
    .disabled(!transport.isPlaying)
    .accentColor(transport.isPlaying ? .primaryColor1 : .disabledColor)
  }

}
