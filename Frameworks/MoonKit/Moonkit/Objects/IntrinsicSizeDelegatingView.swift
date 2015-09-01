//
//  IntrinsicSizeDelegatingView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/31/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class IntrinsicSizeDelegatingView: UIView {

  public var intrinsicContentSizeHandler: ((IntrinsicSizeDelegatingView) -> CGSize)?

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  final override public func intrinsicContentSize() -> CGSize {
    return intrinsicContentSizeHandler?(self) ?? super.intrinsicContentSize()
  }

  /**
  initWithAutolayout:handler:

  - parameter autolayout: Bool
  - parameter handler: ((IntrinsicSizeDelegatingView) -> CGSize
  */
  public convenience init(autolayout: Bool, handler: ((IntrinsicSizeDelegatingView) -> CGSize)?) {
    self.init(autolayout: autolayout)
    intrinsicContentSizeHandler = handler
  }
}