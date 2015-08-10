//
//  Label.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/4/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import UIKit

public class Label: UILabel {

  public var gutter = UIEdgeInsets(top: 0.0, left: 0.0, bottom: -8.0, right: 0.0)

  /**
  drawRect:

  - parameter rect: CGRect
  */
//  public override func drawRect(rect: CGRect) {
//    attributedText.drawInRect(gutter.insetRect(rect))
//  }

  /**
  alignmentRectInsets

  - returns: UIEdgeInsets
  */
//  public override func alignmentRectInsets() -> UIEdgeInsets {
//    return gutter
//  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    return gutter.insetRect(CGRect(size: super.intrinsicContentSize())).size
  }

}
