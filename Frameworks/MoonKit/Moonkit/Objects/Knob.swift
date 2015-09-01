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

  @IBInspectable public var value: Double = 0.0 { didSet { setNeedsDisplay() } }

  @IBInspectable public var minimumValue: Double = 0.0 {
    didSet {
      guard value < minimumValue else { return }
      value = minimumValue
      setNeedsDisplay()
    }
  }

  @IBInspectable public var knobBase: UIImage? {
    didSet {
      if let knobBase = knobBase { self.knobBase = knobBase.imageWithColor(knobColor) }
      setNeedsDisplay()
    }
  }

  @IBInspectable public var maximumValue: Double = 1.0 {
    didSet {
      guard value > maximumValue else { return }
      value = maximumValue
      setNeedsDisplay()
    }
  }

  @IBInspectable public var knobColor: UIColor = .darkGrayColor() {
    didSet {
      if let knobBase = knobBase { self.knobBase = knobBase.imageWithColor(knobColor) }
      setNeedsDisplay()
    }
  }
  @IBInspectable public var indicatorColor: UIColor = .whiteColor() { didSet { setNeedsDisplay() } }

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
    
    let delta: CGFloat = minimumValue < 0 ? CGFloat(abs(minimumValue)) : CGFloat(minimumValue)
    let magnitude: CGFloat = CGFloat(maximumValue) - CGFloat(minimumValue)
    let normalizedMagnitude: CGFloat = magnitude + delta
    let normalizedValue: CGFloat = CGFloat(value) + delta
    let valueAngle: CGFloat = (normalizedMagnitude * π) - (normalizedValue * π / magnitude)
    let startAngle: CGFloat = valueAngle + π / 20
    let endAngle: CGFloat = valueAngle - π / 20

    if let knobBase = knobBase { knobBase.drawInRect(frame) }
    else { knobColor.setFill(); UIBezierPath(ovalInRect: frame).fill() }

      //// Indicator Drawing
    let indicatorRect = CGRectMake(frame.minX + 0.5, frame.minY + floor(frame.height * -0.00195) + 0.5, frame.width, floor(frame.height * 0.99805) - floor(frame.height * -0.00195))
    let indicatorPath = UIBezierPath()
    indicatorPath.addArcWithCenter(CGPointMake(indicatorRect.midX, indicatorRect.midY), radius: indicatorRect.width / 2, startAngle: -startAngle, endAngle: -endAngle, clockwise: true)
    indicatorPath.addLineToPoint(CGPointMake(indicatorRect.midX, indicatorRect.midY))
    indicatorPath.closePath()

    indicatorColor.setFill()
    indicatorPath.fill()
  }

}