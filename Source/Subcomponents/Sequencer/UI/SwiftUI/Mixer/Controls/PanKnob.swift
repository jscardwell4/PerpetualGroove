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

      KnobHost(value: $pan, valueChangedAction: UIAction
      {
        self.pan = ($0.sender as! MoonDev.Knob).value
      }).frame(width: 74, height: 74)
    }
  }
}

// MARK: - KnobHost

/// A wrapper for an instance of `MoonDev.Slider` configured for use as a volume slider.
private struct KnobHost: UIViewRepresentable
{
  /// The backing value for the slider.
  @Binding var value: Float

  /// The image used for the base.
  private static let baseImage = UIImage(named: "knob",
                                         in: bundle,
                                         with: nil)!

  /// The image used for indicator.
  private static let indicatorImage = UIImage(named: "indicator",
                                              in: bundle,
                                              with: nil)

  /// The image used for indicator fill.
  private static let indicatorFillImage = UIImage(named: "indicator_fill",
                                                  in: bundle,
                                                  with: nil)

  /// The value change action for the hosted knob.
  let valueChangedAction: UIAction

  /// Builds and returns the hosted slider.
  ///
  /// - Parameter context: This parameter is ignored.
  /// - Returns: The hosted slider.
  func makeUIView(context: Context) -> MoonDev.Knob
  {
    let knob = MoonDev.Knob(frame: CGRect(size: CGSize(width: 74, height: 74)))
    knob.minimumValue = -1
    knob.maximumValue = 1
    knob.value = value
    knob.knobBase = KnobHost.baseImage
    knob.knobColor = #colorLiteral(red: 0.499273628, green: 0.4559301734, blue: 0.3952253163, alpha: 1)
    knob.indicatorImage = KnobHost.indicatorImage
    knob.indicatorFillImage = KnobHost.indicatorFillImage
    knob.indicatorColor = #colorLiteral(red: 0.499273628, green: 0.4559301734, blue: 0.3952253163, alpha: 1)
    knob.indicatorStyle = .xor
    knob.indicatorFillStyle = .xor
    knob.identifier = "PanKnob"
    return knob
  }

  /// Updates the hosted slider with the current value of `value`.
  ///
  /// - Parameters:
  ///   - uiView: The hosted slider.
  ///   - context: This parameter is ignored.
  func updateUIView(_ uiView: MoonDev.Knob, context: Context)
  {
    uiView.value = value
  }
}

// MARK: - PanKnob_Previews

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
