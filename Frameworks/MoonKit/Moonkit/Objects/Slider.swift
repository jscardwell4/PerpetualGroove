//
//  Slider.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit
import Chameleon

@IBDesignable public class Slider: UIControl {

  // MARK: - Axis
  public enum Axis: String {
    case Horizontal, Vertical
  }

  public var axis: Axis = .Horizontal { didSet { guard oldValue != axis else { return }; setNeedsDisplay() } }
  @IBInspectable public var axisString: String {
    get { return axis.rawValue }
    set { axis = Axis(rawValue: newValue) ?? .Horizontal }
  }

  // MARK: - Images

  private var _thumbImage: UIImage? { didSet { setNeedsDisplay() } }
  @IBInspectable public var thumbImage: UIImage? {
    get { return _thumbImage }
    set { _thumbImage = newValue?.imageWithColor(thumbColor) }
  }
  private var _trackMinImage: UIImage? { didSet { setNeedsDisplay() } }
  @IBInspectable public var trackMinImage: UIImage? {
    get { return _trackMinImage }
    set { _trackMinImage = newValue?.imageWithColor(trackMinColor) }
  }
  private var _trackMaxImage: UIImage? { didSet { setNeedsDisplay() } }
  @IBInspectable public var trackMaxImage: UIImage? {
    get { return _trackMaxImage }
    set { _trackMaxImage = newValue?.imageWithColor(trackMaxColor) }
  }

  // MARK: - Colors

  @IBInspectable public var thumbColor: UIColor = .whiteColor() { 
    didSet {
      guard oldValue != thumbColor else { return }
      _thumbImage = _thumbImage?.imageWithColor(thumbColor)
    }
  }
  @IBInspectable public var trackMinColor: UIColor = rgb(29, 143, 236) {
    didSet {
      guard oldValue != trackMinColor else { return }
      _trackMinImage = _trackMinImage?.imageWithColor(trackMinColor)
    }
  }
  @IBInspectable public var trackMaxColor: UIColor = rgb(184, 184, 184) {
    didSet {
      guard oldValue != trackMaxColor else { return }
      _trackMaxImage = _trackMaxImage?.imageWithColor(trackMaxColor)
    }
  }
  @IBInspectable public var valueLabelTextColor: UIColor = .blackColor() {
    didSet { guard showsValueLabel && oldValue != valueLabelTextColor else { return }; setNeedsDisplay() }
  }
  @IBInspectable public var trackLabelTextColor: UIColor = .blackColor() {
    didSet { guard showsTrackLabel && oldValue != trackLabelTextColor else { return }; setNeedsDisplay() }
  }

  @IBInspectable public var tintColorAlpha: CGFloat = 0 {
    didSet {
      guard tintColorAlpha != oldValue else { return }
      tintColorAlpha = (0 ... 1).clampValue(tintColorAlpha)
      setNeedsDisplay()
    }
  }
  
  // MARK: - Offsets

