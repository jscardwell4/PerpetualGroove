//
//  Checkbox.swift
//  Remote
//
//  Created by Jason Cardwell on 12/06/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit


public class Checkbox: UIControl {

  public var checked: Bool = false { didSet { setNeedsDisplay() } }

  public var checkmarkColor: UIColor = UIColor(white: 0.1, alpha: 1) { didSet { setNeedsDisplay() } }

  public var useFontAwesome = true

  /** toggleChecked */
  public func toggleChecked() { checked = !checked }

  /** init */
  public convenience init() { self.init(frame: CGRect.zeroRect) }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) {
    super.init(frame: frame)
    opaque = false
    backgroundColor = UIColor.clearColor()
    addTarget(self, action: "toggleChecked", forControlEvents: .TouchUpInside)
    setContentHuggingPriority(1000, forAxis: .Vertical)
    setContentHuggingPriority(1000, forAxis: .Horizontal)
  }

  /**
  initWithAutolayout:

  - parameter autolayout: Bool
  */
  public convenience init(autolayout: Bool) { self.init(); translatesAutoresizingMaskIntoConstraints = !autolayout }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize { return CGSize(square: 28.0) }

  /**
  alignmentRectInsets

  - returns: UIEdgeInsets
  */
  // public override func alignmentRectInsets() -> UIEdgeInsets {
  //   let dx = floor(bounds.width * 0.15909 + 0.5)
  //   let dy = floor(bounds.height * 0.11364 + 0.5)
  //   let w  = floor(bounds.width * 0.86364 + 0.5)
  //   let h  = floor(bounds.height * 0.81818 + 0.5)

  //   return UIEdgeInsets(top: dy, left: dx, bottom: bounds.height - h, right: bounds.width - w)
  // }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {

    if useFontAwesome {
      UIFont.fontAwesomeIconForName(checked ? "check-square-o" : "square-o").drawInRect(rect, withAttributes: [
        NSFontAttributeName: UIFont(name: "FontAwesome", size: rect.size.minAxis - 1.0)!
      ])
    } else {
      //// General Declarations
      let context = UIGraphicsGetCurrentContext()


      //// Variable Declarations
//      let radius: CGFloat = rect.size.width * 0.11363636

      //// box Drawing
      let boxRect = CGRect(x: rect.minX + floor(rect.width * 0.09091 + 0.5),
                           y: rect.minY + floor(rect.height * 0.09091 + 0.5),
                           width: floor(rect.width * 0.90909 + 0.5) - floor(rect.width * 0.09091 + 0.5),
                           height: floor(rect.height * 0.84091 + 0.5) - floor(rect.height * 0.09091 + 0.5))

//      let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: radius)
      CGContextSaveGState(context)
      CGContextSetShadowWithColor(
        context,
        DrawingKit.semiDarkShadow.shadowOffset,
        DrawingKit.semiDarkShadow.shadowBlurRadius,
        (DrawingKit.semiDarkShadow.shadowColor as! UIColor).CGColor
      )
      UIColor.whiteColor().setFill()
      UIRectFill(boxRect)

      ////// box Inner Shadow
      UIGraphicsPushContext(context!)
      UIRectClip(boxRect.rectWithOrigin(CGPoint.zeroPoint))
      CGContextSetShadow(context, CGSize.zeroSize, 0)
      CGContextSetAlpha(context, CGColorGetAlpha((DrawingKit.semiDarkShadow.shadowColor as! UIColor).CGColor))
      CGContextBeginTransparencyLayer(context, nil)

      let boxOpaqueShadow = (DrawingKit.semiDarkShadow.shadowColor as! UIColor).colorWithAlphaComponent(1)
      CGContextSetShadowWithColor(
        context,
        DrawingKit.semiDarkShadow.shadowOffset,
        DrawingKit.semiDarkShadow.shadowBlurRadius,
        (boxOpaqueShadow as UIColor).CGColor
      )
      CGContextSetBlendMode(context, .SourceOut)
      CGContextBeginTransparencyLayer(context, nil)

      boxOpaqueShadow.setFill()
      UIRectFill(boxRect)

      CGContextEndTransparencyLayer(context)
      CGContextEndTransparencyLayer(context)
      UIGraphicsPopContext()

      UIGraphicsPopContext()



      if (checked) {
          //// checkmark Drawing
          let checkmarkPath = UIBezierPath()
          checkmarkPath.moveToPoint(     CGPoint(x: rect.minX + 0.95455 * rect.width, y: rect.minY + 0.09047 * rect.height))
          checkmarkPath.addCurveToPoint( CGPoint(x: rect.minX + 0.88555 * rect.width, y: rect.minY + 0.02273 * rect.height),
                          controlPoint1: CGPoint(x: rect.minX + 0.95455 * rect.width, y: rect.minY + 0.05305 * rect.height),
                          controlPoint2: CGPoint(x: rect.minX + 0.92366 * rect.width, y: rect.minY + 0.02273 * rect.height))
          checkmarkPath.addCurveToPoint( CGPoint(x: rect.minX + 0.83519 * rect.width, y: rect.minY + 0.04514 * rect.height),
                          controlPoint1: CGPoint(x: rect.minX + 0.86542 * rect.width, y: rect.minY + 0.02273 * rect.height),
                          controlPoint2: CGPoint(x: rect.minX + 0.84777 * rect.width, y: rect.minY + 0.03160 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.83470 * rect.width, y: rect.minY + 0.04469 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.43462 * rect.width, y: rect.minY + 0.47323 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.29959 * rect.width, y: rect.minY + 0.34065 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.29944 * rect.width, y: rect.minY + 0.34080 * rect.height))
          checkmarkPath.addCurveToPoint( CGPoint(x: rect.minX + 0.25081 * rect.width, y: rect.minY + 0.32080 * rect.height),
                          controlPoint1: CGPoint(x: rect.minX + 0.28698 * rect.width, y: rect.minY + 0.32851 * rect.height),
                          controlPoint2: CGPoint(x: rect.minX + 0.26987 * rect.width, y: rect.minY + 0.32080 * rect.height))
          checkmarkPath.addCurveToPoint( CGPoint(x: rect.minX + 0.18182 * rect.width, y: rect.minY + 0.38855 * rect.height),
                          controlPoint1: CGPoint(x: rect.minX + 0.21270 * rect.width, y: rect.minY + 0.32080 * rect.height),
                          controlPoint2: CGPoint(x: rect.minX + 0.18182 * rect.width, y: rect.minY + 0.35113 * rect.height))
          checkmarkPath.addCurveToPoint( CGPoint(x: rect.minX + 0.19438 * rect.width, y: rect.minY + 0.42734 * rect.height),
                          controlPoint1: CGPoint(x: rect.minX + 0.18182 * rect.width, y: rect.minY + 0.40301 * rect.height),
                          controlPoint2: CGPoint(x: rect.minX + 0.18651 * rect.width, y: rect.minY + 0.41635 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.19428 * rect.width, y: rect.minY + 0.42739 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.38746 * rect.width, y: rect.minY + 0.69837 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.38756 * rect.width, y: rect.minY + 0.69832 * rect.height))
          checkmarkPath.addCurveToPoint( CGPoint(x: rect.minX + 0.44399 * rect.width, y: rect.minY + 0.72727 * rect.height),
                          controlPoint1: CGPoint(x: rect.minX + 0.40003 * rect.width, y: rect.minY + 0.71578 * rect.height),
                          controlPoint2: CGPoint(x: rect.minX + 0.42062 * rect.width, y: rect.minY + 0.72727 * rect.height))
          checkmarkPath.addCurveToPoint( CGPoint(x: rect.minX + 0.49866 * rect.width, y: rect.minY + 0.70043 * rect.height),
                          controlPoint1: CGPoint(x: rect.minX + 0.46637 * rect.width, y: rect.minY + 0.72727 * rect.height),
                          controlPoint2: CGPoint(x: rect.minX + 0.48607 * rect.width, y: rect.minY + 0.71665 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.49888 * rect.width, y: rect.minY + 0.70059 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.94044 * rect.width, y: rect.minY + 0.13154 * rect.height))
          checkmarkPath.addLineToPoint(  CGPoint(x: rect.minX + 0.94022 * rect.width, y: rect.minY + 0.13138 * rect.height))
          checkmarkPath.addCurveToPoint( CGPoint(x: rect.minX + 0.95455 * rect.width, y: rect.minY + 0.09047 * rect.height),
                          controlPoint1: CGPoint(x: rect.minX + 0.94908 * rect.width, y: rect.minY + 0.11998 * rect.height),
                          controlPoint2: CGPoint(x: rect.minX + 0.95455 * rect.width, y: rect.minY + 0.10592 * rect.height))
          checkmarkPath.closePath()
          checkmarkPath.miterLimit = 4;

          UIGraphicsPushContext(context!)
          CGContextSetShadowWithColor(
            context,
            DrawingKit.semiDarkShadow.shadowOffset,
            DrawingKit.semiDarkShadow.shadowBlurRadius,
            (DrawingKit.semiDarkShadow.shadowColor as! UIColor).CGColor
          )

          checkmarkColor.setFill()
          checkmarkPath.fill()

          ////// checkmark Inner Shadow
          UIGraphicsPushContext(context!)
          UIRectClip(checkmarkPath.bounds)
          CGContextSetShadow(context, CGSize.zeroSize, 0)
          CGContextSetAlpha(context, CGColorGetAlpha((DrawingKit.lightShadow.shadowColor as! UIColor).CGColor))
          CGContextBeginTransparencyLayer(context, nil)
          let checkmarkOpaqueShadow = (DrawingKit.lightShadow.shadowColor as! UIColor).colorWithAlphaComponent(1)
          CGContextSetShadowWithColor(
            context,
            DrawingKit.lightShadow.shadowOffset,
            DrawingKit.lightShadow.shadowBlurRadius,
            (checkmarkOpaqueShadow as UIColor).CGColor
          )
          CGContextSetBlendMode(context, .SourceOut)
          CGContextBeginTransparencyLayer(context, nil)

          checkmarkOpaqueShadow.setFill()
          checkmarkPath.fill()

          CGContextEndTransparencyLayer(context)
          CGContextEndTransparencyLayer(context)
          UIGraphicsPopContext()

          UIGraphicsPopContext()

      }
    }

  }
}
