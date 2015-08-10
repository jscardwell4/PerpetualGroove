//
//  TextField.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/4/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import UIKit

public class TextField: UITextField {
  public var gutter: CGFloat = 4.0

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawTextInRect(rect: CGRect) {
    var newRect = rect
    newRect.origin.x = rect.origin.x + gutter
    newRect.origin.y = rect.origin.y + gutter
    newRect.size.width = rect.size.width - CGFloat(2) * gutter
    newRect.size.height = rect.size.height - CGFloat(2) * gutter
    attributedText?.drawInRect(newRect)
  }

  /**
  alignmentRectInsets

  - returns: UIEdgeInsets
  */
//  public override func alignmentRectInsets() -> UIEdgeInsets {
//    return UIEdgeInsets(top: gutter, left: gutter, bottom: gutter, right: gutter);
//  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
//  public override func intrinsicContentSize() -> CGSize {
//    var size = super.intrinsicContentSize()
//    size.width += CGFloat(2) * gutter
//    size.height += CGFloat(2) * gutter
//    return size;
//  }

}