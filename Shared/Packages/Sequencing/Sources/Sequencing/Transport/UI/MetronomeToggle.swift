//
//  MetronomeToggle.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - MetronomeToggle

/// A view for toggling the metronome on and off.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct MetronomeToggle: View
{
  /// The metronome being controlled by the button.
  @EnvironmentObject var metronome: Metronome

  /// Flag indicating whether the button is active.
  @State private var isActive = false

  /// The view's body is composed of a single button that toggles the value of
  /// `metronome.isOn` and adjusts its color accordingly.
  var body: some View
  {
    GeometryReader
    {
      let 𝘴 = min($0.size.width, $0.size.height) * 0.75

      Button { metronome.isOn.toggle() }
      label: {
        Image("metronome", bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 𝘴)
      }
        .position(x: $0.size.width/2, y: $0.size.height/2)
    }
    .accentColor(isActive ? .highlightColor : .primaryColor1)
    .onReceive(metronome.$isOn.receive(on: RunLoop.main)) { isActive = $0 }
  }
}
