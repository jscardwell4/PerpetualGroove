//
//  Label.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/4/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import UIKit

@IBDesignable
public class Label: UILabel {

  @IBInspectable public var gutterString: String {
    get { return gutter.stringValue }
    set { gutter = UIEdgeInsets(newValue) ?? .zeroInsets }
  }

  public var gutter: UIEdgeInsets = .zeroInsets {
    didSet {
      guard gutter != oldValue else { return }
      invalidateIntrinsicContentSize()
      setNeedsDisplay()
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

  public var verticalAlignment: VerticalAlignment = .Center {
    didSet { guard verticalAlignment != oldValue else { return }; setNeedsDisplay() }
  }

  @IBInspectable public var verticalAlignmentString: String {
    get { return verticalAlignment.rawValue }
    set { verticalAlignment = VerticalAlignment(rawValue: newValue) ?? .Center }
  }


  /**
  drawTextInRect:

  - parameter rect: CGRect
  */
  public override func drawTextInRect(rect: CGRect) {

    var textRect = textRectForBounds(rect, limitedToNumberOfLines: numberOfLines)
    switch verticalAlignment {
      case .Top:    break
      case .Center: textRect.origin.y += half(rect.height) - half(textRect.height)
      case .Bottom: textRect.origin.y = rect.maxY - textRect.height
    }

    let alpha = highlighted ? highlightedTintColorAlpha : tintColorAlpha
    guard alpha > 0 else { super.drawTextInRect(textRect); return }

    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
    super.drawTextInRect(textRect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    let context = UIGraphicsGetCurrentContext()
    CGContextSaveGState(context)

    image.addClip()
    tintColor.colorWithAlpha(alpha).setFill()
    UIRectFillUsingBlendMode(textRect, .Color)

    CGContextRestoreGState(context)
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    let size = gutter.outsetRect(CGRect(size: super.intrinsicContentSize())).size
    logIB("gutter: \(gutter); intrinsicContentSize: \(size)")
    return size
  }

}
