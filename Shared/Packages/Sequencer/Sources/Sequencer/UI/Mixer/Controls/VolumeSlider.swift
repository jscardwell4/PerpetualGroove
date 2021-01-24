//
//  VolumeSlider.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import MoonDev
import SwiftUI
import Common

// MARK: - VolumeSlider

/// A view wrapping a hosted instance of `MoonDev.Slider` for controlling the
/// transport's tempo setting.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct VolumeSlider: View
{
  /// The bus volume.
  @Binding private var volume: Float

  /// The view's body is composed of the slider host constrained to a width of `100`
  /// and a "VOL" label.
  var body: some View
  {
    VStack
    {
      Text("VOL")
        .font(.style(FontStyle(font: EvelethFont.regular,
                               size: 12,
                               style: .title3)))
        .foregroundColor(Color(#colorLiteral(red: 0.5725490451, green: 0.5294117928, blue: 0.470588237, alpha: 1)))
        .padding(.top)

      VerticalSlider(value: $volume)
    }
    .fixedSize()
  }

  init(volume: Binding<Float>)
  {
    _volume = volume
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct VolumeSlider_Previews: PreviewProvider
{
  static var previews: some View
  {
    VolumeSlider(volume: .constant(0.75))
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    VerticalSlider(value: .constant(0.75))
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
