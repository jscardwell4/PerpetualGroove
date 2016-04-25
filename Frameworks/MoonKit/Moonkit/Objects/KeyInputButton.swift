//
//  KeyInputButton.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/5/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class KeyInputButton: UIControl {

  public enum Style { case Default, Prominent, Reversed, DeleteBackward, Done }

  public var style: Style = .Default { didSet { if style == .Done { title = "Done"} } }
  public var title: String = ""

  public override var highlighted: Bool { didSet { setNeedsDisplay() } }
  public override var enabled: Bool { didSet { setNeedsDisplay() } }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame) }

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
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {
    //// General Declarations
    let context = UIGraphicsGetCurrentContext()

    //// Color Declarations
    let detailColor = UIColor.whiteColor()
    let disabledDetailColor = detailColor.colorWithBrightness(0.5)
    let foregroundColor = enabled ? detailColor : disabledDetailColor
    let prominent = [Style.Prominent, Style.Done].contains(style)
    let reverse = [Style.Reversed, Style.DeleteBackward].contains(style)
    let normalStateColor = prominent
                             ? DrawingKit.prominentColor
                             : (reverse
                                  ? DrawingKit.keyboardColor2
                                  : DrawingKit.keyboardColor1)
    let highlightedStateColor = prominent
                                  ? DrawingKit.keyboardColor2
                                  : (reverse
                                      ? DrawingKit.keyboardColor1
                                      : DrawingKit.keyboardColor2)

    let backgroundColor = highlighted ? highlightedStateColor : normalStateColor

    UIGraphicsPushContext(context!)
    UIRectClip(rect)
    CGContextTranslateCTM(context, rect.origin.x, rect.origin.y)
    let rectanglePath = UIBezierPath(rect: rect)
    backgroundColor.setFill()
    rectanglePath.fill()
    foregroundColor.setStroke()
    rectanglePath.lineWidth = 0.5
    rectanglePath.stroke()
    UIGraphicsPopContext()

    switch style {
      case .DeleteBackward:
        //// Delete Symbol Drawing
        let rect = CGRect(x: rect.minX + floor(rect.width * 0.29245 + 0.5),
                          y: rect.minY + floor(rect.height * 0.22222 + 0.5),
                          width: floor(rect.width * 0.71698 + 0.5) - floor(rect.width * 0.29245 + 0.5),
                          height: floor(rect.height * 0.77778 + 0.5) - floor(rect.height * 0.22222 + 0.5))
        UIGraphicsPushContext(context!)
        UIRectClip(rect)
        CGContextTranslateCTM(context, rect.origin.x, rect.origin.y)

        let deleteSymbolPath = UIBezierPath()
        deleteSymbolPath.moveToPoint(     CGPoint(x: rect.minX + 0.74055 * rect.width, y: rect.minY + 0.20608 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.58459 * rect.width, y: rect.minY + 0.42905 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.42817 * rect.width, y: rect.minY + 0.20608 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.37902 * rect.width, y: rect.minY + 0.27635 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.53497 * rect.width, y: rect.minY + 0.50000 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.37902 * rect.width, y: rect.minY + 0.72297 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.42817 * rect.width, y: rect.minY + 0.79392 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.58459 * rect.width, y: rect.minY + 0.57027 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.74055 * rect.width, y: rect.minY + 0.79392 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.79017 * rect.width, y: rect.minY + 0.72297 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.63422 * rect.width, y: rect.minY + 0.50000 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.79017 * rect.width, y: rect.minY + 0.27635 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.74055 * rect.width, y: rect.minY + 0.20608 * rect.height))
        deleteSymbolPath.closePath()
        deleteSymbolPath.moveToPoint(     CGPoint(x: rect.minX + 1.00000 * rect.width, y: rect.minY + 0.00002 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 1.00000 * rect.width, y: rect.minY + 1.00000 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.34972 * rect.width, y: rect.minY + 1.00000 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 0.00000 * rect.width, y: rect.minY + 0.50000 * rect.height))
        deleteSymbolPath.addCurveToPoint( CGPoint(x: rect.minX + 0.23565 * rect.width, y: rect.minY + 0.16309 * rect.height),
                           controlPoint1: CGPoint(x:rect.minX + 0.00000 * rect.width, y: rect.minY + 0.50000 * rect.height),
                           controlPoint2: CGPoint(x:rect.minX + 0.13360 * rect.width, y: rect.minY + 0.30899 * rect.height))
        deleteSymbolPath.addCurveToPoint( CGPoint(x: rect.minX + 0.34972 * rect.width, y: rect.minY + 0.00000 * rect.height),
                           controlPoint1: CGPoint(x: rect.minX + 0.29870 * rect.width, y: rect.minY + 0.07293 * rect.height),
                           controlPoint2: CGPoint(x: rect.minX + 0.34972 * rect.width, y: rect.minY + 0.00000 * rect.height))
        deleteSymbolPath.addLineToPoint(  CGPoint(x: rect.minX + 1.00000 * rect.width, y: rect.minY + 0.00002 * rect.height))
        deleteSymbolPath.closePath()
        foregroundColor.setFill()
        deleteSymbolPath.fill()

        UIGraphicsPopContext()

    default:
      // Title drawing
      let textFontAttributes = [
        NSFontAttributeName:            UIFont.boldSystemFontOfSize(30),
        NSForegroundColorAttributeName: foregroundColor,
        NSParagraphStyleAttributeName:  NSParagraphStyle.paragraphStyleWithAttributes(alignment: .Center)
      ]

      let h: CGFloat = title.boundingRectWithSize(CGSize(width: rect.width, height: CGFloat.infinity),
                                                       options: .UsesLineFragmentOrigin,
                                                    attributes: textFontAttributes,
                                                       context: nil).height
      UIGraphicsPushContext(context!)
      UIRectClip(rect);

      let textRect = CGRect(x: rect.minX, y: rect.minY + (rect.height - h) / 2, width: rect.width, height: h)
      title.drawInRect(textRect, withAttributes: textFontAttributes)

      UIGraphicsPopContext()

    }

  }

}

extension KeyInputButton.Style: Equatable {}
public func ==(lhs: KeyInputButton.Style, rhs: KeyInputButton.Style) -> Bool {
  switch (lhs, rhs) {
    case (.Default, .Default),
         (.Prominent, .Prominent),
         (.Reversed, .Reversed),
         (.DeleteBackward, .DeleteBackward),
         (.Done, .Done):
     return true
    default:
      return false
  }
}
