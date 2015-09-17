//
//  ScrollWheel.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/15/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable public class ScrollWheel: UIControl {

  /** 
  Layer subclass for encapsulating custom drawing and providing a level of separation between frames used for touch locations 
  and the use of transforms to rotate the visible content 
  */
  private final class WheelLayer: CALayer {

    private var wheelColorModified = false
    private var dimpleColorModified = false

    var wheelImage: UIImage? {
      didSet {
        guard wheelImage != oldValue && !wheelColorModified else { return }
        wheelImage = wheelImage?.imageWithColor(wheelColor)
        setNeedsDisplay()
      }
    }
    var dimpleImage: UIImage? {
      didSet {
        guard dimpleImage != oldValue && !dimpleColorModified else { return }
        dimpleImage = dimpleImage?.imageWithColor(dimpleColor)
        setNeedsDisplay()
      }
    }
    var dimpleFillImage: UIImage? {
      didSet {
        guard dimpleFillImage != oldValue && !dimpleColorModified else { return }
        dimpleFillImage = dimpleFillImage?.imageWithColor(dimpleColor)
        setNeedsDisplay()
      }
    }

    var wheelColor: UIColor = .darkGrayColor() {
      didSet {
        guard wheelColor != oldValue else { return }
        wheelColorModified = true
        wheelImage = wheelImage?.imageWithColor(wheelColor)
        wheelColorModified = false
        setNeedsDisplay()
      }
    }

    var dimpleColor: UIColor = .lightGrayColor() {
      didSet {
        guard dimpleColor != oldValue else { return }
        dimpleColorModified = true
        dimpleImage = dimpleImage?.imageWithColor(dimpleColor)
        dimpleFillImage = dimpleFillImage?.imageWithColor(dimpleColor)
        dimpleColorModified = false
        setNeedsDisplay()
      }
    }

    var dimpleStyle: CGBlendMode = .Normal {
      didSet {
        guard dimpleStyle != oldValue else { return }
        setNeedsDisplay()
      }
    }

    var dimpleFillStyle: CGBlendMode = .Normal {
      didSet {
        guard dimpleFillStyle != oldValue else { return }
        setNeedsDisplay()
      }
    }

    /**
    drawInContext:

    - parameter ctx: CGContext
    */
    private override func drawInContext(ctx: CGContext) {

      CGContextSaveGState(ctx)
      UIGraphicsPushContext(ctx)

      let baseFrame = CGContextGetClipBoundingBox(ctx).centerInscribedSquare.integral
      if let wheelBase = wheelImage {
        wheelBase.drawInRect(baseFrame)
      } else {
        wheelColor.setFill()
        UIBezierPath(ovalInRect: baseFrame).fill()
      }


      let dimpleSize = baseFrame.size * 0.35
      let dimpleFrame = CGRect(origin: CGPoint(x: baseFrame.midX - half(dimpleSize.width), y: 4), size: dimpleSize)

      if let dimple = dimpleImage, dimpleFill = dimpleFillImage {

        UIBezierPath(ovalInRect: dimpleFrame).addClip()
        dimple.drawInRect(dimpleFrame, blendMode: dimpleStyle, alpha: 1)

        let deltaSize = dimpleSize - dimpleFill.size
        let dimpleFillFrame = CGRect(origin: dimpleFrame.origin + deltaSize * 0.5, size: dimpleFill.size)

        UIBezierPath(ovalInRect: dimpleFillFrame.insetBy(dx: 1, dy: 1)).addClip()
        dimpleFill.drawAtPoint(dimpleFillFrame.origin, blendMode: dimpleFillStyle, alpha: 1)

      } else {
        dimpleColor.setFill()
        UIBezierPath(ovalInRect: dimpleFrame).fill()
      }

      UIGraphicsPopContext()
      CGContextRestoreGState(ctx)

    }
  }

  private let wheelLayer = WheelLayer()

  @IBInspectable public var confineTouchToBounds: Bool = true
  @IBInspectable public var directionLock: Bool = true

  /** setup */
  private func setup() {
    wheelLayer.needsDisplayOnBoundsChange = true
    wheelLayer.contentsScale = UIScreen.mainScreen().scale
    layer.addSublayer(wheelLayer)
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  public var dimpleStyle: CGBlendMode  {
    get { return wheelLayer.dimpleStyle }
    set { wheelLayer.dimpleStyle = newValue }
  }

  @IBInspectable public var dimpleStyleString: String {
    get { return dimpleStyle.stringValue }
    set { dimpleStyle = CGBlendMode(stringValue: newValue) }
  }

  public var dimpleFillStyle: CGBlendMode {
    get { return wheelLayer.dimpleFillStyle }
    set { wheelLayer.dimpleFillStyle = newValue }
  }

  @IBInspectable public var dimpleFillStyleString: String {
    get { return dimpleFillStyle.stringValue }
    set { dimpleFillStyle = CGBlendMode(stringValue: newValue) }
  }

  @IBInspectable public var value: Float = 0

  @IBInspectable public var wheelImage: UIImage? {
    get { return wheelLayer.wheelImage }
    set { wheelLayer.wheelImage = newValue }
  }

  @IBInspectable public var wheelColor: UIColor {
    get { return wheelLayer.wheelColor }
    set { wheelLayer.wheelColor = newValue }
  }

  @IBInspectable public var dimpleImage: UIImage? {
    get { return wheelLayer.dimpleImage }
    set { wheelLayer.dimpleImage = newValue }
  }

  @IBInspectable public var dimpleFillImage: UIImage? {
    get { return wheelLayer.dimpleFillImage }
    set { wheelLayer.dimpleFillImage = newValue }
  }

  @IBInspectable public var dimpleColor:  UIColor {
    get { return wheelLayer.dimpleColor }
    set { wheelLayer.dimpleColor = newValue }
  }

  public private(set) var revolutions: CGFloat = 0

  private let thetaOffset = π / 2

  @IBInspectable public var theta: CGFloat = 0 {
    didSet {
      revolutions = theta % (π * 2)
      wheelLayer.setAffineTransform(CGAffineTransform(angle: theta + thetaOffset))
//      print(
//        "didSet(theta)",
//        "  theta: \(theta.degrees.rounded(2))",
//        "  oldValue: \(oldValue.degrees.rounded(2))",
//        "",
//        separator: "\n"
//      )
    }
  }
  private var previousAngle: CGFloat = 0
  private var previousLocation: CGPoint = .zero
  private var touchPath = UIBezierPath()
  private var direction: Direction?

  /** updateTouchPath */
  private func updateTouchPath() {
    wheelLayer.frame = layer.bounds
    touchPath = UIBezierPath(ovalInRect: bounds.centerInscribedSquare)
//    let center = touchPath.bounds.center
//    let radius = half(touchPath.bounds.width * 0.6)
//    touchPath.moveToPoint(center)
//    touchPath.addArcWithCenter(center, radius: radius, startAngle: 0, endAngle: π * 2, clockwise: true)
//    touchPath.closePath()
  }

  public override var bounds: CGRect { didSet { updateTouchPath() } }
  public override var frame: CGRect { didSet { updateTouchPath() } }

  /**
  angleForTouchLocation:

  - parameter location: CGPoint

  - returns: CGFloat
  */
  private func angleForTouchLocation(location: CGPoint) -> CGFloat {
    let (x, y) = (location - bounds.center).unpack
    let h = sqrt(pow(x, 2) + pow(y, 2))
    return acos(x / h)
  }

  private enum Direction: String {
    case Clockwise, CounterClockwise
    init(from: CGPoint, to: CGPoint, about: CGPoint) {
      switch (from.unpack, to.unpack, about.unpack) {
        case let ((x1, y1), (x2, y2), (_, yc)) where x2 > x1 && y2 == y1 && y2 > yc:
          self = .CounterClockwise
        case let ((x1, y1), (x2, y2), (_, yc)) where x2 > x1 && y2 == y1 && y2 <= yc:
          self = .Clockwise
        case let ((x1, y1), (x2, y2), (_, yc)) where x2 < x1 && y2 == y1 && y2 > yc:
          self = .Clockwise
        case let ((x1, y1), (x2, y2), (_, yc)) where x2 < x1 && y2 == y1 && y2 <= yc:
          self = .CounterClockwise
        case let ((x1, y1), (x2, y2), (xc, _)) where x2 == x1 && y2 > y1 && x2 > xc:
          self = .Clockwise
        case let ((x1, y1), (x2, y2), (xc, _)) where x2 == x1 && y2 > y1 && x2 <= xc:
          self = .CounterClockwise
        case let ((x1, y1), (x2, y2), (xc, _)) where x2 == x1 && y2 < y1 && x2 > xc:
          self = .CounterClockwise
        case let ((x1, y1), (x2, y2), (xc, _)) where x2 == x1 && y2 < y1 && x2 <= xc:
          self = .Clockwise
        case let ((x1, y1), (x2, y2), _) where x2 > x1 && y2 > y1:
          self = .Clockwise
        case let ((x1, y1), (x2, y2), _) where x2 > x1 && y2 < y1:
          self = .CounterClockwise
        case let ((x1, y1), (x2, y2), _) where x2 < x1 && y2 > y1:
          self = .CounterClockwise
        case let ((x1, y1), (x2, y2), _) where x2 < x1 && y2 < y1:
          self = .Clockwise
        default:
          assert(false)
          self = .Clockwise // Unreachable?
      }
    }
  }

  /**
  updateForTouch:

  - parameter touch: UITouch
  */
  private func updateForTouch(touch: UITouch) {

    let location = touch.locationInView(self)
    let touchPreviousLocation = touch.previousLocationInView(self)
    let currentDirection = Direction(from: touchPreviousLocation, to: location, about: bounds.center)

    if let direction = direction where directionLock && currentDirection != direction { return }
    else if direction == nil { direction = currentDirection }

    let locationAngle = angleForTouchLocation(location)

    let deltaAngle = abs(locationAngle - previousAngle)

//    print(
//      "location: (\(location.x.rounded(2)), \(location.y.rounded(2)))",
//      "previousLocation: (\(previousLocation.x.rounded(2)), \(previousLocation.y.rounded(2)))",
//      "touchPreviousLocation: (\(touchPreviousLocation.x.rounded(2)), \(touchPreviousLocation.y.rounded(2)))",
//      "locationAngle: \(locationAngle.degrees.rounded(2))",
//      "previousAngle: \(previousAngle.degrees.rounded(2))",
//      "deltaAngle: \(deltaAngle.degrees.rounded(2))",
//      "direction: \(currentDirection.rawValue)",
//      "",
//      separator: "\n")

    switch currentDirection {
      case .Clockwise: theta += deltaAngle
      case .CounterClockwise: theta -= deltaAngle
    }

    previousAngle = locationAngle
    previousLocation = location
  }

  /**
  drawRect:

  - parameter rect: CGRect
  */
//  public override func drawRect(rect: CGRect) {
//    var frame = rect
//    if frame.size.width != frame.size.height {
//      frame.size = CGSize(square: frame.size.minAxis)
//      frame.origin += (rect.size - frame.size) * 0.5
//    }
//
//    let context = UIGraphicsGetCurrentContext()
//    CGContextSaveGState(context)
//
//    let baseFrame = frame.integral
//    if let wheelBase = wheelImage {
//      wheelBase.drawInRect(baseFrame)
//    } else {
//      wheelColor.setFill()
//      UIBezierPath(ovalInRect: baseFrame).fill()
//    }
//
//
//    let dimpleSize = baseFrame.size * 0.35
//    let dimpleFrame = CGRect(origin: CGPoint(x: frame.midX - half(dimpleSize.width), y: 4), size: dimpleSize)
//
//    if let dimple = dimpleImage, dimpleFill = dimpleFillImage {
//
//      UIBezierPath(ovalInRect: dimpleFrame).addClip()
//      dimple.drawInRect(dimpleFrame, blendMode: dimpleStyle, alpha: 1)
//
//      let deltaSize = dimpleSize - dimpleFill.size
//      let dimpleFillFrame = CGRect(origin: dimpleFrame.origin + deltaSize * 0.5, size: dimpleFill.size)
//
//      UIBezierPath(ovalInRect: dimpleFillFrame.insetBy(dx: 1, dy: 1)).addClip()
//      dimpleFill.drawAtPoint(dimpleFillFrame.origin, blendMode: dimpleFillStyle, alpha: 1)
//
//    } else {
//      dimpleColor.setFill()
//      UIBezierPath(ovalInRect: dimpleFrame).fill()
//    }
//
//    CGContextRestoreGState(context)
//  }

  /**
  beginTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    guard touchPath.containsPoint(touch.locationInView(self)) else { return false }
    direction = nil
    previousAngle = angleForTouchLocation(touch.locationInView(self))
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
    guard !confineTouchToBounds || touchPath.containsPoint(touch.locationInView(self)) else { return false }
    updateForTouch(touch)
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

    guard !confineTouchToBounds || touchPath.containsPoint(touch.locationInView(self)) else {
      sendActionsForControlEvents(.TouchUpOutside)
      return
    }
    updateForTouch(touch)
    sendActionsForControlEvents(.TouchUpInside)
  }

  /**
  cancelTrackingWithEvent:

  - parameter event: UIEvent?
  */
  public override func cancelTrackingWithEvent(event: UIEvent?) { sendActionsForControlEvents(.TouchCancel) }
}