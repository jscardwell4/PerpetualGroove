//
//  ScrollWheel.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/15/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
public class ScrollWheel: UIControl {

  // MARK: - Colors

  private var wheelColorModified = false
  private var dimpleColorModified = false

  @IBInspectable public var wheelColor: UIColor = .darkGrayColor() {
    didSet {
      guard wheelColor != oldValue else { return }
      wheelColorModified = true
      wheelImage = wheelImage?.imageWithColor(wheelColor)
      wheelColorModified = false
      setNeedsDisplay()
    }
  }

  @IBInspectable public var dimpleColor: UIColor = .lightGrayColor() {
    didSet {
      guard dimpleColor != oldValue else { return }
      dimpleColorModified = true
      dimpleImage = dimpleImage?.imageWithColor(dimpleColor)
      dimpleFillImage = dimpleFillImage?.imageWithColor(dimpleColor)
      dimpleColorModified = false
      setNeedsDisplay()
    }
  }

  // MARK: - Images

  @IBInspectable public var wheelImage: UIImage? {
    didSet {
      guard wheelImage != oldValue && !wheelColorModified else { return }
      wheelImage = wheelImage?.imageWithColor(wheelColor)
      setNeedsDisplay()
    }
  }
  @IBInspectable public var dimpleImage: UIImage? {
    didSet {
      guard dimpleImage != oldValue && !dimpleColorModified else { return }
      dimpleImage = dimpleImage?.imageWithColor(dimpleColor)
      setNeedsDisplay()
    }
  }
  @IBInspectable public var dimpleFillImage: UIImage? {
    didSet {
      guard dimpleFillImage != oldValue && !dimpleColorModified else { return }
      dimpleFillImage = dimpleFillImage?.imageWithColor(dimpleColor)
      setNeedsDisplay()
    }
  }

  // MARK: - Styles

  public var dimpleStyle: CGBlendMode = .Normal {
    didSet {
      guard dimpleStyle != oldValue else { return }
      setNeedsDisplay()
    }
  }

  public var dimpleFillStyle: CGBlendMode = .Normal {
    didSet {
      guard dimpleFillStyle != oldValue else { return }
      setNeedsDisplay()
    }
  }

  @IBInspectable public var dimpleStyleString: String {
    get { return dimpleStyle.stringValue }
    set { dimpleStyle = CGBlendMode(stringValue: newValue) }
  }

  @IBInspectable public var dimpleFillStyleString: String {
    get { return dimpleFillStyle.stringValue }
    set { dimpleFillStyle = CGBlendMode(stringValue: newValue) }
  }

  // MARK: - Drawing

  private var angle: CGFloat = 0 { didSet { setNeedsDisplay() } }
  private var wheelCenter: CGPoint = .zero

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {
    let context = UIGraphicsGetCurrentContext()
    CGContextSaveGState(context)
    CGContextTranslateCTM(context, half(rect.width), half(rect.height))
    CGContextRotateCTM(context, angle)
    CGContextTranslateCTM(context, -half(rect.width), -half(rect.height))

    let baseFrame = rect.centerInscribedSquare
    if let wheelBase = wheelImage {
      wheelBase.drawInRect(baseFrame)
    } else {
      wheelColor.setFill()
      UIBezierPath(ovalInRect: baseFrame).fill()
    }


    let dimpleSize = CGSize(square: baseFrame.height * 0.25)
    let dimpleFrame = CGRect(origin: CGPoint(x: baseFrame.midX - half(dimpleSize.width), y: baseFrame.minY + 10), size: dimpleSize)
    if let dimple = dimpleImage, dimpleFill = dimpleFillImage {

      UIBezierPath(ovalInRect: dimpleFrame).addClip()
      dimple.drawInRect(dimpleFrame, blendMode: dimpleStyle, alpha: 1)

      let dimpleFillFrame = dimpleFrame.insetBy(dx: 1, dy: 1)

      UIBezierPath(ovalInRect: dimpleFillFrame.insetBy(dx: 1, dy: 1)).addClip()
      dimpleFill.drawInRect(dimpleFillFrame, blendMode: dimpleFillStyle, alpha: 1)

    } else {
      dimpleColor.setFill()
      UIBezierPath(ovalInRect: dimpleFrame).fill()
    }

    CGContextRestoreGState(context)
  }

  // MARK: - Behavior

  @IBInspectable public var confineTouchToBounds: Bool = false
  @IBInspectable public var beginResetsRevolutions: Bool = true

  // MARK: - Values

  public var revolutions: Float { return Float(theta / (π * 2)) }

  @IBInspectable public var theta: CGFloat = 0

  // MARK: - Touches

  private var touchPath = UIBezierPath()
  private var touchOffset: CGFloat = 0

