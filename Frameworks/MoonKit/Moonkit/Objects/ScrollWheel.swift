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

  @IBInspectable public var confineTouchToBounds: Bool = false
  @IBInspectable public var beginResetsRevolutions: Bool = true

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

  private var thetaOffset: CGFloat = 0
  public var revolutions: Float { return Float((theta - thetaOffset) / (π * 2)) }

  @IBInspectable public var theta: CGFloat = 0 {
    didSet {
      wheelLayer.setAffineTransform(CGAffineTransform(angle: theta))
    }
  }

  private var touchPath = UIBezierPath()


  /** updateTouchPath */
  private func updateTouchPath() {
    wheelLayer.frame = layer.bounds
    touchPath = UIBezierPath(ovalInRect: bounds.centerInscribedSquare)
  }

  public override var bounds: CGRect { didSet { updateTouchPath() } }
  public override var frame: CGRect { didSet { updateTouchPath() } }

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
      let (x1, y1) = from.unpack
      let (x2, y2) = to.unpack
      switch (y2 - y1) / (x2 - x1) {

      case 0 where x2 < x1:

        switch about.unpack {
        case let (_, yc) where y2 <= yc:
//          print("case 0 where x2 < x1 && y2 <= yc: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        case let (_, yc) where y2 >= yc:
//          print("case 0 where x2 < x1 && y2 >= yc: x2 = \(x2); y2 = \(y2) Clockwise")
          self = .Clockwise
        default:
//          let result = trending ?? .Clockwise
//          print("case 0 where x2 < x1 && default: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
        }

      case 0 where x2 >= x1:

        switch about.unpack {
        case let (_, yc) where y2 <= yc:
//          print("case 0 where x2 >= x1 && y2 <= yc: x2 = \(x2); y2 = \(y2) Clockwise")
          self = .Clockwise
        case let (_, yc) where y2 >= yc:
//          print("case 0 where x2 >= x1 && y2 >= yc: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        default:
//          let result = trending ?? .CounterClockwise
//          print("case 0 where x2 >= x1 && default: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .CounterClockwise
        }

      case CGFloat.infinity where y2 <= y1:

        switch about.unpack {
        case let (xc, _) where x2 <= xc:
//          print("case CGFloat.infinity where y2 <= y1 && x2 <= xc: x2 = \(x2); y2 = \(y2) Clockwise")
          self = .Clockwise
        case let (xc, _) where x2 >= xc:
//          print("case CGFloat.infinity where y2 <= y1 && x2 >= xc: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        default:
//          let result = trending ?? .CounterClockwise
//          print("case CGFloat.infinity where y2 <= y1 && default: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .CounterClockwise
        }

      case CGFloat.infinity where y2 >= y1:

        switch about.unpack {
        case let (xc, _) where x2 <= xc:
//          print("case CGFloat.infinity where y2 >= y1: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        case let (xc, _) where x2 >= xc:
//          print("case CGFloat.infinity where y2 >= y1: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .Clockwise
        default:
//          let result = trending ?? .Clockwise
//          print("case CGFloat.infinity where y2 >= y1: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
        }

      case let s where s.isSignMinus:

        switch about.unpack {
        case let (xc, yc) where x2 <= xc && y2 >= yc:
//          print("case let s where s.isSignMinus && x2 <= xc && y2 >= yc: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        case let (xc, yc) where x2 <= xc && y2 <= yc:
//          let result = trending ?? .Clockwise
//          print("case let s where s.isSignMinus && x2 <= xc && y2 <= yc: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
        case let (xc, yc) where x2 >= xc && y2 >= yc:
//          let result = trending ?? .CounterClockwise
//          print("case let s where s.isSignMinus && x2 >= xc && y2 >= yc: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .CounterClockwise
        default:
//          let result = trending ?? .Clockwise
//          print("case let s where s.isSignMinus && default: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
        }

      default:
        switch about.unpack {
        case let (xc, yc) where x2 <= xc && y2 >= yc:
//          print("<default && x2 <= xc && y2 >= yc> x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .Clockwise
        case let (xc, yc) where x2 <= xc && y2 <= yc:
//          print("<default && x2 <= xc && y2 <= yc> x2 = \(x2); y2 = \(y2) Clockwise")
          self = .Clockwise
        case let (xc, yc) where x2 >= xc && y2 >= yc:
////          let result = trending ?? .CounterClockwise
//          print("<default && x2 >= xc && y2 >= yc> x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .CounterClockwise
        default:
//          let result = trending ?? .CounterClockwise
//          print("<default && default> x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
        }

      }

    }
  }

  private var geometry: Geometry?

  private struct Angle {
    init(_ a: CGFloat) { counterClockwise = a }
    var clockwise: CGFloat { return π * 2 - counterClockwise }
    var counterClockwise: CGFloat
    func angleForDirection(direction: Direction) -> CGFloat { return direction == .Clockwise ? clockwise : counterClockwise }
  }

  private struct Geometry { var location: CGPoint; var angle: Angle; var quadrant: Quadrant; var direction: Direction }

  private enum Quadrant: String {
    case I, II, III, IV
    init(point: CGPoint, center: CGPoint) {
      switch (point.unpack, center.unpack) {
      case let ((px, py), (cx, cy)) where px >= cx && py <= cy: self = .I
      case let ((px, py), (cx, cy)) where px <= cx && py <= cy: self = .II
      case let ((px, py), (cx, cy)) where px <= cx && py >= cy: self = .III
      default:                                                  self = .IV
      }
    }
  }

  /**
  angleForTouchLocation:withCenter:direction:

  - parameter location: CGPoint
  - parameter center: CGPoint

  - returns: (Angle, Quadrant)
  */
  private func angleForTouchLocation(location: CGPoint, withCenter center: CGPoint) -> (Angle, Quadrant) {

    let delta = location - center
    let quadrant = Quadrant(point: location, center: center)
    let (x, y) = delta.absolute.unpack
    let h = sqrt(pow(x, 2) + pow(y, 2))
    var a = acos(x / h)
    switch quadrant {
      case .I: break
      case .II: a = π * 0.5 - a + π * 0.5
      case .III: a += π
      case .IV: a = π * 0.5 - a + π * 1.5
    }

    return (Angle(a), quadrant)
  }

  /**
  updateForTouch:

  - parameter touch: UITouch
  */
  private func updateForTouch(touch: UITouch) {


    let location = touch.locationInView(nil)
    let center = window!.convertPoint(self.center, fromView: superview)
    var (angle, quadrant) = angleForTouchLocation(location, withCenter: center)

    guard let previousGeometry = geometry else {
      geometry = Geometry(location: location, angle: angle, quadrant: quadrant, direction: .Unknown)
      return
    }

    guard location != previousGeometry.location else { return }

    let trending: Direction? = previousGeometry.direction == .Unknown ? nil : previousGeometry.direction
    let direction = Direction(from: previousGeometry.location, to: location, about: center, trending: trending)

    if case (.IV, .I) = (previousGeometry.quadrant, quadrant) { angle.counterClockwise += π * 2 }

    let deltaAngle = angle - previousGeometry.angle
    backgroundDispatch {
      let currentGeometry = Geometry(location: location, angle: angle, quadrant: quadrant, direction: direction)
      var string = "<updateForTouch>\n\tcurrent geometry: \(currentGeometry)\n\tprevious geometry: \(previousGeometry)\n"
      string += "\tcenter: (\(center.x.rounded(2)), \(center.y.rounded(2)))\n\tdeltaAngle: \(deltaAngle)"
      logDebug(string)
    }

    switch direction {
      case .Clockwise: theta += abs(deltaAngle.clockwise)
      case .CounterClockwise: theta -= abs(deltaAngle.counterClockwise)
      case .Unknown: fatalError("We should know which direction we are moving")
    }

    geometry?.angle = angle
    geometry?.direction = direction
    geometry?.location = location
    geometry?.quadrant = quadrant
  }

  /**
  beginTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    guard touchPath.containsPoint(touch.locationInView(self)) else { return false }
    if beginResetsRevolutions { thetaOffset = theta }
    geometry = nil
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
    return "location: (\(location.x.rounded(2)); quadrant: \(quadrant.rawValue); direction: \(direction.rawValue); angle: \(angle)"
  }
}

