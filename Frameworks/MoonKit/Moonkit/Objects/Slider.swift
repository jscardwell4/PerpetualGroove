//
//  Slider.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/6/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

@IBDesignable public class Slider: UISlider {

  // MARK: - Enumeration to specify the style of the slider's thumb button
  public enum ThumbStyle: Equatable {

    public enum ColorType { case Red, Green, Blue, Alpha }

    case Default
    case Custom ((Slider) -> UIImage)
    case OneTone (ColorType)
    case TwoTone (ColorType)
    case Gradient (ColorType)

  }

  public var labelTextForValue: (Float) -> String = { String($0, precision: 2) } {
    didSet {
      valueLabel.text = labelTextForValue(value)
    }
  }

  public override func updateConstraints() {
    super.updateConstraints()
    guard constraintsWithPrefixTags(labelValueIdentifier.tags).count == 0 else { return }
    constrain(valueLabel.centerY => centerY + valueLabelOffset.vertical --> (labelValueIdentifier + "Vertical"))
    constrain(valueLabel.centerX => centerX + valueLabelOffset.horizontal --> (labelValueIdentifier + "Horizontal"))
    labelValueWidthConstraint = constraintWithIdentifier(labelValueIdentifier + "Horizontal")
  }

  private let labelValueIdentifier = Identifier(self, "ValueLabel")
  private weak var labelValueWidthConstraint: NSLayoutConstraint?

  func valueDidChange() {
    valueLabel.text = labelTextForValue(value)
  }

