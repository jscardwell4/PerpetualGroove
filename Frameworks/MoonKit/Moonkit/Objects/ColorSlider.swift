//
//  ColorSlider.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/6/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
public class ColorSlider: UISlider {

  // MARK: - Thumb image

  override public var value: Float {
    didSet {
      if style != ThumbStyle.Default { updateThumbImage() }
      #if TARGET_INTERFACE_BUILDER
        valueDidChange()
      #endif
    }
  }

  /** Just to make this settable from interface builder */
  @IBInspectable public var thumbOffsetString: String {
    get { return NSStringFromUIOffset(thumbOffset) }
    set { thumbOffset = UIOffsetFromString(newValue) }
  }

  public var thumbOffset: UIOffset = .zeroOffset { didSet { setNeedsDisplay() } }

  @IBInspectable public var trackShowsThroughThumb: Bool = false

  @IBInspectable public var defaultThumbImage: UIImage? {
    didSet {
      setThumbImage(defaultThumbImage, forState: .Normal, color: thumbTintColor)
      setThumbImage(defaultThumbImage, forState: .Highlighted, color: thumbTintColor)
      setThumbImage(defaultThumbImage, forState: .Selected, color: thumbTintColor)
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

  /** updateThumbImage */
  func updateThumbImage() {
    let value = CGFloat(self.value / minimumValue.distanceTo(maximumValue))
    var image: UIImage?

    switch style {
      case .Custom(let generateThumbImage): image = generateThumbImage(self)
      case .OneTone(let colorType):
        switch colorType {
          case .Red:   image = DrawingKit.imageOfRedCircle(opacity: value)
          case .Green: image = DrawingKit.imageOfGreenCircle(opacity: value)
          case .Blue:  image = DrawingKit.imageOfBlueCircle(opacity: value)
          case .Alpha: image = DrawingKit.imageOfAlphaCircle(opacity: value)
        }
      case .TwoTone(let colorType):
        switch colorType {
          case .Red:   image = DrawingKit.imageOfRedValueCircle(value: value)
          case .Green: image = DrawingKit.imageOfGreenValueCircle(value: value)
          case .Blue:  image = DrawingKit.imageOfBlueValueCircle(value: value)
          case .Alpha: image = DrawingKit.imageOfAlphaValueCircle(value: value)
        }
      case .Gradient(let colorType):
        switch colorType {
          case .Red:   image = DrawingKit.imageOfRedGradientCircle(opacity: value)
          case .Green: image = DrawingKit.imageOfGreenGradientCircle(opacity: value)
          case .Blue:  image = DrawingKit.imageOfBlueGradientCircle(opacity: value)
          case .Alpha: image = DrawingKit.imageOfAlphaGradientCircle(opacity: value)
        }
      case .Default: image = currentThumbImage
    }
    setThumbImage(image, forState: .Normal)
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



  /** An enumeration to specify the style of the slider's thumb button */
  public enum ThumbStyle: Equatable {

    public enum Channel { case Red, Green, Blue, Alpha }

    case Default
    case Custom ((ColorSlider) -> UIImage)
    case OneTone (Channel)
    case TwoTone (Channel)
    case Gradient (Channel)

  }

  // MARK: - Constraints

  /** updateConstraints */
  public override func updateConstraints() {
    super.updateConstraints()
    guard constraintsWithPrefixTags(Identifier(self).tags).count == 0 else { return }
    constrain(valueLabel.centerY => centerY + valueLabelOffset.vertical --> (valueLabelIdentifier + "Vertical"))
    constrain(valueLabel.centerX => centerX + valueLabelOffset.horizontal --> (valueLabelIdentifier + "Horizontal"))
    valueLabelCenterXConstraint = constraintWithIdentifier(valueLabelIdentifier + "Horizontal")
    valueLabelCenterYConstraint = constraintWithIdentifier(valueLabelIdentifier + "Vertical")
    constrain(trackLabel.centerY => centerY + trackLabelOffset.vertical --> (trackLabelIdentifier + "Vertical"))
    constrain(trackLabel.centerX => centerX + trackLabelOffset.horizontal --> (trackLabelIdentifier + "Horizontal"))
    trackLabelCenterXConstraint = constraintWithIdentifier(trackLabelIdentifier + "Horiziontal")
    trackLabelCenterYConstraint = constraintWithIdentifier(trackLabelIdentifier + "Vertical")
  }

  // MARK: - Value label

  private let valueLabel = UILabel(autolayout: true)

  public var valueLabelFont: UIFont {
    get { return valueLabel.font }
    set { valueLabel.font = newValue }
  }

  @IBInspectable public var valueLabelFontName: String = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1).fontName {
    didSet {
      valueLabelFont = UIFont(name: valueLabelFontName, size: valueLabelFont.pointSize)!
    }
  }
  @IBInspectable public var valueLabelFontSize: CGFloat = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1).pointSize {
    didSet {
    valueLabelFont = UIFont(name: valueLabelFont.fontName, size: valueLabelFontSize)!
    }
  }

  @IBInspectable public var valueLabelTextColor: UIColor {
    get { return valueLabel.textColor }
    set { valueLabel.textColor = newValue }
  }

  @IBInspectable public var valueLabelHidden: Bool = true {
    didSet {
      valueLabel.hidden = valueLabelHidden
      #if TARGET_INTERFACE_BUILDER
        valueLabel.text = _labelTextForValue(value)
      #endif
    }
  }

  /** Just to make this settable from interface builder */
  @IBInspectable public var valueLabelOffsetString: String {
    get { return NSStringFromUIOffset(valueLabelOffset) }
    set { valueLabelOffset = UIOffsetFromString(newValue) }
  }

  public var valueLabelOffset: UIOffset = .zeroOffset {
    didSet {
      valueLabelCenterYConstraint?.constant = valueLabelOffset.vertical
      setNeedsDisplay()
    }
  }

  private let valueLabelIdentifier = Identifier(self, "ValueLabel")
  private weak var valueLabelCenterXConstraint: NSLayoutConstraint?
  private weak var valueLabelCenterYConstraint: NSLayoutConstraint?

  @IBInspectable public var valueLabelTextPrecision: Int = 0 {
    didSet {
      valueLabel.text = _labelTextForValue(value)
    }
  }

  public var labelTextForValue: ((Float) -> String)? {
    didSet {
      valueLabel.text = _labelTextForValue(value)
    }
  }

  private func _labelTextForValue(value: Float) -> String {
    guard labelTextForValue == nil else { return labelTextForValue!(value) }
    return valueLabelTextPrecision == 0 ? "\(Int(value))" : String(value, precision: valueLabelTextPrecision)
  }

  /** valueDidChange */
  @objc private func valueDidChange() { valueLabel.text = _labelTextForValue(value) }

 // MARK: - Track label

  private let trackLabelIdentifier = Identifier(self, "TrackLabel")
  private weak var trackLabelCenterXConstraint: NSLayoutConstraint?
  private weak var trackLabelCenterYConstraint: NSLayoutConstraint?

  private let trackLabel = UILabel(autolayout: true)

  @IBInspectable public var trackLabelText: String? { get { return trackLabel.text } set { trackLabel.text = newValue } }

  public var trackLabelFont: UIFont {
    get { return trackLabel.font }
    set { trackLabel.font = newValue }
  }

  @IBInspectable public var trackLabelFontName: String = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1).fontName {
    didSet {
      trackLabelFont = UIFont(name: trackLabelFontName, size: trackLabelFont.pointSize)!
    }
  }
  @IBInspectable public var trackLabelFontSize: CGFloat = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1).pointSize {
    didSet {
    trackLabelFont = UIFont(name: trackLabelFont.fontName, size: trackLabelFontSize)!
    }
  }

  @IBInspectable public var trackLabelTextColor: UIColor {
    get { return trackLabel.textColor }
    set { trackLabel.textColor = newValue }
  }

  @IBInspectable public var trackLabelHidden: Bool = true {
    didSet { trackLabel.hidden = trackLabelHidden }
  }

  /** Just to make this settable from interface builder */
  @IBInspectable public var trackLabelOffsetString: String {
    get { return NSStringFromUIOffset(trackLabelOffset) }
    set { trackLabelOffset = UIOffsetFromString(newValue) }
  }

  public var trackLabelOffset: UIOffset = .zeroOffset {
    didSet {
      trackLabelCenterXConstraint?.constant = trackLabelOffset.horizontal
      trackLabelCenterYConstraint?.constant = trackLabelOffset.vertical
    }
  }

  // MARK: - Initializing

  /**
  requiresConstraintBasedLayout

  - returns: Bool
  */
  public static override func requiresConstraintBasedLayout() -> Bool { return true }

  /** setup */
  private func setup() {
    trackLabel.hidden = trackLabelHidden
    trackLabel.layer.zPosition = 100
    addSubview(trackLabel)

    addTarget(self, action: "valueDidChange", forControlEvents: [.ValueChanged])
    valueLabel.setContentCompressionResistancePriority(1000, forAxis: .Vertical)
    valueLabel.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
    valueLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
    valueLabel.setContentHuggingPriority(1000, forAxis: .Horizontal)
    valueLabel.layer.zPosition = 100
    valueLabel.hidden = valueLabelHidden
    valueLabel.text = _labelTextForValue(value)
    addSubview(valueLabel)
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeBool(valueLabelHidden,       forKey: "valueLabelHidden")
    aCoder.encodeBool(trackLabelHidden,       forKey: "trackLabelHidden")
    aCoder.encodeBool(trackShowsThroughThumb, forKey: "trackShowsThroughThumb")
    aCoder.encodeUIOffset(thumbOffset,        forKey: "thumbOffset")
    aCoder.encodeUIOffset(valueLabelOffset,   forKey: "valueLabelOffset")
    aCoder.encodeObject(valueLabelFont,       forKey: "valueLabelFont")
    aCoder.encodeObject(valueLabelTextColor,  forKey: "valueLabelTextColor")
    aCoder.encodeUIOffset(trackLabelOffset,   forKey: "trackLabelOffset")
    aCoder.encodeObject(trackLabelFont,       forKey: "trackLabelFont")
    aCoder.encodeObject(trackLabelTextColor,  forKey: "trackLabelTextColor")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)

    valueLabelHidden       = aDecoder.decodeBoolForKey("valueLabelHidden")
    trackLabelHidden       = aDecoder.decodeBoolForKey("trackLabelHidden")
    trackShowsThroughThumb = aDecoder.decodeBoolForKey("trackShowsThroughThumb")
    thumbOffset            = aDecoder.decodeUIOffsetForKey("thumbOffset")
    valueLabelOffset       = aDecoder.decodeUIOffsetForKey("valueLabelOffset")
    trackLabelOffset       = aDecoder.decodeUIOffsetForKey("trackLabelOffset")

    if let fontName = aDecoder.decodeObjectForKey("valueLabelFontName") as? String,
           fontSize = aDecoder.decodeObjectForKey("valueLabelFontSize") as? Double,
           font = UIFont(name: fontName, size: CGFloat(fontSize))
    {
      valueLabelFont = font
    }

    if let fontName = aDecoder.decodeObjectForKey("trackLabelFontName") as? String,
      fontSize = aDecoder.decodeObjectForKey("trackLabelFontSize") as? Double,
      font = UIFont(name: fontName, size: CGFloat(fontSize))
    {
      trackLabelFont = font
    }

    if let color = aDecoder.decodeObjectForKey("valueLabelTextColor") as? UIColor {
      valueLabelTextColor = color
    }

    if let color = aDecoder.decodeObjectForKey("trackLabelTextColor") as? UIColor {
      trackLabelTextColor = color
    }

    setup()
  }


  // MARK: - Minimum track image

  @IBInspectable public var defaultMinimumTrackImage: UIImage? {
    didSet {
      setMinimumTrackImage(defaultMinimumTrackImage, forState: .Normal, color: minimumTrackTintColor)
      setMinimumTrackImage(defaultMinimumTrackImage, forState: .Highlighted, color: minimumTrackTintColor)
      setMinimumTrackImage(defaultMinimumTrackImage, forState: .Selected, color: minimumTrackTintColor)
    }
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

  // MARK: - Maximum track image

  @IBInspectable public var defaultMaximumTrackImage: UIImage? {
    didSet {
      setMaximumTrackImage(defaultMaximumTrackImage, forState: .Normal, color: maximumTrackTintColor)
      setMaximumTrackImage(defaultMaximumTrackImage, forState: .Highlighted, color: maximumTrackTintColor)
      setMaximumTrackImage(defaultMaximumTrackImage, forState: .Selected, color: maximumTrackTintColor)
    }
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

  // MARK: - Rect calculations

  /**
  thumbRectForBounds:trackRect:value:

  - parameter bounds: CGRect
  - parameter rect: CGRect
  - parameter value: Float

  - returns: CGRect
  */
  public override func thumbRectForBounds(bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
    var thumbRect = super.thumbRectForBounds(bounds, trackRect: rect, value: value)
    thumbRect.offsetInPlace(thumbOffset)
    let zeroConstant = rect.midX
    var midThumb = thumbRect.midX
    guard trackShowsThroughThumb, let thumbImage = currentThumbImage else {
      valueLabelCenterXConstraint?.constant = midThumb - zeroConstant
      return thumbRect
    }

    let halfThumb = half(thumbImage.size.width)
    let midValue = half(CGFloat(maximumValue))
    let ratio = Ratio((CGFloat(value) - midValue) / midValue)
    thumbRect.origin.x += halfThumb * ratio.value
    midThumb = thumbRect.midX
    valueLabelCenterXConstraint?.constant = midThumb - zeroConstant

    return thumbRect
  }

  /**
  trackRectForBounds:

  - parameter bounds: CGRect

  - returns: CGRect
  */
  public override func trackRectForBounds(bounds: CGRect) -> CGRect {
    var rect = super.trackRectForBounds(bounds)
    rect.origin.y -= thumbOffset.vertical
    return rect
  }

  /**
  alignmentRectInsets

  - returns: UIEdgeInsets
  */
  public override func alignmentRectInsets() -> UIEdgeInsets {
    let offset = thumbOffset.vertical
    guard offset != 0 else { return .zeroInsets }
    if offset < 0 { return UIEdgeInsets(top: -offset, left: 0, bottom: 0, right: 0) }
    else { return UIEdgeInsets(top: 0, left: 0, bottom: offset, right: 0) }
  }
}

/**
Equatable implementation for thumb styles

- parameter lhs: ColorSlider.ThumbStyle
- parameter rhs: ColorSlider.ThumbStyle

- returns: Bool
*/
public func ==(lhs: ColorSlider.ThumbStyle, rhs: ColorSlider.ThumbStyle) -> Bool {
  switch (lhs, rhs) {
    case (.Default, .Default), (.OneTone, .OneTone), (.TwoTone, .TwoTone), (.Gradient, .Gradient), (.Custom, .Custom): return true
    default: return false
  }
}
