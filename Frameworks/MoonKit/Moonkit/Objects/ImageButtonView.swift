//

//  ImageButtonView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

@IBDesignable public class ImageButtonView: ToggleControl {

  // MARK: - Images

  @IBInspectable public var image: UIImage? {
    didSet {
      guard !(highlighted || selected) || highlightedImage == nil else { return}
      setNeedsDisplay()
    }
  }

  @IBInspectable public var highlightedImage: UIImage? {
    didSet {
      guard highlighted || selected else { return }
      setNeedsDisplay()
    }
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override public func intrinsicContentSize() -> CGSize {
    return image?.size ?? CGSize(square: UIViewNoIntrinsicMetric)
  }

  /** setup */
  private func setup() {
    opaque = false
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

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {
    guard let image = (highlighted || selected) && highlightedImage != nil ? highlightedImage : image else { return }

    let context = UIGraphicsGetCurrentContext()
    CGContextSaveGState(context)
    CGContextClearRect(context, rect)
    image.drawInRect(rect)

    currentTintColor.setFill()
    UIBezierPath(rect: rect).fillWithBlendMode(.SourceIn, alpha: 1)

    CGContextRestoreGState(context)
  }
}
