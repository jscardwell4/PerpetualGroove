//
//  TempoSlider.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonKit
import SwiftUI

// MARK: - TempoSlider

struct TempoSlider: UIViewRepresentable
{
  @Binding var value: Float

  func makeUIView(context: Context) -> MoonKit.Slider
  {
    let valueChangedAction = UIAction
    {
      self.value = ($0.sender as? MoonKit.Slider)?.value ?? self.value
    }

    let thumbImage = UIImage(named: "horizontal_thumb", in: bundle, with: nil)!
    let height = thumbImage.size.height

    let slider = MoonKit.Slider(frame: CGRect(size: CGSize(width: 300, height: height)))
    slider.backgroundColor = .clear
    slider.addAction(valueChangedAction, for: .valueChanged)
    slider.thumbImage = thumbImage
    slider.trackMinImage = UIImage(named: "horizontal_track", in: bundle, with: nil)
    slider.trackMaxImage = UIImage(named: "horizontal_track", in: bundle, with: nil)
    slider.thumbColor = UIColor(named: "thumbColor", in: bundle, compatibleWith: nil)!
    slider.trackMinColor = UIColor(named: "trackMinColor",
                                   in: bundle,
                                   compatibleWith: nil)!
    slider.trackMaxColor = UIColor(named: "trackMaxColor",
                                   in: bundle,
                                   compatibleWith: nil)!
    slider.minimumValue = 24
    slider.maximumValue = 400
    slider.value = value
    slider.valueLabelTextColor = UIColor(named: "valueLabelTextColor",
                                         in: bundle,
                                         compatibleWith: nil)!
    slider.showsValueLabel = true
    slider.valueLabelPrecision = 0
    slider.valueLabelFontName = "EvelethRegular"
    slider.valueLabelFontSize = 12
    slider.continuous = false
    slider.trackLabelText = "Tempo"
    slider.trackLabelFontName = "EvelethLight"
    slider.trackLabelFontSize = 13
    slider.showsTrackLabel = true
    slider.identifier = "TempoSlider"
    slider.trackAlignment = .bottomOrRight
    slider.thumbAlignment = .center
    slider.valueLabelAlignment = .top
    slider.valueLabelVerticalOffset = 6
    slider.trackLabelVerticalOffset = 1

    return slider
  }

  func updateUIView(_ uiView: MoonKit.Slider, context: Context) {}
}
