//
//  PanKnob.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import MoonDev
import SwiftUI

// MARK: - PanKnob

/// A view wrapping a hosted instance of `MoonDev.Slider` for controlling the
/// transport's tempo setting.
@available(iOS 14.0, *)
struct PanKnob: View
{
  /// The tempo value kept in sync with `transport.tempo`.
  @State var pan: Float

  /// The view's body is composed of the slider host constrained to 330w x 44h.
  var body: some View
  {
    VStack
    {
      Text("PAN")
        .font(.style(FontStyle(font: EvelethFont.regular,
                               size: 12,
                               style: .title3)))
        .foregroundColor(Color(#colorLiteral(red: 0.5725490451, green: 0.5294117928, blue: 0.470588237, alpha: 1)))

      Knob(degreesOver90: $pan)
        .frame(width: 74, height: 74)
    }
  }
}

// MARK: - PanKnob_Previews

@available(iOS 14.0, *)
struct PanKnob_Previews: PreviewProvider
{
  static var previews: some View
  {
    PanKnob(pan: 0)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