  /** updateTouchPath */
  private func updateTouchPath() {
    let square = bounds.centerInscribedSquare
    touchPath = UIBezierPath(ovalInRect: square)
    let outterRadius = half(square.width)
    let innerRadius = square.width * 0.125
    touchPath.moveToPoint(CGPoint(x: square.minX + outterRadius + innerRadius, y: square.minY + outterRadius))
    touchPath.usesEvenOddFillRule = true
    touchPath.addArcWithCenter(CGPoint(x: square.midX, y: square.midY),
                        radius: innerRadius,
                    startAngle: 0,
                      endAngle: π * 2,
                     clockwise: true)
  }

  public override var bounds: CGRect { didSet { updateTouchPath() } }
  public override var frame: CGRect { didSet { updateTouchPath() } }


  /**
  angleForTouchLocation:withCenter:direction:

  - parameter location: CGPoint

  - returns: (Angle, Quadrant)
  */
  private func angleForTouchLocation(location: CGPoint) -> CGFloat {

    let delta = location - wheelCenter
    let quadrant = Quadrant(point: location, center: wheelCenter)
    let (x, y) = delta.absolute.unpack
    let h = sqrt(pow(x, 2) + pow(y, 2))
    var a = acos(x / h)

    // Adjust the angle for the quadrant
    switch quadrant {
      case .I: a = π * 2 - a
      case .II: a += π
      case .III: a = π - a
      case .IV: break
    }

    // Adjust the angle for the rotated dimple
    a += π * 0.5

    // Adjust for initial touch offset
    a += touchOffset

    return a
  }

  private var innerLastTouch = false

  /**
  updateForTouch:

  - parameter touch: UITouch
  */
  private func updateForTouch(touch: UITouch, withEvent event: UIEvent? = nil) {

    guard touchPath.containsPoint(touch.locationInView(self)) else { innerLastTouch = true; return }

    if innerLastTouch {
      touchOffset = 0
      let touchAngle = angleForTouchLocation(touch.locationInView(nil))
      touchOffset = (angle - touchAngle) % (π * 2)
      self.geometry = nil
      innerLastTouch = false
    }

    let location = touch.locationInView(nil)
    angle = angleForTouchLocation(location)

    guard let previousGeometry = self.geometry else {
      self.geometry = Geometry(location: location, angle: angle, offset: touchOffset)
      return
    }

    guard location != previousGeometry.location else { return }

    let trending: Direction? = previousGeometry.direction == .Unknown ? nil : previousGeometry.direction
    let direction = Direction(from: previousGeometry.location, to: location, about: wheelCenter, trending: trending)

    let geometry = Geometry(location: location, angle: angle, offset: touchOffset, direction: direction)


    var deltaAngle = abs(angle - previousGeometry.angle)
    switch (previousGeometry.quadrant, geometry.quadrant) {
      case (.IV, .I), (.I, .IV): deltaAngle -= π * 2
      default:                   break
    }

    guard !isnan(deltaAngle) else { return }
    switch direction {
      case .Clockwise:        theta += deltaAngle
      case .CounterClockwise: theta -= deltaAngle
      case .Unknown:          return
    }

    self.geometry = geometry
  }

  private var geometry: Geometry?

  // MARK: - Supporting types

  private struct Angle {
    init(_ a: CGFloat) { counterClockwise = a }
    var clockwise: CGFloat { return π * 2 - counterClockwise }
    var counterClockwise: CGFloat
  }

  private struct Geometry {
    let location: CGPoint
    let angle: CGFloat
    let offset: CGFloat
    var quadrant: Quadrant { return Quadrant(angle: angle - offset - π * 0.5) }
    let direction: Direction
    init(location: CGPoint, angle: CGFloat, offset: CGFloat = 0, direction: Direction = .Unknown) {
      self.location = location
      self.angle = angle
      self.direction = direction
      self.offset = offset
    }
  }

  private enum Direction: String {
    case Clockwise, CounterClockwise, Unknown

