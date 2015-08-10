//
//  ColorSwatch.swift
//  Remote
//
//  Created by Jason Cardwell on 12/07/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit

 @objc public protocol ColorSwatchDelegate : NSObjectProtocol {
  optional func colorSwatchShouldBeginEditing(colorSwatch: ColorSwatch) -> Bool
  optional func colorSwatchDidBeginEditing(colorSwatch: ColorSwatch)
  optional func colorSwatchShouldEndEditing(colorSwatch: ColorSwatch) -> Bool
  optional func colorSwatchDidEndEditing(colorSwatch: ColorSwatch)
}

@IBDesignable public class ColorSwatch: UIControl {

  public var color: UIColor? { didSet { setNeedsDisplay() } }

  public var delegate: ColorSwatchDelegate?

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {

    //// General Declarations
    let context = UIGraphicsGetCurrentContext()


    //// Shadow Declarations
    let dropShadow = NSShadow(color: UIColor.blackColor().colorWithAlphaComponent(0.15),
                              offset: CGSize(width: 0.1, height: 3.1),
                              blurRadius: 1)
    let swatchBaseInnerShadow = NSShadow(color: UIColor.whiteColor(),
                                         offset: CGSize(width: 0.1, height: -0.1),
                                         blurRadius: 5)
    let swatchBaseStrokeShadow = NSShadow(color: UIColor(white: 0.0, alpha: 0.43),
                                          offset: CGSize(width: 0.1, height: -0.1),
                                          blurRadius: 1)
    let swatchInnerShadow = NSShadow(color: UIColor(white: 0.0, alpha: 0.45),
                                     offset: CGSizeMake(0.1, -0.1),
                                     blurRadius: 1)

    //// Rectangle Drawing
    let rectanglePath = UIBezierPath(rect: CGRect(x: rect.minX + 2,
                                                  y: rect.minY + 2,
                                                  width: rect.width - 4,
                                                  height: rect.height - 7))
    CGContextSaveGState(context)
    CGContextSetShadowWithColor(context,
                                dropShadow.shadowOffset,
                                dropShadow.shadowBlurRadius,
                                (dropShadow.shadowColor as! UIColor).CGColor)
    UIColor.whiteColor().setFill()
    rectanglePath.fill()

    ////// Rectangle Inner Shadow
    CGContextSaveGState(context)
    CGContextClipToRect(context, rectanglePath.bounds)
    CGContextSetShadow(context, CGSizeMake(0, 0), 0)
    CGContextSetAlpha(context, CGColorGetAlpha((swatchBaseInnerShadow.shadowColor as! UIColor).CGColor))
    CGContextBeginTransparencyLayer(context, nil)
    let rectangleOpaqueShadow = (swatchBaseInnerShadow.shadowColor as! UIColor).colorWithAlphaComponent(1)
    CGContextSetShadowWithColor(context,
                                swatchBaseInnerShadow.shadowOffset,
                                swatchBaseInnerShadow.shadowBlurRadius,
                                (rectangleOpaqueShadow as UIColor).CGColor)
    CGContextSetBlendMode(context, .SourceOut)
    CGContextBeginTransparencyLayer(context, nil)

    rectangleOpaqueShadow.setFill()
    rectanglePath.fill()

    CGContextEndTransparencyLayer(context)
    CGContextEndTransparencyLayer(context)
    CGContextRestoreGState(context)

    CGContextRestoreGState(context)

    CGContextSaveGState(context)
    CGContextSetShadowWithColor(context,
                                swatchBaseStrokeShadow.shadowOffset,
                                swatchBaseStrokeShadow.shadowBlurRadius,
                                (swatchBaseStrokeShadow.shadowColor as! UIColor).CGColor)
    UIColor.whiteColor().setStroke()
    rectanglePath.lineWidth = 0.5
    rectanglePath.stroke()
    CGContextRestoreGState(context)


    //// swatch Drawing
    let swatchPath = UIBezierPath(rect: CGRect(x: rect.minX + 2.5,
                                               y: rect.minY + 2.5,
                                               width: rect.width - 5,
                                               height: rect.height - 8))
    CGContextSaveGState(context)
    CGContextSetShadowWithColor(context,
                                swatchInnerShadow.shadowOffset,
                                swatchInnerShadow.shadowBlurRadius,
                                (swatchInnerShadow.shadowColor as! UIColor).CGColor)
    (color ?? UIColor.whiteColor()).setFill()
    swatchPath.fill()
    CGContextRestoreGState(context)



    if color == nil {
      //// Diagonal Drawing
      let diagonalPath = UIBezierPath()
      diagonalPath.moveToPoint(CGPoint(x: rect.minX + 4.5, y: rect.maxY - 5.5))
      diagonalPath.addLineToPoint(CGPoint(x: rect.minX + 2.5, y: rect.maxY - 5.5))
      diagonalPath.addLineToPoint(CGPoint(x: rect.minX + 2.5, y: rect.maxY - 6.5))
      diagonalPath.addLineToPoint(CGPoint(x: rect.maxX - 3.5, y: rect.minY + 2.5))
      diagonalPath.addLineToPoint(CGPoint(x: rect.maxX - 2.5, y: rect.minY + 2.5))
      diagonalPath.addLineToPoint(CGPoint(x: rect.maxX - 2.5, y: rect.minY + 3.5))
      diagonalPath.addLineToPoint(CGPoint(x: rect.minX + 4.5, y: rect.maxY - 5.5))
      diagonalPath.closePath()
      UIColor.redColor().setFill()
      diagonalPath.fill()
    }

  }

