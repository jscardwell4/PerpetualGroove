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
  @StateObject private var metronome: Metronome = sequencer.metronome

  /// The view's body is composed of a single button that toggles the value of
  /// `metronome.isOn` and adjusts its color accordingly.
  var body: some View
  {
    Button(action: { metronome.isOn.toggle() }) { Image("metronome", bundle: .module) }
      .accentColor(metronome.isOn ? .highlightColor : .primaryColor1)
  }
}
