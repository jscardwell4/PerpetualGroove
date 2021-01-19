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
struct StopButton: View
{
  /// The view's body is composed of a single button that reset's the transport.
  /// This button is only enabled when `transport.playing == true`.
  var body: some View
  {
    Button(action: { transport.reset() })
    {
      Image("stop", bundle: Bundle.module)
    }
    .disabled(!transport.playing)
    .accentColor(transport.playing ? .primaryColor1 : .disabledColor)
  }
}

// MARK: - StopButton_Previews

@available(iOS 14.0, *)
struct StopButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    StopButton()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
