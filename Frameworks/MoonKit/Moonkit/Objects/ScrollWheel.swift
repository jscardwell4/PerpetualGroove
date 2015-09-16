//
//  ScrollWheel.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/15/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit


/**
getAngle:p2:

- parameter p1: CGPoint
- parameter p2: CGPoint

- returns: CGFloat
*/
private func getAngle(point: CGPoint, center: CGPoint) -> CGFloat {
  let p = point - center
  let h = abs(sqrt(pow(p.x, 2) + pow(p.y, 2)))
  let angle = acos(p.x / h) * 180 / π
  return point.y > center.y ? angle : 360 - angle
}

/**
pointInsideRadius:r:center:

- parameter point: CGPoint
- parameter r: CGFloat
- parameter center: CGPoint

- returns: Bool
*/
private func pointInsideRadius(point: CGPoint, r: CGFloat, center: CGPoint) -> Bool {
  let p = point - center
  let xSquared = pow(p.x, 2)
  let ySquared = pow(p.y, 2)
  let h = abs(sqrt(xSquared + ySquared))
  return (xSquared + ySquared) / h < r
}

@IBDesignable public class ScrollWheel: UIControl {

  public var dimpleStyle: CGBlendMode = .Normal {
    didSet { guard oldValue != dimpleStyle else { return }; setNeedsDisplay() }
  }

  @IBInspectable public var dimpleStyleString: String {
    get { return dimpleStyle.stringValue }
    set { dimpleStyle = CGBlendMode(stringValue: newValue) }
  }

  public var dimpleFillStyle: CGBlendMode = .Normal {
    didSet { guard oldValue != dimpleFillStyle else { return }; setNeedsDisplay() }
  }

  @IBInspectable public var dimpleFillStyleString: String {
    get { return dimpleFillStyle.stringValue }
    set { dimpleFillStyle = CGBlendMode(stringValue: newValue) }
  }

  @IBInspectable public var theta: CGFloat = 0 { didSet { setNeedsDisplay() } }
  @IBInspectable public var value: Float = 0

  #if TARGET_INTERFACE_BUILDER
  @IBInspectable public override var highlighted: Bool { didSet { setNeedsDisplay() } }
  #endif

  @IBInspectable public var wheelImage: UIImage? {
    didSet { 
      guard oldValue != wheelImage else { return }
      wheelImage = wheelImage?.imageWithColor(wheelColor)
      setNeedsDisplay() 
    }
  }

  @IBInspectable public var wheelColor: UIColor = .darkGrayColor() {
    didSet { 
      guard oldValue != wheelColor else { return }
      wheelImage = wheelImage?.imageWithColor(wheelColor)
      setNeedsDisplay() 
    }
  }

  @IBInspectable public var dimpleImage: UIImage? {
    didSet { 
      guard oldValue != dimpleImage else { return }
      dimpleImage = dimpleImage?.imageWithColor(dimpleColor)
      dimpleHighlightedImage = dimpleImage?.imageWithColor(dimpleHighlightedColor)
      setNeedsDisplay() 
    }
  }
  private var dimpleHighlightedImage: UIImage?

  @IBInspectable public var dimpleFillImage: UIImage? {
    didSet {
      guard oldValue != dimpleFillImage else { return }
      dimpleFillImage = dimpleFillImage?.imageWithColor(dimpleColor)
      dimpleFillHighlightedImage = dimpleFillImage?.imageWithColor(dimpleHighlightedColor)
      setNeedsDisplay()
    }
  }
  private var dimpleFillHighlightedImage: UIImage?

  @IBInspectable public var dimpleColor:  UIColor = .lightGrayColor() {
    didSet { 
      guard oldValue != dimpleColor else { return }
      dimpleImage = dimpleImage?.imageWithColor(dimpleColor)
      setNeedsDisplay() 
    }
  }

