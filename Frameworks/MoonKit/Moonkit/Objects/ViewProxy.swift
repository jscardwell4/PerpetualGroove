//
//  ViewProxy.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/30/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

public final class ViewProxy: UIView {

  public var subviewType: UIView.Type = UIView.self

  
  /**
  drawRect:

  - parameter rect: CGRect
  */
  override public func drawRect(rect: CGRect) { draw(UIGraphicsGetCurrentContext()!, rect) }
  

  /**
  addSubview:

  - parameter view: UIView
  */
  override public func addSubview(view: UIView) { if let v = typeCast(view, subviewType) { super.addSubview(v) } }

  public var draw: (CGContext, CGRect) -> Void = { _, _ in }

  /**
  initWithFrame:draw:

  - parameter frame: CGRect
  - parameter draw: (CGContext, CGRect) -> Void
  */
  public convenience init(frame: CGRect, draw: (CGContext, CGRect) -> Void) {
    self.init(frame: frame)
    self.draw = draw
  }

}
