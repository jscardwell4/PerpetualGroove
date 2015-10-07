//
//  TextField.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/4/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import UIKit

@IBDesignable public class TextField: UITextField {

  @IBInspectable public var gutter: UIEdgeInsets = .zeroInsets {
    didSet {
      guard gutter != oldValue else { return }
      invalidateIntrinsicContentSize()
    }
  }

  @IBInspectable public var tintColorAlpha: CGFloat = 0 {
    didSet {
      guard tintColorAlpha != oldValue else { return }
      tintColorAlpha = (0 ... 1).clampValue(tintColorAlpha)
      if !highlighted { setNeedsDisplay() }
    }
  }

  @IBInspectable public var highlightedTintColorAlpha: CGFloat = 0 {
    didSet {
      guard highlightedTintColorAlpha != oldValue else { return }
      highlightedTintColorAlpha = (0 ... 1).clampValue(highlightedTintColorAlpha)
      if highlighted { setNeedsDisplay() }
    }
  }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawTextInRect(rect: CGRect) {
    super.drawTextInRect(rect)
    let alpha = highlighted ? highlightedTintColorAlpha : tintColorAlpha
    guard alpha > 0 else { return }

    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    super.drawTextInRect(rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    let context = UIGraphicsGetCurrentContext()
    CGContextSaveGState(context)

    image.addClip()
    tintColor.colorWithAlpha(alpha).setFill()
    UIRectFillUsingBlendMode(rect, .Color)

    CGContextRestoreGState(context)
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    return gutter.insetRect(CGRect(size: super.intrinsicContentSize())).size
  }

}