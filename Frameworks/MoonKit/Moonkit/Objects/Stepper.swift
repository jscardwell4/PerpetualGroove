//
//  Stepper.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/9/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

//@IBDesignable
public class Stepper: UIControl {


  @IBInspectable public var continuous: Bool = true
  @IBInspectable public var autorepeat: Bool = true
  @IBInspectable public var wraps: Bool = false

  @IBInspectable public var value: Double = 0          { didSet { value = (minimumValue ... maximumValue).clampValue(value) } }
  @IBInspectable public var minimumValue: Double = 0   { didSet { minimumValue = min(minimumValue, maximumValue) } }
  @IBInspectable public var maximumValue: Double = 100 { didSet { maximumValue = max(minimumValue, maximumValue) } }
  @IBInspectable public var stepValue: Double = 1      { didSet { stepValue = max(stepValue, 1) } }

  @IBInspectable public var backgroundImage: UIImage? {
    didSet { guard backgroundImage != oldValue else { return }; setNeedsDisplay() }
  }
  @IBInspectable public var dividerImage: UIImage? {
    didSet { guard dividerImage != oldValue else { return }; setNeedsDisplay() }
  }
  @IBInspectable public var incrementImage: UIImage? {
    didSet { guard incrementImage != oldValue else { return }; setNeedsDisplay() }
  }
  @IBInspectable public var decrementImage: UIImage? {
    didSet { guard decrementImage != oldValue else { return }; setNeedsDisplay()}
  }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {
    if let backgroundImage = backgroundImage {
      backgroundImage.drawInRect(rect)
    }

    if let incrementImage = incrementImage, decrementImage = decrementImage {
      var decrementRect = rect
      decrementRect.size.width /= 2
      decrementImage.drawInRect(decrementRect)

      var incrementRect = decrementRect
      incrementRect.origin.x += incrementRect.width
      incrementImage.drawInRect(incrementRect)
    }
  }


}