  @IBInspectable public var dimpleHighlightedColor:  UIColor = .blueColor() {
    didSet {
      guard oldValue != dimpleHighlightedColor else { return }
      dimpleHighlightedImage = dimpleImage?.imageWithColor(dimpleHighlightedColor)
      dimpleFillHighlightedImage = dimpleFillImage?.imageWithColor(dimpleHighlightedColor)
      setNeedsDisplay()
    }
  }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {
    var frame = rect//.insetBy(dx: 2, dy: 2)
    if frame.size.width != frame.size.height {
      frame.size = CGSize(square: frame.size.minAxis)
      frame.origin += (rect.size - frame.size) * 0.5
    }

    let context = UIGraphicsGetCurrentContext()
    CGContextSaveGState(context)
    CGContextTranslateCTM(context, half(rect.width), half(rect.height))
    CGContextRotateCTM(context, theta)

    let baseFrame = CGRect(origin: frame.origin - (frame.size * 0.5),  size: frame.size).integral
    if let wheelBase = wheelImage {
      wheelBase.drawInRect(baseFrame)
    } else {
      wheelColor.setFill()
      UIBezierPath(ovalInRect: baseFrame).fill()
    }


    let dimpleSize = baseFrame.size * 0.35
    let dimpleFrame = CGRect(origin: CGPoint(x: -half(dimpleSize.width), y: baseFrame.origin.y + 4), size: dimpleSize)

    if let dimple = highlighted ? dimpleHighlightedImage : dimpleImage,
           dimpleFill = highlighted ? dimpleFillHighlightedImage : dimpleFillImage
    {

      CGContextSaveGState(context)
      UIBezierPath(ovalInRect: dimpleFrame).addClip()
      dimple.drawInRect(dimpleFrame, blendMode: dimpleStyle, alpha: 1)
      CGContextRestoreGState(context)

      let deltaSize = dimpleSize - dimpleFill.size
      let dimpleFillFrame = CGRect(origin: dimpleFrame.origin + deltaSize * 0.5, size: dimpleFill.size)//.insetBy(dx: 1, dy: 1)

      CGContextSaveGState(context)
      UIBezierPath(ovalInRect: dimpleFillFrame.insetBy(dx: 1, dy: 1)).addClip()
      dimpleFill.drawAtPoint(dimpleFillFrame.origin, blendMode: dimpleFillStyle, alpha: 1)
      CGContextRestoreGState(context)

    } else {
      (highlighted ? dimpleHighlightedColor : dimpleColor).setFill()
      UIBezierPath(ovalInRect: dimpleFrame).fill()
    }

    CGContextRestoreGState(context) // Matrix rotation
  }

  /**
  beginTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    let p = touch.locationInView(self)
    let cp = CGPoint((bounds.size * 0.5).unpack)
    guard pointInsideRadius(p, r: cp.x, center: cp) && !pointInsideRadius(p, r: 30, center: cp) else { return false }
    theta = getAngle(p, center: cp)
    sendActionsForControlEvents(.TouchDown)
    return true
  }

  /**
  continueTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    let p = touch.locationInView(self)
    let cp = CGPoint((bounds.size * 0.5).unpack)
    let events: UIControlEvents = frame.contains(p) ? .TouchDragInside : .TouchDragOutside
    sendActionsForControlEvents(events)

    guard pointInsideRadius(p, r: cp.x + 50, center: cp) else {
      // falls outside too far, with boundary of 50 pixels. Inside strokes treated as touched
      return false
    }

    let newTheta = getAngle(p, center: cp)
    var deltaTheta = newTheta - theta

    // correct for edge conditions
    var n = 0
    while abs(deltaTheta) > 360 && n++ < 4 { if deltaTheta > 0 { deltaTheta -= 360 } else { deltaTheta += 360 } }

    // Update current values
    value -= Float(deltaTheta / 360)
    theta = newTheta

    sendActionsForControlEvents(.ValueChanged)

    return true
  }

  /**
  endTrackingWithTouch:withEvent:

  - parameter touch: UITouch?
  - parameter event: UIEvent?
  */
  public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
    guard let touch = touch else { return }
    let events: UIControlEvents = bounds.contains(touch.locationInView(self)) ? .TouchUpInside : .TouchUpOutside
    sendActionsForControlEvents(events)
  }

  /**
  cancelTrackingWithEvent:

  - parameter event: UIEvent?
  */
  public override func cancelTrackingWithEvent(event: UIEvent?) {
    sendActionsForControlEvents(.TouchCancel)
  }
}