  @IBInspectable public var thumbXOffset: CGFloat = 0 { 
    didSet { guard oldValue != thumbXOffset else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var thumbYOffset: CGFloat = 0 { 
    didSet { guard oldValue != thumbYOffset else { return }; setNeedsDisplay() } 
  }

  @IBInspectable public var trackXOffset: CGFloat = 0 { 
    didSet { guard oldValue != trackXOffset else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var trackYOffset: CGFloat = 0 { 
    didSet { guard oldValue != trackYOffset else { return }; setNeedsDisplay() } 
  }

  @IBInspectable public var valueLabelXOffset: CGFloat = 0 {
    didSet { guard showsValueLabel && oldValue != valueLabelXOffset else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var valueLabelYOffset: CGFloat = 0 { 
    didSet { guard showsValueLabel && oldValue != valueLabelYOffset else { return }; setNeedsDisplay() } 
  }

  @IBInspectable public var trackLabelXOffset: CGFloat = 0 { 
    didSet { guard showsTrackLabel && oldValue != trackLabelXOffset else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var trackLabelYOffset: CGFloat = 0 { 
    didSet { guard showsTrackLabel && oldValue != trackLabelYOffset else { return }; setNeedsDisplay() } 
  }

  // MARK: - Text

  @IBInspectable public var showsValueLabel: Bool = false {
    didSet { guard oldValue != showsValueLabel else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var valueLabelPrecision: Int = 2 { 
    didSet { guard showsValueLabel && oldValue != valueLabelPrecision else { return }; setNeedsDisplay() } 
  }

  public static let DefaultValueLabelFont = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
  @IBInspectable public var valueLabelFontName: String = DefaultValueLabelFont.fontName { 
    didSet { guard showsValueLabel && oldValue != valueLabelFontName else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var valueLabelFontSize: CGFloat = DefaultValueLabelFont.pointSize { 
    didSet { guard showsValueLabel && oldValue != valueLabelFontSize else { return }; setNeedsDisplay() } 
  }
  private var valueLabelFont: UIFont {
    return UIFont(name: valueLabelFontName, size: valueLabelFontSize) ?? Slider.DefaultValueLabelFont
  }

  @IBInspectable public var showsTrackLabel: Bool = true {
    didSet { guard oldValue != showsTrackLabel else { return }; setNeedsDisplay() } 
  }

  @IBInspectable public var trackLabelText: String? { 
    didSet { guard showsTrackLabel && oldValue != trackLabelText else { return }; setNeedsDisplay() } 
  }

  public static let DefaultTrackLabelFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
  @IBInspectable public var trackLabelFontName: String = DefaultTrackLabelFont.fontName { 
    didSet { guard showsTrackLabel && oldValue != trackLabelFontName else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var trackLabelFontSize: CGFloat = DefaultTrackLabelFont.pointSize { 
    didSet { guard showsTrackLabel && oldValue != trackLabelFontSize else { return }; setNeedsDisplay() } 
  }
  private var trackLabelFont: UIFont {
    return UIFont(name: trackLabelFontName, size: trackLabelFontSize) ?? Slider.DefaultTrackLabelFont
  }

  // MARK: - Sizes

  @IBInspectable public var trackMinBreadth: CGFloat = 4 { 
    didSet { guard oldValue != trackMinBreadth else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var preservesTrackMinImageSize: Bool = false { 
    didSet { guard oldValue != preservesTrackMinImageSize else { return }; setNeedsDisplay() } 
  }

  private var _trackMinBreadth: CGFloat {
    guard preservesTrackMinImageSize, let trackMinImage = trackMinImage else { return trackMinBreadth }
    return axis == .Horizontal ? trackMinImage.size.height : trackMinImage.size.width
  }

  @IBInspectable public var trackMaxBreadth: CGFloat = 4 { 
    didSet { guard oldValue != trackMaxBreadth else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var preservesTrackMaxImageSize: Bool = false { 
    didSet { guard oldValue != preservesTrackMaxImageSize else { return }; setNeedsDisplay() } 
  }

  private var _trackMaxBreadth: CGFloat {
    guard preservesTrackMaxImageSize, let trackMaxImage = trackMaxImage else { return trackMaxBreadth }
    return axis == .Horizontal ? trackMaxImage.size.height : trackMaxImage.size.width
  }

  @IBInspectable public var thumbSize: CGSize = CGSize(square: 43) { 
    didSet { guard oldValue != thumbSize else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var preservesThumbImageSize: Bool = false { 
    didSet { guard oldValue != preservesThumbImageSize else { return }; setNeedsDisplay() } 
  }

  private var _thumbSize: CGSize {
    guard preservesThumbImageSize, let thumbImage = thumbImage else { return thumbSize }
    return thumbImage.size
  }

  // MARK: - Alignment

  @IBInspectable public var alignmentRectInsetsString: String? {
    didSet {
      guard alignmentRectInsetsString != oldValue else { return }
      setNeedsLayout()
    }
  }

  /**
  alignmentRectInsets

  - returns: UIEdgeInsets
  */
  public override func alignmentRectInsets() -> UIEdgeInsets {
    let defaultInsets = axis == .Horizontal
                          ? UIEdgeInsets(horizontal: half(_thumbSize.width - 1), vertical: 0)
                          : UIEdgeInsets(horizontal: 0, vertical: half(_thumbSize.height - 1))
    guard let string = alignmentRectInsetsString, insets = UIEdgeInsets(string) else { return defaultInsets }
    
    return defaultInsets + insets
  }

  // MARK: - Values

  @IBInspectable public var value: Float = 0 { didSet { guard oldValue != value else { return }; setNeedsDisplay() } }
  @IBInspectable public var minimumValue: Float = 0
  @IBInspectable public var maximumValue: Float = 1

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override public func intrinsicContentSize() -> CGSize {
    switch axis {
      case .Horizontal: return CGSize(width: 150, height: _thumbSize.height)
      case .Vertical: return CGSize(width: _thumbSize.width, height: 150)
    }
  }

  private var valueInterval: ClosedInterval<Float> {
    guard minimumValue < maximumValue else { return 0 ... 1 }
    return minimumValue ... maximumValue
  }

  // MARK: - Initializing

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame) }


  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeObject(showsValueLabel,              forKey: "showsValueLabel")
    aCoder.encodeObject(showsTrackLabel,              forKey: "showsTrackLabel")
    aCoder.encodeObject(thumbXOffset,                 forKey: "thumbXOffset")
    aCoder.encodeObject(thumbYOffset,                 forKey: "thumbYOffset")
    aCoder.encodeObject(valueLabelXOffset,            forKey: "valueLabelXOffset")
    aCoder.encodeObject(valueLabelYOffset,            forKey: "valueLabelYOffset")
    aCoder.encodeObject(valueLabelFontName,           forKey: "valueLabelFontName")
    aCoder.encodeObject(valueLabelFontSize,           forKey: "valueLabelFontSize")
    aCoder.encodeObject(valueLabelTextColor,          forKey: "valueLabelTextColor")
    aCoder.encodeObject(trackLabelXOffset,            forKey: "trackLabelXOffset")
    aCoder.encodeObject(trackLabelYOffset,            forKey: "trackLabelYOffset")
    aCoder.encodeObject(trackXOffset,                 forKey: "trackXOffset")
    aCoder.encodeObject(trackYOffset,                 forKey: "trackYOffset")
    aCoder.encodeObject(trackLabelFontName,           forKey: "trackLabelFontName")
    aCoder.encodeObject(trackLabelFontSize,           forKey: "trackLabelFontSize")
    aCoder.encodeObject(trackLabelTextColor,          forKey: "trackLabelTextColor")
    aCoder.encodeObject(minimumValue,                 forKey: "minimumValue")
    aCoder.encodeObject(maximumValue,                 forKey: "maximumValue")
    aCoder.encodeObject(thumbImage,                   forKey: "thumbImage")
    aCoder.encodeObject(trackMinImage,                forKey: "trackMinImage")
    aCoder.encodeObject(trackMaxImage,                forKey: "trackMaxImage")
    aCoder.encodeObject(thumbColor,                   forKey: "thumbColor")
    aCoder.encodeObject(trackMinColor,                forKey: "trackMinColor")
    aCoder.encodeObject(trackMaxColor,                forKey: "trackMaxColor")
    aCoder.encodeObject(preservesTrackMinImageSize,   forKey: "preservesTrackMinImageSize")
    aCoder.encodeObject(preservesTrackMaxImageSize,   forKey: "preservesTrackMaxImageSize")
    aCoder.encodeObject(preservesThumbImageSize,      forKey: "preservesThumbImageSize")
    aCoder.encodeObject(valueLabelPrecision,          forKey: "valueLabelPrecision")
    aCoder.encodeObject(trackMinBreadth,              forKey: "trackMinBreadth")
    aCoder.encodeObject(trackMaxBreadth,              forKey: "trackMaxBreadth")
    aCoder.encodeObject(NSValue(CGSize: thumbSize),   forKey: "thumbSize")
    aCoder.encodeObject(trackLabelText,               forKey: "trackLabelText")
    aCoder.encodeObject(axisString,                   forKey: "axisString")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    if aDecoder.containsValueForKey("continuous") { continuous = aDecoder.decodeBoolForKey("continuous") }
    if aDecoder.containsValueForKey("showsValueLabel") { showsValueLabel = aDecoder.decodeBoolForKey("showsValueLabel") }
    if aDecoder.containsValueForKey("showsTrackLabel") { showsTrackLabel = aDecoder.decodeBoolForKey("showsTrackLabel") }
    if aDecoder.containsValueForKey("thumbXOffset") { thumbXOffset = CGFloat(aDecoder.decodeFloatForKey("thumbXOffset")) }
    if aDecoder.containsValueForKey("thumbYOffset") { thumbYOffset = CGFloat(aDecoder.decodeFloatForKey("thumbYOffset")) }
    if aDecoder.containsValueForKey("valueLabelXOffset") { 
      valueLabelXOffset = CGFloat(aDecoder.decodeFloatForKey("valueLabelXOffset")) 
    }
    if aDecoder.containsValueForKey("valueLabelYOffset") { 
      valueLabelYOffset = CGFloat(aDecoder.decodeFloatForKey("valueLabelYOffset")) 
    }
    if aDecoder.containsValueForKey("valueLabelFontName") {
      valueLabelFontName = aDecoder.decodeObjectForKey("valueLabelFontName") as? String ?? Slider.DefaultValueLabelFont.fontName
    }
    if aDecoder.containsValueForKey("valueLabelFontSize") {
      valueLabelFontSize = CGFloat(aDecoder.decodeFloatForKey("valueLabelFontSize"))
    }
    if aDecoder.containsValueForKey("valueLabelTextColor") {
      valueLabelTextColor = aDecoder.decodeObjectForKey("valueLabelTextColor") as? UIColor ?? .blackColor() 
    }
    if aDecoder.containsValueForKey("trackLabelXOffset") { 
      trackLabelXOffset = CGFloat(aDecoder.decodeFloatForKey("trackLabelXOffset")) 
    }
    if aDecoder.containsValueForKey("trackLabelYOffset") { 
      trackLabelYOffset = CGFloat(aDecoder.decodeFloatForKey("trackLabelYOffset")) 
    }
    if aDecoder.containsValueForKey("trackXOffset") { trackXOffset = CGFloat(aDecoder.decodeFloatForKey("trackXOffset")) }
    if aDecoder.containsValueForKey("trackYOffset") { trackYOffset = CGFloat(aDecoder.decodeFloatForKey("trackYOffset")) }
    if aDecoder.containsValueForKey("trackLabelFontName") {
      trackLabelFontName = aDecoder.decodeObjectForKey("trackLabelFontName") as? String ?? Slider.DefaultTrackLabelFont.fontName
    }
    if aDecoder.containsValueForKey("trackLabelFontSize") {
      trackLabelFontSize = CGFloat(aDecoder.decodeFloatForKey("trackLabelFontSize"))
    }
    if aDecoder.containsValueForKey("trackLabelTextColor") {
      trackLabelTextColor = aDecoder.decodeObjectForKey("trackLabelTextColor") as? UIColor ?? .blackColor() 
    }
    if aDecoder.containsValueForKey("minimumValue") { minimumValue = aDecoder.decodeFloatForKey("minimumValue") }
    if aDecoder.containsValueForKey("maximumValue") { maximumValue = aDecoder.decodeFloatForKey("maximumValue") }
    if aDecoder.containsValueForKey("thumbImage") {
      thumbImage = aDecoder.decodeObjectForKey("thumbImage") as? UIImage 
    }
    if aDecoder.containsValueForKey("trackMinImage") { trackMinImage = aDecoder.decodeObjectForKey("trackMinImage") as? UIImage }
    if aDecoder.containsValueForKey("trackMaxImage") { trackMaxImage = aDecoder.decodeObjectForKey("trackMaxImage") as? UIImage }
    if aDecoder.containsValueForKey("thumbColor") {
      thumbColor = aDecoder.decodeObjectForKey("thumbColor") as? UIColor ?? .whiteColor() 
    }
    if aDecoder.containsValueForKey("trackMinColor") {
      trackMinColor = aDecoder.decodeObjectForKey("trackMinColor") as? UIColor ?? rgb(29, 143, 236) 
    }
    if aDecoder.containsValueForKey("trackMaxColor") {
      trackMaxColor = aDecoder.decodeObjectForKey("trackMaxColor") as? UIColor ?? rgb(184, 184, 184) 
    }
    if aDecoder.containsValueForKey("preservesTrackMinImageSize") {
      preservesTrackMinImageSize = aDecoder.decodeBoolForKey("preservesTrackMinImageSize")
    }
    if aDecoder.containsValueForKey("preservesTrackMaxImageSize") {
      preservesTrackMaxImageSize = aDecoder.decodeBoolForKey("preservesTrackMaxImageSize")
    }
    if aDecoder.containsValueForKey("preservesThumbImageSize") {
      preservesThumbImageSize = aDecoder.decodeBoolForKey("preservesThumbImageSize")
    }
    if aDecoder.containsValueForKey("valueLabelPrecision") {
      valueLabelPrecision = (aDecoder.decodeObjectForKey("valueLabelPrecision") as? NSNumber)?.integerValue ?? 2 
    }
    if aDecoder.containsValueForKey("trackMinBreadth") { trackMinBreadth = CGFloat(aDecoder.decodeFloatForKey("trackMinBreadth")) }
    if aDecoder.containsValueForKey("trackMaxBreadth") { trackMaxBreadth = CGFloat(aDecoder.decodeFloatForKey("trackMaxBreadth")) }
    if aDecoder.containsValueForKey("thumbSize") { thumbSize = aDecoder.decodeCGSizeForKey("thumbSize") }
    if aDecoder.containsValueForKey("trackLabelText") { trackLabelText = aDecoder.decodeObjectForKey("trackLabelText") as? String }
    if aDecoder.containsValueForKey("axisString") {
      axisString = aDecoder.decodeObjectForKey("axisString") as? String ?? Axis.Horizontal.rawValue 
    }
  }

  // MARK: - Drawing

  /**
  drawRect:

  - parameter rect: CGRect
  */
  override public func drawRect(var rect: CGRect) {
    guard rect == bounds else { fatalError("wtf") }
    rect = bounds

    // Get a reference to the current context
    let context = UIGraphicsGetCurrentContext()

    // Save the context
    CGContextSaveGState(context)

    // Make sure our rect is clear
    CGContextClearRect(context, rect)

    // Get the track heights and thumb size to use for drawing
    let trackMinBreadth = _trackMinBreadth, trackMaxBreadth = _trackMaxBreadth, thumbSize = _thumbSize + 1

    let trackMinFrame: CGRect, trackMaxFrame: CGRect, thumbFrame: CGRect

    switch axis {
    case .Horizontal:
      // Inset the drawing rect to allow room for thumb at both ends of track
      let insetFrame = rect.insetBy(dx: half(thumbSize.width), dy: 0)

      // Create an interval to work with representing the track's width
      let trackInterval: ClosedInterval<CGFloat> = insetFrame.minX ... insetFrame.maxX

      // Get the value as a number between 0 and 1
      let normalizedValue = CGFloat(valueInterval.normalizeValue(value))

      // Calculate the widths of the track segments
      let trackMinLength = round(trackInterval.diameter * normalizedValue)
      let trackMaxLength = round(trackInterval.diameter - trackMinLength)

      // Create some sizes
      let trackMinSize = CGSize(width: trackMinLength, height: trackMinBreadth)
      let trackMaxSize = CGSize(width: trackMaxLength, height: trackMaxBreadth)

      // Calculate the x value where min becomes max
      let minToMax = trackMinLength + trackInterval.start

      // Create some origins
      let trackMinOrigin = CGPoint(x: trackInterval.start, y: rect.midY - half(trackMinBreadth))
      let trackMaxOrigin = CGPoint(x: minToMax, y: rect.midY - half(trackMaxBreadth))
      let thumbOrigin = CGPoint(x: minToMax - half(thumbSize.width), y: rect.midY - half(thumbSize.height))

      // Create the frames for the track segments and the thumb
      trackMinFrame = CGRect(origin: trackMinOrigin.offsetBy(dx: trackXOffset, dy: trackYOffset), size: trackMinSize)
      trackMaxFrame = CGRect(origin: trackMaxOrigin.offsetBy(dx: trackXOffset, dy: trackYOffset), size: trackMaxSize)
      thumbFrame = CGRect(origin: thumbOrigin, size: thumbSize).offsetBy(dx: thumbXOffset, dy: thumbYOffset)
    case .Vertical:
      // Inset the drawing rect to allow room for thumb at both ends of track
      let insetFrame = rect.insetBy(dx: 0, dy: half(thumbSize.height))

      // Create an interval to work with representing the track's width
      let trackInterval = ReverseClosedInterval<CGFloat>(insetFrame.maxY, insetFrame.minY)

      // Get the value as a number between 0 and 1
      let normalizedValue = CGFloat(valueInterval.normalizeValue(value))

      // Calculate the widths of the track segments
      let trackMinLength = round(trackInterval.diameter * normalizedValue)
      let trackMaxLength = round(trackInterval.diameter - trackMinLength)

      // Create some sizes
      let trackMinSize = CGSize(width: trackMinBreadth, height: trackMinLength)
      let trackMaxSize = CGSize(width: trackMaxBreadth, height: trackMaxLength)

      // Calculate the x value where min becomes max
      let minToMax = trackInterval.start - trackMinLength

      // Create some origins
      let trackMinOrigin = CGPoint(x: rect.midX - half(trackMinBreadth), y: minToMax)
      let trackMaxOrigin = CGPoint(x: rect.midX - half(trackMaxBreadth), y: trackInterval.end)
      let thumbOrigin = CGPoint(x: rect.midX - half(thumbSize.width), y: minToMax - half(thumbSize.height))

      // Create the frames for the track segments and the thumb
      trackMinFrame = CGRect(origin: trackMinOrigin.offsetBy(dx: trackXOffset, dy: trackYOffset), size: trackMinSize)
      trackMaxFrame = CGRect(origin: trackMaxOrigin.offsetBy(dx: trackXOffset, dy: trackYOffset), size: trackMaxSize)
      thumbFrame = CGRect(origin: thumbOrigin, size: thumbSize).offsetBy(dx: thumbXOffset, dy: thumbYOffset)
    }


    // Draw the track segments
    if let trackMinImage = trackMinImage, trackMaxImage = trackMaxImage {
      trackMinColor.setFill()
      trackMinImage.drawAsPatternInRect(trackMinFrame)
      trackMaxColor.setFill()
      trackMaxImage.drawAsPatternInRect(trackMaxFrame)
    } else {
      trackMinColor.setFill()
      UIRectFill(trackMinFrame)
      trackMaxColor.setFill()
      UIRectFill(trackMaxFrame)
    }

    // Draw the track label
    if showsTrackLabel, let text = trackLabelText {
      let attributes = [NSFontAttributeName: trackLabelFont, NSForegroundColorAttributeName: trackLabelTextColor]
      let textSize = text.sizeWithAttributes(attributes)
      let center = axis == .Horizontal
                     ? CGPoint(x: rect.midX, y: trackMinFrame.center.y)
                     : CGPoint(x: trackMinFrame.center.x, y: frame.midY)
      let textFrame = CGRect(size: textSize, center: center).offsetBy(dx: trackLabelXOffset, dy: trackLabelYOffset)
      CGContextSaveGState(context)
      CGContextSetBlendMode(context, .Clear)
      text.drawInRect(textFrame, withAttributes: attributes)
      CGContextRestoreGState(context)
    }

    // Draw the thumb
    if let thumbImage = thumbImage {
      thumbColor.setFill()
      thumbImage.drawInRect(thumbFrame)
    } else {
      thumbColor.setFill()
      trackMaxColor.setStroke()
      let thumbPath = UIBezierPath(ovalInRect: thumbFrame)
      thumbPath.fill()
      thumbPath.stroke()
    }

    // Draw the value label
    if showsValueLabel {
      let text = String(value, precision: valueLabelPrecision)
      let attributes = [NSFontAttributeName: valueLabelFont, NSForegroundColorAttributeName: valueLabelTextColor]
      let textSize = text.sizeWithAttributes(attributes)
      let textFrame = CGRect(size: textSize, center: thumbFrame.center).offsetBy(dx: valueLabelXOffset, dy: valueLabelYOffset)

      text.drawInRect(textFrame, withAttributes: attributes)
    }

    if tintColorAlpha > 0 {
      tintColor.colorWithAlpha(tintColorAlpha).setFill()

      if let trackMinImage = trackMinImage, trackMaxImage = trackMaxImage, thumbImage = thumbImage {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        trackMinImage.drawAsPatternInRect(trackMinFrame)
        trackMaxImage.drawAsPatternInRect(trackMaxFrame)
        thumbImage.drawInRect(thumbFrame)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { logError("Failed to produce image from context"); return }
        UIGraphicsEndImageContext()
        image.addClip()
        UIRectFillUsingBlendMode(rect, .Color)
      } else {
        UIRectFillUsingBlendMode(trackMinFrame, .Color)
        UIRectFillUsingBlendMode(trackMaxFrame, .Color)
        UIBezierPath(ovalInRect: thumbFrame).addClip()
        UIRectFillUsingBlendMode(thumbFrame, .Color)
      }
    }

    // Restore the context to previous state
    CGContextRestoreGState(context)
  }

  // MARK: - Touch handling

  @IBInspectable var continuous: Bool = true

  private var touch: UITouch?
  private var touchTime: NSTimeInterval = 0
  private var touchInterval: ClosedInterval<Float>  {
    return axis == .Horizontal ? Float(frame.minX) ... Float(frame.maxX) : Float(frame.minY) ... Float(frame.maxY)
  }

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard self.touch == nil,
      let touch = touches.filter({self.pointInside($0.locationInView(self), withEvent: event)}).first else { return }
    self.touch = touch
  }

  /**
  updateValueForTouch:

  - parameter touch: UITouch
  */
  private func updateValueForTouch(touch: UITouch, sendActions: Bool) {
    guard touchTime != touch.timestamp else { return }

    let location = touch.locationInView(self)
    let previousLocation = touch.previousLocationInView(self)

    let delta: CGFloat, distance: CGFloat
    let distanceInterval: ClosedInterval<CGFloat>
    switch axis {
    case .Horizontal:
      delta = (location - previousLocation).x
      distanceInterval = bounds.minY ... bounds.maxY
      distance = location.y
    case .Vertical:
      delta = (previousLocation - location).y
      distanceInterval = bounds.minX ... bounds.maxX
      distance = location.x
    }

    guard delta != 0 else { return }

    let valueInterval = self.valueInterval, touchInterval = self.touchInterval

    let newValue = valueInterval.mapValue(touchInterval.mapValue(value, from: valueInterval) + Float(delta), from: touchInterval)

    var valueDelta = value - newValue

    if !distanceInterval.contains(distance) {
      let clampedDistance = distanceInterval.clampValue(distance)
      let deltaDistance = max(Float(abs(distance - clampedDistance)), 1)
      valueDelta *= 1 / deltaDistance
    }

    value -= valueDelta
    touchTime = touch.timestamp
    sendActionsForControlEvents(.ValueChanged)

  }

  /**
  touchesMoved:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = self.touch where touches.contains(touch) else { return }
    updateValueForTouch(touch, sendActions: continuous)
  }

  /**
  touchesCancelled:withEvent:

  - parameter touches: Set<UITouch>?
  - parameter event: UIEvent?
  */
  public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    guard let touch = self.touch where touches?.contains(touch) == true else { return }
    self.touch = nil
  }

  /**
  touchesEnded:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = self.touch where touches.contains(touch) else { return }
    updateValueForTouch(touch, sendActions: true)
    self.touch = nil
  }

}