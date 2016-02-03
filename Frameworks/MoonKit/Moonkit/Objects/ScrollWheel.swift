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

  @IBInspectable public var wheelColor: UIColor = .darkGrayColor() {
    didSet {
      guard wheelColor != oldValue else { return }

      backgroundDispatch {
        [weak self] in
        self?._wheelImage = self?.wheelImage?.imageWithColor(self!.wheelColor)
        dispatchToMain { self?.setNeedsDisplay() }
      }
    }
  }

  @IBInspectable public var dimpleColor: UIColor = .lightGrayColor() {
    didSet {
      guard dimpleColor != oldValue else { return }
      backgroundDispatch {
        [weak self] in
        self?._dimpleImage = self?.dimpleImage?.imageWithColor(self!.dimpleColor)
        self?._dimpleFillImage = self?.dimpleFillImage?.imageWithColor(self!.dimpleColor)
        dispatchToMain { self?.setNeedsDisplay() }
      }
    }
  }

  // MARK: - Images

  private var _wheelImage: UIImage?
  @IBInspectable public var wheelImage: UIImage? {
    didSet {
      guard wheelImage != oldValue else { return }
      backgroundDispatch {
        [weak self] in
        self?._wheelImage = self?.wheelImage?.imageWithColor(self!.wheelColor)
        dispatchToMain { self?.setNeedsDisplay() }
      }
    }
  }
  private var _dimpleImage: UIImage?
  @IBInspectable public var dimpleImage: UIImage? {
    didSet {
      guard dimpleImage != oldValue else { return }
      backgroundDispatch {
        [weak self] in
        self?._dimpleImage = self?.dimpleImage?.imageWithColor(self!.dimpleColor)
        dispatchToMain { self?.setNeedsDisplay() }
      }
    }
  }
  private var _dimpleFillImage: UIImage?
  @IBInspectable public var dimpleFillImage: UIImage? {
    didSet {
      guard dimpleFillImage != oldValue else { return }
      backgroundDispatch {
        [weak self] in
        self?._dimpleFillImage = self?.dimpleFillImage?.imageWithColor(self!.dimpleColor)
        dispatchToMain { self?.setNeedsDisplay() }
      }
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

  /// The angle used in drawing the wheel
  private var angle: CGFloat = 0.0 { didSet { setNeedsDisplay() } }

  /// The wheel's center point in window coordinates
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
    if let wheelBase = _wheelImage {
      wheelBase.drawInRect(baseFrame)
    } else {
      wheelColor.setFill()
      UIBezierPath(ovalInRect: baseFrame).fill()
    }


    let dimpleSize = CGSize(square: baseFrame.height * 0.25)
    let dimpleFrame = CGRect(origin: CGPoint(x: baseFrame.midX - half(dimpleSize.width),
                                             y: baseFrame.minY + 10),
                             size: dimpleSize)
    if let dimple = _dimpleImage, dimpleFill = _dimpleFillImage {

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

  // MARK: - Values

  /// One full revolution in radians
  private static let revolution = π * 2

  /// Half a revolution in radians
  private static let halfRevolution = π

  /// A quarter revolution in radians
  private static let quarterRevolution = π / 2

  /// Total rotation in radians
  public private(set) var radians = 0.0 {
    didSet {
      guard radians != oldValue else { return }
      sendActionsForControlEvents(.ValueChanged)
    }
  }

  /// Total number of revolutions
  public var revolutions: Double { return radians / Double(ScrollWheel.revolution) }
  @objc(deltaRevolutions) public var 𝝙revolutions: Double { return 𝝙radians / Double(ScrollWheel.revolution) }

  @objc(deltaRadians) public private(set) var 𝝙radians = 0.0
  @objc(deltaSeconds) public private(set) var 𝝙seconds = 0.0

  /// Velocity in radians per second
  public var velocity: Double { return 𝝙radians / 𝝙seconds }

  /// The current direction of rotation
  public var direction: Direction { return directionalTrend }

  // MARK: - Touches

  /// The path within which valid touch events occur
  private var touchPath = UIBezierPath()

  /// The difference between the `angle` and the angle of the initial touch location
  private var touchOffset: CGFloat = 0.0

  /** updateTouchPath */
  private func updateTouchPath() {
    let square = bounds.centerInscribedSquare
    touchPath = UIBezierPath(ovalInRect: square)
    let outterRadius = half(square.width)
    touchPath.moveToPoint(CGPoint(x: square.minX + outterRadius + 1,
                                  y: square.minY + outterRadius))
    touchPath.usesEvenOddFillRule = true
    touchPath.addArcWithCenter(CGPoint(x: square.midX, y: square.midY),
                        radius: 1,
                    startAngle: 0,
                      endAngle: π * 2,
                     clockwise: true)
  }

  public override var bounds: CGRect { didSet { updateTouchPath() } }
  public override var frame: CGRect { didSet { updateTouchPath() } }

  /**
   angleForTouchLocation:

   - parameter location: CGPoint

    - returns: Double
  */
  private func angleForTouchLocation(location: CGPoint) -> CGFloat {

    let 𝝙 = location - wheelCenter
    let quadrant = Quadrant(point: location, center: wheelCenter)
    let (x, y) = 𝝙.absolute.unpack
    let h = hypot(x, y)
    var α = acos(x / h)

    // Adjust the angle for the quadrant
    switch quadrant {
      case .I:   α = ScrollWheel.revolution - α
      case .II:  α += ScrollWheel.halfRevolution
      case .III: α = ScrollWheel.halfRevolution - α
      case .IV:  break
    }

    // Adjust the angle for the rotated dimple
    α += ScrollWheel.quarterRevolution

    // Adjust for initial touch offset
    α += touchOffset

    return α
  }

  /// Values required for updating rotation
  private var preliminaryValues: (location: CGPoint, quadrant: Quadrant, timestamp: NSTimeInterval)?

  /// The direction indicated by the weighted average of the contents of `directionHistory`
  private var directionalTrend: Direction {
    var n = 0.0
    let directions = directionHistory.reverse().prefix(5)
    guard directions.count > 0 else { return .Unknown }
    for (i, d) in zip((1 ... directions.count).reverse(), directions) {
      n += Double(d.rawValue) * (5.0 + Double(i) * 0.1)
    }
    let result: Direction
    switch n {
      case ..<0: result = .CounterClockwise
      case 0..<: result = .Clockwise
      default:   result = .Unknown
    }

    return result
  }

  /**
  updateForTouch:

  - parameter touch: UITouch
  */
  private func updateForTouch(touch: UITouch, withEvent event: UIEvent? = nil) {

    // Make sure the touch is located inside `touchPath`
    guard touchPath.containsPoint(touch.locationInView(self)) else { /*innerLastTouch = true;*/ return }

    // Get the new location, angle and quadrant
    let locationʹ = touch.locationInView(nil)
    let angleʹ = angleForTouchLocation(locationʹ)
    let quadrantʹ = Quadrant(point: locationʹ, center: wheelCenter)

    // Make sure we already had some values or cache the new values and return
    guard let (location, quadrant, timestamp) = preliminaryValues else {
      preliminaryValues = (locationʹ, quadrantʹ, touch.timestamp)
      return
    }

    // Make sure the location has actually changed
    guard locationʹ != location else { return }

    // Get the current direction of rotation and cache it
    let direction = Direction(from: location, to: locationʹ, about: wheelCenter, trending: directionalTrend)
    directionHistory.append(direction)

    // Make sure we haven't changed direction or clear cached values and return
    guard direction == directionalTrend else { preliminaryValues = nil; return }

    // Get the absolute change in radians between the previous angle and the current angle and validate the value
    var 𝝙angle = abs(angleʹ - angle)
    guard !isnan(𝝙angle) else { fatalError("unexptected NaN for 𝝙angle") }

    // Correct the value if we've crossed the 0/2π threshold
    switch (quadrantʹ, quadrant) { case (.IV, .I), (.I, .IV): 𝝙angle -= ScrollWheel.revolution; default: break }

    // Get the change in radians signed for the current direction
    let 𝝙radiansʹ = Double(direction == .CounterClockwise ? -𝝙angle : 𝝙angle)

    // Calculate the updated total radians
    let radiansʹ = radians + 𝝙radiansʹ

    // Calculate the number of seconds over which the change in radians occurred
    let 𝝙secondsʹ = touch.timestamp - timestamp

    // Update the cached values
    preliminaryValues = (locationʹ, quadrantʹ, touch.timestamp)

    // Update property values
    𝝙radians = 𝝙radiansʹ
    𝝙seconds = 𝝙secondsʹ
    angle = angleʹ

    // Update radians last so all values have been updated when actions are sent
    radians = radiansʹ
  }

  /// Cache of calculated direction values
  private var directionHistory: [Direction] = []

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    return CGSize(square: wheelImage?.size.maxAxisValue ?? 100)
  }

  /**
  beginTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    guard touchPath.containsPoint(touch.locationInView(self)) else { return false }
    preliminaryValues = nil
    wheelCenter = window!.convertPoint(self.center, fromView: superview)
    touchOffset = (angle - angleForTouchLocation(touch.locationInView(nil))) % ScrollWheel.revolution
    radians = 0
    𝝙radians = 0
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
    updateForTouch(touch, withEvent: event)
    return true
  }

  /**
  endTrackingWithTouch:withEvent:

  - parameter touch: UITouch?
  - parameter event: UIEvent?
  */
  public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
    guard let touch = touch  else { return }
    updateForTouch(touch)
  }

  /**
  cancelTrackingWithEvent:

  - parameter event: UIEvent?
  */
  public override func cancelTrackingWithEvent(event: UIEvent?) {
    sendActionsForControlEvents(.TouchCancel)
  }

}

