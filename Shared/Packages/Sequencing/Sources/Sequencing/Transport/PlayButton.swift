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
  @Environment(\.currentTransport) var currentTransport: Transport

  /// The name of the image appropriate for the current `transport` state.
  @State private var image = Image("play", bundle: .module)

  /// The view's body is composed of a single state sensitive button
  /// that displays either a play or a pause symbol.
  var body: some View
  {
    Button
    {
      if currentTransport.isPlaying { currentTransport.isPaused.toggle() }
      else { currentTransport.isPlaying.toggle() }
    }
    label: {
      image
        .resizable()
        .aspectRatio(contentMode: .fit)
        .accentColor(!currentTransport.isPlaying ? .primaryColor1 : .primaryColor2)
    }
      .onReceive(currentTransport.$isPlaying.receive(on: RunLoop.main))
      {
        image = Image($0 ? "pause" : "play", bundle: .module)
      }
  }
}
