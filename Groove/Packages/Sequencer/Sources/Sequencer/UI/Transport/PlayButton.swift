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
struct PlayButton: View
{
  /// The view's body is composed of a single state sensitive button
  /// that displays either a play or a pause symbol and is equipped
  /// with an action that manipulates `transport.paused` and
  /// `transport.playing` values
  var body: some View
  {
    Button(action: {
      transport.paused = transport.playing ^ transport.paused
      transport.playing = transport.playing ^ transport.paused
    })
    {
      Image(transport.playing && !transport.paused ? "pause" : "play", bundle: Bundle.module)
        .accentColor(transport.paused ? .primaryColor2 : .primaryColor1)
    }
  }
}

// MARK: - PlayButton_Previews

@available(iOS 14.0, *)
struct PlayButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    PlayButton()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