extension ScrollWheel {
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
    init(angle: Double) {
      switch angle {
        case 0 ... Double(π * 0.5):         self = .IV
        case Double(π * 0.5) ... Double(π): self = .III
        case Double(π) ... Double(π * 1.5): self = .II
        default:                            self = .I
      }
    }
  }

}

extension ScrollWheel {
  public enum Direction: Int, CustomStringConvertible {
    case CounterClockwise = -1, Unknown, Clockwise

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
          switch toQuadrant {
            case .I, .II: direction = .CounterClockwise
            default: direction = .Clockwise
          }

        case let ((x1, y1), (x2, y2)) where y2 == y1 && x2 >= x1:
          switch toQuadrant {
            case .I, .II: direction = .Clockwise
            default: direction = .CounterClockwise
          }

        case let ((x1, y1), (x2, y2)) where x2 == x1 && y2 <= y1:
          switch toQuadrant {
            case .II, .III: direction = .Clockwise
            default: direction = .CounterClockwise
          }

        case let ((x1, y1), (x2, y2)) where x2 == x1 && y2 >= y1:
          switch toQuadrant {
            case .II, .III: direction = .CounterClockwise
            default: direction = .Clockwise
          }

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

    public var description: String {
      switch self {
        case .Clockwise:        return "Clockwise"
        case .Unknown:          return "Unknown"
        case .CounterClockwise: return "CounterClockwise"
      }
    }
  }
}
