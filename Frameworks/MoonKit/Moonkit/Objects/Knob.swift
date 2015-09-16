//
//  Knob.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/31/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable public class Knob: UIControl {

  public enum IndicatorStyle: String {
    case Clear, SourceAtop
    var blendMode: CGBlendMode { switch self { case .Clear: return .Clear; case .SourceAtop: return .SourceAtop } }
  }

  public var indicatorStyle = IndicatorStyle.Clear {
    didSet { guard oldValue != indicatorStyle else { return }; setNeedsDisplay() }
  }

  @IBInspectable public var indicatorStyleString: String {
    get { return indicatorStyle.rawValue }
    set { indicatorStyle = IndicatorStyle(rawValue: newValue) ?? .Clear }
  }

  @IBInspectable public var value: Float = 0.0 {
    didSet {
      guard oldValue != value else { return }
      value = valueInterval.clampValue(value)
      setNeedsDisplay()
    }
  }

  @IBInspectable public var minimumValue: Float {
    get { return valueInterval.start }
    set {
      guard valueInterval.start != newValue || newValue > valueInterval.end else { return }
      valueInterval = newValue ... valueInterval.end
    }
  }

  @IBInspectable public var maximumValue: Float {
    get { return valueInterval.end }
    set {
      guard valueInterval.end != newValue || newValue < valueInterval.start else { return }
      valueInterval = valueInterval.start ... newValue
    }
  }

  @IBInspectable public var knobBase: UIImage? {
    didSet {
      guard oldValue != value else { return }
      if let knobBase = knobBase { self.knobBase = knobBase.imageWithColor(knobColor) }
      setNeedsDisplay()
    }
  }

  private var previousRotation: CGFloat = 0
  private weak var rotationGesture: UIRotationGestureRecognizer?
  private let rotationInterval: ClosedInterval<CGFloat> = -π / 2 ... π / 2

  /**
  addTarget:action:forControlEvents:

  - parameter target: AnyObject?
  - parameter action: Selector
  - parameter controlEvents: UIControlEvents
  */
  override public func addTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) {
    super.addTarget(target, action: action, forControlEvents: controlEvents)
    guard self.rotationGesture == nil else { return }
    let rotationGesture = UIRotationGestureRecognizer(target: self, action: "didRotate")
    addGestureRecognizer(rotationGesture)
    self.rotationGesture = rotationGesture
  }

  /**
  didRotate:

  - parameter gesture: UIRotationGestureRecognizer
  */
  @objc private func didRotate() {
    guard let rotationGesture = rotationGesture else { return }
    let currentRotation = -rotationInterval.clampValue(rotationGesture.rotation)
    guard currentRotation != previousRotation else { return }
    value = valueInterval.valueForNormalizedValue(Float(rotationInterval.normalizeValue(currentRotation)))
    previousRotation = currentRotation
  }

  @IBInspectable public var knobColor: UIColor = .darkGrayColor() {
    didSet {
      knobBase = knobBase?.imageWithColor(knobColor)
      setNeedsDisplay()
    }
  }
  @IBInspectable public var indicatorColor: UIColor = .whiteColor() { didSet { setNeedsDisplay() } }

  private var valueAngle: CGFloat { return -π * CGFloat(valueInterval.normalizeValue(value)) }
  private var startAngle: CGFloat { return valueAngle + π / 20 }
  private var endAngle: CGFloat  { return valueAngle - π / 20 }

  private var valueInterval: ClosedInterval<Float> = 0 ... 1 { didSet { value = valueInterval.clampValue(value) } }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {

    var frame = rect
    if frame.size.width != frame.size.height {
      frame.size = CGSize(square: frame.size.minAxis)
      frame.origin += (rect.size - frame.size) * 0.5
    }

    if let knobBase = knobBase {
      let context = UIGraphicsGetCurrentContext()
      CGContextSaveGState(context)
      CGContextTranslateCTM(context, half(frame.width), half(frame.height))
      CGContextRotateCTM(context, valueAngle)
      let baseFrame = CGRect(origin: frame.origin - (frame.size * 0.5),  size: frame.size)
      knobBase.drawInRect(baseFrame)
      CGContextRestoreGState(context)
    } else {
      knobColor.setFill()
      UIBezierPath(ovalInRect: frame).fill()
    }

    let center = frame.center.offsetBy(dx: 0, dy: -2)
    let indicatorPath = UIBezierPath()
    indicatorPath.addArcWithCenter(center, radius: half(frame.width) - 2, startAngle: startAngle, endAngle: endAngle, clockwise: false)
    indicatorPath.addLineToPoint(center)
    indicatorPath.closePath()

    indicatorColor.setFill()
    indicatorPath.fillWithBlendMode(indicatorStyle.blendMode, alpha: 1)
    indicatorPath.lineWidth = 2
    indicatorPath.lineJoinStyle = .Bevel
    indicatorPath.strokeWithBlendMode(.Clear, alpha: 1)
  }

}