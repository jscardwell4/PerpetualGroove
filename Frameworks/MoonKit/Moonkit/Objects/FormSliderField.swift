//
//  FormSliderField.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public final class FormSliderField: FormField {

  private var _value: Float = 0

  override public var value: Any? {
    get { return _value }
    set { guard let v = newValue as? Float else { return }; _value = v; slider?.value = v }
  }

  public var min: Float = 0 { didSet { slider?.minimumValue = min } }
  public var max: Float = 1 { didSet { slider?.maximumValue = max } }

  public var minTrack: UIImage? { didSet { slider?.setMinimumTrackImage(minTrack, forState: .Normal) } }
  public var maxTrack: UIImage?  { didSet { slider?.setMaximumTrackImage(maxTrack, forState: .Normal) } }

  public var thumb: UIImage?  { didSet { slider?.setThumbImage(thumb, forState: .Normal) } }

  public var offset: UIOffset? { didSet { slider?.thumbOffset = offset ?? UIOffset.zeroOffset } }

  public var precision = 0 { didSet { slider?.precision = precision } }

  public init(name: String,
              precision: Int = 0,
              value: Float = 0,
              min: Float = 0,
              max: Float = 1,
              minTrack: UIImage? = nil,
              maxTrack: UIImage? = nil,
              thumb: UIImage? = nil,
              offset: UIOffset? = nil)
  {
    _value = value
    self.precision = precision
    self.min = min
    self.max = max
    self.minTrack = minTrack
    self.maxTrack = maxTrack
    self.thumb = thumb
    self.offset = offset
    super.init(name: name)
  }

  private weak var slider: LabeledSlider? { didSet { _control = slider } }

  override public var font: UIFont? { didSet { if let font = font { slider?.font = font } } }
  override public var color: UIColor? { didSet { if let color = color { slider?.textColor = color } } }
  override var control: UIView {
    guard slider == nil else { return slider! }

    let control = LabeledSlider(autolayout: true)
    control.precision = precision
    control.identifier = "slider"
    control.userInteractionEnabled = editable
    control.minimumValue = min
    control.maximumValue = max
    control.value = _value
    control.setMinimumTrackImage(minTrack, forState: .Normal)
    control.setMaximumTrackImage(maxTrack, forState: .Normal)
    control.setThumbImage(thumb, forState: .Normal)
    if let offset = offset { control.thumbOffset = offset }
    control.addTarget(self, action: "valueDidChange:", forControlEvents: .ValueChanged)
    slider = control
    return control
  }

  func valueDidChange(slider: ColorSlider) {
    _value = slider.value
    changeHandler?(self)
  }

}
