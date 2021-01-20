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
struct VolumeSlider: View
{
  /// The bus volume.
  @State var volume: Float

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

      SliderHost(value: $volume, valueChangedAction: UIAction
      {
        self.volume = ($0.sender as! MoonDev.Slider).value
      })
    }
    .frame(height: 300)
  }
}

// MARK: - SliderHost

/// A wrapper for an instance of `MoonDev.Slider` configured for use as a volume slider.
@available(iOS 14.0, *)
private struct SliderHost: UIViewRepresentable
{
  /// The backing value for the slider.
  @Binding var value: Float

  /// The image used for the thumb.
  private static let thumbImage = UIImage(named: "vertical_thumb",
                                          in: Bundle.module,
                                          with: nil)!

  /// The image used for both tracks.
  private static let trackImage = UIImage(named: "vertical_track",
                                          in: Bundle.module,
                                          with: nil)

  /// The value change action for the hosted slider.
  let valueChangedAction: UIAction

  /// Builds and returns the hosted slider.
  ///
  /// - Parameter context: This parameter is ignored.
  /// - Returns: The hosted slider.
  func makeUIView(context: Context) -> MoonDev.Slider
  {
    let slider = MoonDev.Slider()
    slider.backgroundColor = .clear
    slider.isVertical = true
    slider.addAction(valueChangedAction, for: .valueChanged)
    slider.thumbImage = SliderHost.thumbImage
    slider.trackMinImage = SliderHost.trackImage
    slider.trackMaxImage = SliderHost.trackImage
    slider.thumbColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    slider.trackMinColor = #colorLiteral(red: 0.499273628, green: 0.4559301734, blue: 0.3952253163, alpha: 1)
    slider.trackMaxColor = #colorLiteral(red: 0.3598591387, green: 0.3248813152, blue: 0.2747731805, alpha: 1)
    slider.minimumValue = 0
    slider.maximumValue = 11
    slider.value = value
    slider.identifier = "VolumeSlider"
    return slider
  }

  /// Updates the hosted slider with the current value of `value`.
  ///
  /// - Parameters:
  ///   - uiView: The hosted slider.
  ///   - context: This parameter is ignored.
  func updateUIView(_ uiView: MoonDev.Slider, context: Context)
  {
    uiView.value = value
  }
}

// MARK: - VolumeSlider_Previews

@available(iOS 14.0, *)
struct VolumeSlider_Previews: PreviewProvider
{
  static var previews: some View
  {
    VolumeSlider(volume: 7)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
      .padding()
  }
}
