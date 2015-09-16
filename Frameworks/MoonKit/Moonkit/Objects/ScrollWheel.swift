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

  @IBInspectable public var theta: CGFloat = 0 { didSet { setNeedsDisplay() } }
  @IBInspectable public var value: Float = 0
  @IBInspectable public var wheelBaseImage: UIImage? { didSet { setNeedsDisplay() } }
  @IBInspectable public var dimpleImage: UIImage? { didSet { setNeedsDisplay() } }
  @IBInspectable public var wheelBaseColor: UIColor = .darkGrayColor() {
    didSet {
      wheelBaseImage = wheelBaseImage?.imageWithColor(wheelBaseColor)
      setNeedsDisplay()
    }
  }
  @IBInspectable public var dimpleColor:  UIColor = .lightGrayColor() {
    didSet {
      dimpleImage = dimpleImage?.imageWithColor(dimpleColor)
      setNeedsDisplay()
    }
  }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {
    var frame = rect.insetBy(dx: 2, dy: 2)
    if frame.size.width != frame.size.height {
      frame.size = CGSize(square: frame.size.minAxis)
      frame.origin += (rect.size - frame.size) * 0.5
    }

    let context = UIGraphicsGetCurrentContext()
    CGContextSaveGState(context)
    CGContextTranslateCTM(context, half(frame.width), half(frame.height))
    CGContextRotateCTM(context, theta)

    let baseFrame = CGRect(origin: frame.origin - (frame.size * 0.5),  size: frame.size).integral
    if let wheelBase = wheelBaseImage {
      wheelBase.drawInRect(baseFrame)
    } else {
      wheelBaseColor.setFill()
      UIBezierPath(ovalInRect: baseFrame).fill()
    }

    let dimpleSize = baseFrame.size * 0.35
    let dimpleFrame = CGRect(origin: CGPoint(x: -half(dimpleSize.width), y: baseFrame.origin.y + 4), size: dimpleSize)
    if let dimple = dimpleImage {
      dimple.drawInRect(dimpleFrame)
    } else {
      dimpleColor.setFill()
      UIBezierPath(ovalInRect: dimpleFrame).fill()
    }

    CGContextRestoreGState(context)
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