  /**
  canBecomeFirstResponder

  - returns: Bool
  */
  public override func canBecomeFirstResponder() -> Bool { return true }

  /**
  becomeFirstResponder

  - returns: Bool
  */
  public override func becomeFirstResponder() -> Bool {
    var didBecomeFirstResponder = false
    if delegate?.colorSwatchShouldBeginEditing?(self) != false { didBecomeFirstResponder = super.becomeFirstResponder() }
    if didBecomeFirstResponder { delegate?.colorSwatchDidBeginEditing?(self) }
    return didBecomeFirstResponder
  }

  /**
  resignFirstResponder

  - returns: Bool
  */
  public override func resignFirstResponder() -> Bool {
    var didResignFirstResponder = false
    if delegate?.colorSwatchShouldEndEditing?(self) != false { didResignFirstResponder = super.resignFirstResponder() }
    if didResignFirstResponder { delegate?.colorSwatchDidEndEditing?(self) }
    return didResignFirstResponder
  }

  public override var inputView: UIView? {
    return ColorInputView(frame: CGRect(size: CGSize(width: UIScreen.mainScreen().bounds.width, height: 200)), colorInput: self)
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) {
    super.init(frame: frame)
    opaque = false
    backgroundColor = UIColor.clearColor()
    addActionBlock({ self.toggleFirstResponder() }, forControlEvents: .TouchUpInside)
  }

  /** init */
//  public override init() { super.init() }

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
  public override func intrinsicContentSize() -> CGSize { return CGSize(width: 50, height: 24) }

}

extension ColorSwatch: ColorInput {

  public var redValue: Float {
    get { return Float(color?.red ?? 0) }
    set { color = color?.colorWithRed(CGFloat(newValue)) ?? UIColor(red: CGFloat(newValue), green: 0, blue: 0, alpha: 1) }
  }

  public var greenValue: Float {
    get { return Float(color?.green ?? 0) }
    set { color = color?.colorWithGreen(CGFloat(newValue)) ?? UIColor(red: 0, green: CGFloat(newValue), blue: 0, alpha: 1) }
  }

  public var blueValue: Float {
    get { return Float(color?.blue ?? 0) }
    set { color = color?.colorWithBlue(CGFloat(newValue)) ?? UIColor(red: 0, green: 0, blue: CGFloat(newValue), alpha: 1) }
  }

  public var alphaValue: Float {
    get { return Float(color?.alpha ?? 0) }
    set { color = color?.colorWithAlpha(CGFloat(newValue)) ?? UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(newValue)) }
  }

}