    /**
    initWithFrom:to:about:trending:

    - parameter from: CGPoint
    - parameter to: CGPoint
    - parameter about: CGPoint
    - parameter trending: Direction?
    */
    init(from: CGPoint, to: CGPoint, about: CGPoint, trending: Direction?) {
      let direction: Direction
      let fromQuadrant = Quadrant(point: from, center: about)
      let toQuadrant = Quadrant(point: to, center: about)

      switch (fromQuadrant, toQuadrant) {
      case (.I, .II), (.II, .III), (.III, .IV), (.IV, .I):
        direction = .CounterClockwise
      case (.I, .IV), (.IV, .III), (.III, .II), (.II, .I):
        direction = .Clockwise
      default:
        switch (from.unpack, to.unpack) {

        case let ((x1, y1), (x2, y2)) where y2 == y1 && x2 < x1:
          switch toQuadrant { case .I, .II: direction = .CounterClockwise; default: direction = .Clockwise }

        case let ((x1, y1), (x2, y2)) where y2 == y1 && x2 >= x1:
          switch toQuadrant { case .I, .II: direction = .Clockwise; default: direction = .CounterClockwise }

        case let ((x1, y1), (x2, y2)) where x2 == x1 && y2 <= y1:
          switch toQuadrant { case .II, .III: direction = .Clockwise; default: direction = .CounterClockwise }

        case let ((x1, y1), (x2, y2)) where x2 == x1 && y2 >= y1:
          switch toQuadrant { case .II, .III: direction = .CounterClockwise; default: direction = .Clockwise }

        case let ((x1, y1), (x2, y2)) where y2 < y1 && x2 < x1:
          switch toQuadrant {
          case .III: direction = .Clockwise
          case .I:   direction = .CounterClockwise
          case .II:  direction = trending ?? .Unknown
          case .IV:  direction = trending ?? .Unknown
          }

        case let ((x1, y1), (x2, y2)) where y2 < y1 && x2 > x1:
          switch toQuadrant {
          case .III: direction = trending ?? .CounterClockwise
          case .I:   direction = trending ?? .Clockwise
          case .II:  direction = .Clockwise
          case .IV:  direction = .CounterClockwise
          }

        case let ((x1, y1), (x2, y2)) where y2 > y1 && x2 < x1:
          switch toQuadrant {
          case .III: direction = trending ?? .Unknown
          case .I:   direction = trending ?? .Unknown
          case .II:  direction = .CounterClockwise
          case .IV:  direction = .Clockwise
          }

        case let ((x1, y1), (x2, y2)) where y2 > y1 && x2 > x1:
          switch toQuadrant {
          case .III: direction = trending ?? .Unknown
          case .I:   direction = trending ?? .Unknown
          case .II:  direction = .Clockwise
          case .IV:  direction = .CounterClockwise
          }

        default:
          direction = .Unknown
        }
      }

      self = direction
    }
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize { return CGSize(square: wheelImage?.size.maxAxisValue ?? 100) }

  private enum Quadrant: String {
    case I, II, III, IV

    /**
    initWithPoint:center:

    - parameter point: CGPoint
    - parameter center: CGPoint
    */
    init(point: CGPoint, center: CGPoint) {
      switch (point.unpack, center.unpack) {
        case let ((px, py), (cx, cy)) where px >= cx && py <= cy: self = .I
        case let ((px, py), (cx, cy)) where px <= cx && py <= cy: self = .II
        case let ((px, py), (cx, cy)) where px <= cx && py >= cy: self = .III
        default:                                                  self = .IV
      }
    }

    /**
    initWithAngle:

    - parameter angle: CGFloat
    */
    init(angle: CGFloat) {
      switch angle {
        case 0 ... (π * 0.5): self = .IV
        case (π * 0.5) ... π: self = .III
        case π ... (π * 1.5): self = .II
        default:              self = .I
      }
    }
  }

  /**
  beginTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    guard touchPath.containsPoint(touch.locationInView(self)) else { return false }
    if beginResetsRevolutions { theta = 0 }
    geometry = nil
    touchOffset = 0
    wheelCenter = window!.convertPoint(self.center, fromView: superview)
    let touchAngle = angleForTouchLocation(touch.locationInView(nil))
    touchOffset = (angle - touchAngle) % (π * 2)
    updateForTouch(touch)
    return true
  }

  #if TARGET_INTERFACE_BUILDER
  @IBInspectable public override var enabled: Bool { didSet {} }
  #endif

  /**
  continueTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    guard !confineTouchToBounds || touchPath.containsPoint(touch.locationInView(self)) else { return false }
    updateForTouch(touch, withEvent: event)
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
    guard !confineTouchToBounds || touchPath.containsPoint(touch.locationInView(self)) else { return }
    updateForTouch(touch)
  }

  /**
  cancelTrackingWithEvent:

  - parameter event: UIEvent?
  */
  public override func cancelTrackingWithEvent(event: UIEvent?) { sendActionsForControlEvents(.TouchCancel) }

}

private func -(lhs: ScrollWheel.Angle, rhs: ScrollWheel.Angle) -> ScrollWheel.Angle {
  return ScrollWheel.Angle(lhs.counterClockwise - rhs.counterClockwise)
}

extension ScrollWheel.Angle: CustomStringConvertible {
  var description: String {
    return "{ clockwise: \(clockwise.degrees.rounded(2)); counterClockwise: \(counterClockwise.degrees.rounded(2)) }"
  }
}

extension ScrollWheel.Geometry: CustomStringConvertible {
  var description: String {
    return "; ".join(
      "location: (\(location.x.rounded(2)), \(location.y.rounded(2)))",
      "quadrant: \(quadrant.rawValue)",
      "direction: \(direction.rawValue)",
      "angle: \(angle)"
    )
  }
}

