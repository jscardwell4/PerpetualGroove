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

/** @IBDesignable */ public class Slider: UIControl {

  // MARK: - Images

  @IBInspectable public var thumbImage: UIImage? { 
    didSet { guard oldValue != thumbImage else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var trackMinImage: UIImage? { 
    didSet { guard oldValue != trackMinImage else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var trackMaxImage: UIImage? { 
    didSet { guard oldValue != trackMaxImage else { return }; setNeedsDisplay() } 
  }

  // MARK: - Colors

  @IBInspectable public var thumbColor: UIColor = .whiteColor() { 
    didSet { guard oldValue != thumbColor else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var trackMinColor: UIColor = rgb(29, 143, 236) {
    didSet { guard oldValue != trackMinColor else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var trackMaxColor: UIColor = rgb(184, 184, 184) {
    didSet { guard oldValue != trackMaxColor else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var valueLabelTextColor: UIColor = .blackColor() {
    didSet { guard showsValueLabel && oldValue != valueLabelTextColor else { return }; setNeedsDisplay() }
  }
  @IBInspectable public var trackLabelTextColor: UIColor = .blackColor() {
    didSet { guard showsTrackLabel && oldValue != trackLabelTextColor else { return }; setNeedsDisplay() }
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

  @IBInspectable public var trackMinHeight: CGFloat = 4 { 
    didSet { guard oldValue != trackMinHeight else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var preservesTrackMinImageHeight: Bool = false { 
    didSet { guard oldValue != preservesTrackMinImageHeight else { return }; setNeedsDisplay() } 
  }

  private var _trackMinHeight: CGFloat {
    guard preservesTrackMinImageHeight, let trackMinImage = trackMinImage else { return trackMinHeight }
    return trackMinImage.size.height
  }

  @IBInspectable public var trackMaxHeight: CGFloat = 4 { 
    didSet { guard oldValue != trackMaxHeight else { return }; setNeedsDisplay() } 
  }
  @IBInspectable public var preservesTrackMaxImageHeight: Bool = false { 
    didSet { guard oldValue != preservesTrackMaxImageHeight else { return }; setNeedsDisplay() } 
  }

  private var _trackMaxHeight: CGFloat {
    guard preservesTrackMaxImageHeight, let trackMaxImage = trackMaxImage else { return trackMaxHeight }
    return trackMaxImage.size.height
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

  // MARK: - Values

  @IBInspectable public var value: Float = 0 { didSet { guard oldValue != value else { return }; setNeedsDisplay() } }
  @IBInspectable public var minimumValue: Float = 0

  @IBInspectable public var maximumValue: Float = 1

  override public func intrinsicContentSize() -> CGSize {
    return CGSize(square: max(max(_trackMinHeight, _trackMaxHeight), _thumbSize.height))
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
    aCoder.encodeObject(preservesTrackMinImageHeight, forKey: "preservesTrackMinImageHeight")
    aCoder.encodeObject(preservesTrackMaxImageHeight, forKey: "preservesTrackMaxImageHeight")
    aCoder.encodeObject(preservesThumbImageSize,      forKey: "preservesThumbImageSize")
    aCoder.encodeObject(valueLabelPrecision,          forKey: "valueLabelPrecision")
    aCoder.encodeObject(trackMinHeight,               forKey: "trackMinHeight")
    aCoder.encodeObject(trackMaxHeight,               forKey: "trackMaxHeight")
    aCoder.encodeObject(NSValue(CGSize: thumbSize),   forKey: "thumbSize")
    aCoder.encodeObject(trackLabelText,               forKey: "trackLabelText")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    showsValueLabel              = (aDecoder.decodeObjectForKey("showsValueLabel") as? NSNumber)?.boolValue ?? false
    showsTrackLabel              = (aDecoder.decodeObjectForKey("showsTrackLabel") as? NSNumber)?.boolValue ?? false
    thumbXOffset                 = CGFloat((aDecoder.decodeObjectForKey("thumbXOffset") as? NSNumber)?.floatValue ?? 0)
    thumbYOffset                 = CGFloat((aDecoder.decodeObjectForKey("thumbYOffset") as? NSNumber)?.floatValue ?? 0)
    valueLabelXOffset            = CGFloat((aDecoder.decodeObjectForKey("valueLabelXOffset") as? NSNumber)?.floatValue ?? 0)
    valueLabelYOffset            = CGFloat((aDecoder.decodeObjectForKey("valueLabelYOffset") as? NSNumber)?.floatValue ?? 0)
    valueLabelFontName           = aDecoder.decodeObjectForKey("valueLabelFontName") as? String
                                     ?? Slider.DefaultValueLabelFont.fontName
    valueLabelFontSize           = CGFloat((aDecoder.decodeObjectForKey("valueLabelFontSize") as? NSNumber)?.floatValue
                                     ?? Slider.DefaultValueLabelFont.pointSize)
    valueLabelTextColor          = aDecoder.decodeObjectForKey("valueLabelTextColor") as? UIColor ?? .blackColor()
    trackLabelXOffset            = CGFloat((aDecoder.decodeObjectForKey("trackLabelXOffset") as? NSNumber)?.floatValue ?? 0)
    trackLabelYOffset            = CGFloat((aDecoder.decodeObjectForKey("trackLabelYOffset") as? NSNumber)?.floatValue ?? 0)
    trackXOffset                 = CGFloat((aDecoder.decodeObjectForKey("trackXOffset") as? NSNumber)?.floatValue ?? 0)
    trackYOffset                 = CGFloat((aDecoder.decodeObjectForKey("trackYOffset") as? NSNumber)?.floatValue ?? 0)
    trackLabelFontName           = aDecoder.decodeObjectForKey("trackLabelFontName") as? String
                                     ?? Slider.DefaultTrackLabelFont.fontName
    trackLabelFontSize           = CGFloat((aDecoder.decodeObjectForKey("trackLabelFontSize") as? NSNumber)?.floatValue
                                     ?? Slider.DefaultTrackLabelFont.pointSize)
    trackLabelTextColor          = aDecoder.decodeObjectForKey("trackLabelTextColor") as? UIColor ?? .blackColor()
    minimumValue                 = (aDecoder.decodeObjectForKey("minimumValue") as? NSNumber)?.floatValue ?? 0
    maximumValue                 = (aDecoder.decodeObjectForKey("maximumValue") as? NSNumber)?.floatValue ?? 1
    thumbImage                   = aDecoder.decodeObjectForKey("thumbImage") as? UIImage
    trackMinImage                = aDecoder.decodeObjectForKey("trackMinImage") as? UIImage
    trackMaxImage                = aDecoder.decodeObjectForKey("trackMaxImage") as? UIImage
    thumbColor                   = aDecoder.decodeObjectForKey("thumbColor") as? UIColor ?? .whiteColor()
    trackMinColor                = aDecoder.decodeObjectForKey("trackMinColor") as? UIColor ?? rgb(29, 143, 236)
    trackMaxColor                = aDecoder.decodeObjectForKey("trackMaxColor") as? UIColor ?? rgb(184, 184, 184)
    preservesTrackMinImageHeight = (aDecoder.decodeObjectForKey("preservesTrackMinImageHeight") as? NSNumber)?.boolValue ?? false
    preservesTrackMaxImageHeight = (aDecoder.decodeObjectForKey("preservesTrackMaxImageHeight") as? NSNumber)?.boolValue ?? false
    preservesThumbImageSize      = (aDecoder.decodeObjectForKey("preservesThumbImageSize") as? NSNumber)?.boolValue ?? false
    valueLabelPrecision          = (aDecoder.decodeObjectForKey("valueLabelPrecision") as? NSNumber)?.integerValue ?? 2
    trackMinHeight               = CGFloat((aDecoder.decodeObjectForKey("trackMinHeight") as? NSNumber)?.floatValue ?? 4)
    trackMaxHeight               = CGFloat((aDecoder.decodeObjectForKey("trackMaxHeight") as? NSNumber)?.floatValue ?? 4)
    thumbSize                    = (aDecoder.decodeObjectForKey("thumbSize") as? NSValue)?.CGSizeValue() ?? CGSize(square: 43)
    trackLabelText               = aDecoder.decodeObjectForKey("trackLabelText") as? String
  }

  // MARK: - Drawing

  /**
  drawRect:

  - parameter rect: CGRect
  */
  override public func drawRect(var rect: CGRect) {

    rect = bounds

    // Get a reference to the current context
    let context = UIGraphicsGetCurrentContext()

    // Save the context
    CGContextSaveGState(context)

    // Make sure our rect is clear
    CGContextClearRect(context, rect)

    // Get the track heights and thumb size to use for drawing
    let trackMinHeight = _trackMinHeight, trackMaxHeight = _trackMaxHeight, thumbSize = _thumbSize + 1

    // Inset the drawing rect to allow room for thumb at both ends of track
    let insetFrame = rect.insetBy(dx: half(thumbSize.width), dy: 0)

    // Create an interval to work with representing the track's width
    let trackInterval: ClosedInterval<CGFloat> = insetFrame.minX ... insetFrame.maxX

    // Get the value as a number between 0 and 1
    let normalizedValue = CGFloat(valueInterval.normalizeValue(value))

    // Calculate the widths of the track segments
    let trackMinWidth = round(trackInterval.diameter * normalizedValue)
    let trackMaxWidth = round(trackInterval.diameter - trackMinWidth)

    // Create some sizes
    let trackMinSize = CGSize(width: trackMinWidth, height: trackMinHeight)
    let trackMaxSize = CGSize(width: trackMaxWidth, height: trackMaxHeight)

    // Calculate the x value where min becomes max
    let minToMax = trackMinWidth + trackInterval.start

    // Create some origins
    let trackMinOrigin = CGPoint(x: trackInterval.start, y: rect.midY - half(trackMinHeight))
    let trackMaxOrigin = CGPoint(x: minToMax, y: rect.midY - half(trackMaxHeight))
    let thumbOrigin = CGPoint(x: minToMax - half(thumbSize.width), y: rect.midY - half(thumbSize.height))

    // Create the frames for the track segments and the thumb
    let trackMinFrame = CGRect(origin: trackMinOrigin, size: trackMinSize).offsetBy(dx: trackXOffset, dy: trackYOffset)
    let trackMaxFrame = CGRect(origin: trackMaxOrigin, size: trackMaxSize).offsetBy(dx: trackXOffset, dy: trackYOffset)
    let thumbFrame = CGRect(origin: thumbOrigin, size: thumbSize).offsetBy(dx: thumbXOffset, dy: thumbYOffset)


    // Draw the track segments
    if let trackMinImage = trackMinImage, trackMaxImage = trackMaxImage {
      trackMinColor.setFill()
      trackMinImage.drawInRect(trackMinFrame)
      trackMaxColor.setFill()
      trackMaxImage.drawInRect(trackMaxFrame)
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
      let center = CGPoint(x: rect.midX, y: trackMinFrame.center.y)
      let textFrame = CGRect(size: textSize, center: center).insetBy(dx: valueLabelXOffset, dy: valueLabelYOffset)
      text.drawInRect(textFrame, withAttributes: attributes)
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
      let textFrame = CGRect(size: textSize, center: thumbFrame.center).insetBy(dx: valueLabelXOffset, dy: valueLabelYOffset)

      text.drawInRect(textFrame, withAttributes: attributes)
    }

    // Restore the context to previous state
    CGContextRestoreGState(context)
  }

  // MARK: - Touch handling

  @IBInspectable var continuous: Bool = true

  private var touch: UITouch?
  private var touchInterval: ClosedInterval<Float>  { return Float(frame.minX) ... Float(frame.maxX) }

  /**
  updateValueFromTouch:

  - parameter touch: UITouch
  */
  private func updateValueFromTouch(touch: UITouch) {
    let location = touch.locationInView(self)
    let deltaX = location.x - touch.previousLocationInView(self).x
    let y = location.y
    guard deltaX != 0 else { return }
    let v = valueInterval, t = touchInterval
    let newValue = v.mapValue(t.mapValue(value, from: v) + Float(deltaX), from: t)
    var valueDelta = value - newValue
    if y < 0 {
      valueDelta *= 1 / max(Float(abs(y)), 1)
    }
    value -= valueDelta
    sendActionsForControlEvents(.ValueChanged)
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
  touchesMoved:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = self.touch where touches.contains(touch) else { return }
    updateValueFromTouch(touch)
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
//    updateValueFromTouch(touch)
    self.touch = nil
  }

}