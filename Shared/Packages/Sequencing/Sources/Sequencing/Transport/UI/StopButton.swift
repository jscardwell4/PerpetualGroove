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

  /// Flag indicating whether the button is disabled.
  @State private var isDisabled = true

  /// The view's body is composed of a single button that reset's the transport.
  /// This button is only enabled when `transport.playing == true`.
  var body: some View
  {
    Button { transport.reset() }
      label: {
        Image("stop", bundle: Bundle.module)
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
      .disabled(isDisabled)
      .accentColor(isDisabled ? .disabledColor : .primaryColor2)
      .onReceive(transport.$isPlaying.receive(on: RunLoop.main)) { isDisabled = !$0 }
  }

}
