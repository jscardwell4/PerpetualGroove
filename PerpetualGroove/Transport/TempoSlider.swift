//
//  TempoSlider.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/2/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Eveleth

@IBDesignable
final class TempoSlider: UIControl {

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private let slider = Slider(autolayout: true)

  @objc private func valueChanged() {
    sendActions(for: .valueChanged)
  }


  private func setup() {

    slider.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    if let image = UIImage(named: "horizontal_thumb2", in: Bundle(for: TempoSlider.self), compatibleWith: nil) {
      slider.thumbImage = image
    }
//    slider.thumbImage = #imageLiteral(resourceName: "horizontal_thumb")

    if let image = UIImage(named: "horizontal_track2", in: Bundle(for: TempoSlider.self), compatibleWith: nil) {
      slider.trackMinImage = image
      slider.trackMaxImage = image
    }
//    slider.trackMinImage = #imageLiteral(resourceName: "horizontal_track")
//    slider.trackMaxImage = #imageLiteral(resourceName: "horizontal_track")
    slider.thumbColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    slider.trackMinColor = #colorLiteral(red: 0.5725490196, green: 0.5294117647, blue: 0.4705882353, alpha: 1)
    slider.trackMaxColor = #colorLiteral(red: 0.3012522161, green: 0.2939507067, blue: 0.2860662341, alpha: 1)
    slider.minimumValue = 24
    slider.maximumValue = 400
    slider.value = 120
    slider.valueLabelTextColor = #colorLiteral(red: 0.9688921571, green: 0.9929882288, blue: 0.9999273419, alpha: 1)
    slider.showsValueLabel = true
    slider.valueLabelPrecision = 0
    slider.valueLabelFont = Eveleth.regularFontWithSize(12)
//    slider.valueLabelYOffset = -10
    slider.continuous = false
    slider.trackLabelText = "TEMPO"
    slider.trackLabelFont = Eveleth.lightFontWithSize(13)
//    slider.trackLabelYOffset = 12
//    slider.thumbYOffset = 5
    slider.showsTrackLabel = true

    addSubview(slider)
    constrain(𝗛|slider|𝗛, 𝗩|slider|𝗩)

  }

}