  private func setup() {
    addTarget(self, action: "valueDidChange", forControlEvents: [.ValueChanged])
    valueLabel.setContentCompressionResistancePriority(1000, forAxis: .Vertical)
    valueLabel.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
    valueLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
    valueLabel.setContentHuggingPriority(1000, forAxis: .Horizontal)
    valueLabel.layer.zPosition = 100
    valueLabel.hidden = valueLabelHidden
    valueLabel.text = labelTextForValue(value)
    addSubview(valueLabel)
    setNeedsUpdateConstraints()
  }

  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeBool(valueLabelHidden, forKey: "valueLabelHidden")
    aCoder.encodeBool(trackShowsThroughThumb, forKey: "trackShowsThroughThumb")
    aCoder.encodeUIOffset(thumbOffset, forKey: "thumbOffset")
    aCoder.encodeUIOffset(valueLabelOffset, forKey: "valueLabelOffset")
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    valueLabelHidden = aDecoder.decodeBoolForKey("valueLabelHidden")
    trackShowsThroughThumb = aDecoder.decodeBoolForKey("trackShowsThroughThumb")
    thumbOffset = aDecoder.decodeUIOffsetForKey("thumbOffset")
    valueLabelOffset = aDecoder.decodeUIOffsetForKey("valueLabelOffset")
    setup()
  }

  public let valueLabel = UILabel(autolayout: true)
  @IBInspectable public var valueLabelHidden: Bool = true { didSet { valueLabel.hidden = valueLabelHidden } }
  @IBInspectable public var thumbOffsetString: String {
    get { return NSStringFromUIOffset(thumbOffset) }
    set { thumbOffset = UIOffsetFromString(newValue) }
  }
  @IBInspectable public var valueLabelOffsetString: String {
    get { return NSStringFromUIOffset(valueLabelOffset) }
    set { valueLabelOffset = UIOffsetFromString(newValue) }
  }
  public var thumbOffset: UIOffset = .zeroOffset { didSet { setNeedsDisplay() } }
  public var valueLabelOffset: UIOffset = .zeroOffset { didSet { setNeedsDisplay() } }

  @IBInspectable public var trackShowsThroughThumb: Bool = false
  @IBInspectable public var defaultMinimumTrackImage: UIImage? {
    didSet {
      if let image = defaultMinimumTrackImage, color = minimumTrackTintColor {
        setMinimumTrackImage(image, forState: .Normal, color: color)
      }
    }
  }
  @IBInspectable public var defaultMaximumTrackImage: UIImage? {
    didSet {
      if let image = defaultMaximumTrackImage, color = maximumTrackTintColor {
        setMaximumTrackImage(image, forState: .Normal, color: color)
      }
    }
  }
  @IBInspectable public var defaultThumbImage: UIImage? {
    didSet {
      if let image = defaultThumbImage, color = thumbTintColor {
        setThumbImage(image, forState: .Normal, color: color)
      }
    }
  }

  /**
  setThumbImage:forState:

  - parameter image: UIImage?
  - parameter state: UIControlState
  */
  public func setThumbImage(image: UIImage?, forState state: UIControlState, color: UIColor?) {
    if let color = color { setThumbImage(image?.imageWithColor(color), forState: state) }
    else { setThumbImage(image, forState: state) }
  }

  /**
  setMinimumTrackImage:forState:

  - parameter image: UIImage?
  - parameter state: UIControlState
  */
  public func setMinimumTrackImage(image: UIImage?, forState state: UIControlState, color: UIColor?) {
    if let color = color { setMinimumTrackImage(image?.imageWithColor(color), forState: state) }
    else { setMinimumTrackImage(image, forState: state) }
  }

  /**
  setMaximumTrackImage:forState:

  - parameter image: UIImage?
  - parameter state: UIControlState
  */
  public func setMaximumTrackImage(image: UIImage?, forState state: UIControlState, color: UIColor?) {
    if let color = color {  setMaximumTrackImage(image?.imageWithColor(color), forState: state) }
    else {  setMaximumTrackImage(image, forState: state) }
  }

  /**
  thumbRectForBounds:trackRect:value:

  - parameter bounds: CGRect
  - parameter rect: CGRect
  - parameter value: Float

  - returns: CGRect
  */
  public override func thumbRectForBounds(bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
    var thumbRect = super.thumbRectForBounds(bounds, trackRect: rect, value: value)
    thumbRect.offset(thumbOffset)
    let zeroConstant = rect.midX
    var midThumb = thumbRect.midX
    guard trackShowsThroughThumb, let thumbImage = currentThumbImage else {
      labelValueWidthConstraint?.constant = midThumb - zeroConstant
      return thumbRect
    }

    let halfThumb = half(thumbImage.size.width)
    let midValue = half(CGFloat(maximumValue))
    let ratio = Ratio((CGFloat(value) - midValue) / midValue)
    thumbRect.origin.x += halfThumb * ratio.value
    midThumb = thumbRect.midX
    labelValueWidthConstraint?.constant = midThumb - zeroConstant

    return thumbRect
  }

  public var style: ThumbStyle = .Default {
    didSet {
      if case .Default = style {
        removeTarget(self, action: nil, forControlEvents: .ValueChanged)
      } else if actionsForTarget(self, forControlEvent: .ValueChanged) == nil {
        updateThumbImage()
        addTarget(self, action: "updateThumbImage", forControlEvents: .ValueChanged)
      }
    }
  }

  override public var value: Float {
    didSet {
      if style != ThumbStyle.Default { updateThumbImage() }
    }
  }

  /** updateThumbImage */
  func updateThumbImage() {

    let value = CGFloat(self.value / minimumValue.distanceTo(maximumValue))
    var image: UIImage?

    switch style {

      case .Custom(let generateThumbImage):
        image = generateThumbImage(self)

      case .OneTone(let colorType):
        switch colorType {
          case .Red:
            image = DrawingKit.imageOfRedCircle(opacity: value)
          case .Green:
            image = DrawingKit.imageOfGreenCircle(opacity: value)
          case .Blue:
            image = DrawingKit.imageOfBlueCircle(opacity: value)
          case .Alpha:
            image = DrawingKit.imageOfAlphaCircle(opacity: value)
        }

      case .TwoTone(let colorType):
        switch colorType {
          case .Red:
            image = DrawingKit.imageOfRedValueCircle(value: value)
          case .Green:
            image = DrawingKit.imageOfGreenValueCircle(value: value)
          case .Blue:
            image = DrawingKit.imageOfBlueValueCircle(value: value)
          case .Alpha:
            image = DrawingKit.imageOfAlphaValueCircle(value: value)
        }

      case .Gradient(let colorType):
        switch colorType {
          case .Red:
            image = DrawingKit.imageOfRedGradientCircle(opacity: value)
          case .Green:
            image = DrawingKit.imageOfGreenGradientCircle(opacity: value)
          case .Blue:
            image = DrawingKit.imageOfBlueGradientCircle(opacity: value)
          case .Alpha:
            image = DrawingKit.imageOfAlphaGradientCircle(opacity: value)
        }

      case .Default: image = currentThumbImage

    }
    setThumbImage(image, forState: .Normal)
  }

}

public func ==(lhs: Slider.ThumbStyle, rhs: Slider.ThumbStyle) -> Bool {
  switch (lhs, rhs) {
    case (.Default, .Default), (.OneTone, .OneTone), (.TwoTone, .TwoTone), (.Gradient, .Gradient), (.Custom, .Custom): return true
    default: return false
  }
}
