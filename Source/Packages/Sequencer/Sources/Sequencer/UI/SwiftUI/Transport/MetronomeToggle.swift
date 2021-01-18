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
struct MetronomeToggle: View
{
  /// The view's body is composed of a single button that toggles the value of
  /// `metronome.isOn` and adjusts its color accordingly.
  var body: some View
  {
    Button(action: { metronome.isOn.toggle() })
    {
      Image("metronome", bundle: bundle)
    }
    .accentColor(metronome.isOn ? .highlightColor : .primaryColor1)
  }
}

// MARK: - MetronomeToggle_Previews

@available(iOS 14.0, *)
struct MetronomeToggle_Previews: PreviewProvider
{
  static var previews: some View
  {
    MetronomeToggle()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
